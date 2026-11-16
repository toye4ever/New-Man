import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../../application/android_reminder_scheduler.dart';
import '../../domain/android_reminder_delivery.dart';

enum ReminderBridgeFailure {
  unavailable,
  unconfirmed,
  invalidReply,
  notAuthorized,
}

class ReminderBridgeException implements Exception {
  const ReminderBridgeException(this.failure);
  final ReminderBridgeFailure failure;
  @override
  String toString() =>
      'Android task reminder operation unavailable or unconfirmed.';
}

class AndroidReminderBridgeState {
  const AndroidReminderBridgeState({
    this.access = const AndroidReminderAccess(),
    this.consent = const ReminderDeliveryOptIn(ownerToken: ''),
    this.revision = 0,
  });
  final AndroidReminderAccess access;
  final ReminderDeliveryOptIn consent;
  final int revision;
  String get ownerScope =>
      sha256.convert(utf8.encode(consent.ownerToken)).toString();
  bool get authorized =>
      access.supported &&
      consent.enabled &&
      consent.acceptedInexactTiming &&
      access.notificationsEnabled &&
      (access.permission == ReminderNotificationPermission.granted ||
          (access.apiLevel < 33 &&
              access.permission ==
                  ReminderNotificationPermission.notRequested));
}

/// Dormant Dart transport only. No native handler, application wiring, manifest
/// permission or user toggle is introduced by this class.
class MethodChannelAndroidTaskReminderPort implements AndroidTaskReminderPort {
  MethodChannelAndroidTaskReminderPort({
    MethodChannel? channel,
    this.timeout = const Duration(seconds: 3),
    DateTime Function()? clock,
  }) : _channel = channel ?? const MethodChannel(channelName),
       _clock = clock ?? DateTime.now {
    if (timeout <= Duration.zero) {
      throw ArgumentError('A positive timeout is required.');
    }
  }
  static const channelName = 'com.newman.newmanapp/task_reminders_v1';
  final MethodChannel _channel;
  final DateTime Function() _clock;
  final Duration timeout;
  static final _opaqueKey = RegExp(r'^[a-f0-9]{64}$');
  static final _installationToken = RegExp(r'^[A-Za-z0-9_-]{16,128}$');

  Future<Map<Object?, Object?>> _call(
    String method,
    Map<String, Object> arguments,
  ) async {
    final Object? result;
    try {
      result = await _channel
          .invokeMethod<Object?>(method, {'protocol': 1, ...arguments})
          .timeout(timeout);
    } on MissingPluginException {
      throw const ReminderBridgeException(ReminderBridgeFailure.unavailable);
    } on TimeoutException {
      throw const ReminderBridgeException(ReminderBridgeFailure.unconfirmed);
    } on PlatformException {
      // Native error strings may contain private diagnostics. Do not forward or
      // log them, and do not assume the mutation did not execute.
      throw const ReminderBridgeException(ReminderBridgeFailure.unconfirmed);
    }
    if (result is! Map ||
        result['protocol'] is! int ||
        result['protocol'] != 1) {
      throw const ReminderBridgeException(ReminderBridgeFailure.invalidReply);
    }
    return Map<Object?, Object?>.from(result);
  }

  AndroidReminderBridgeState _parseState(Map<Object?, Object?> value) {
    if (value['supported'] == false) return const AndroidReminderBridgeState();
    final api = value['apiLevel'];
    final revision = value['revision'];
    final token = value['installationToken'];
    final permission = switch (value['permission']) {
      'notRequested' => ReminderNotificationPermission.notRequested,
      'granted' => ReminderNotificationPermission.granted,
      'denied' => ReminderNotificationPermission.denied,
      'unavailable' => ReminderNotificationPermission.unavailable,
      _ => null,
    };
    if (value['supported'] != true ||
        value['platform'] != 'android' ||
        value['deliveryMode'] != 'inexact' ||
        value['redaction'] != 'generic' ||
        api is! int ||
        api < 23 ||
        api > 1000 ||
        revision is! int ||
        revision < 0 ||
        token is! String ||
        !_installationToken.hasMatch(token) ||
        value['notificationsEnabled'] is! bool ||
        value['consentEnabled'] is! bool ||
        value['inexactAcknowledged'] is! bool ||
        permission == null) {
      throw const ReminderBridgeException(ReminderBridgeFailure.invalidReply);
    }
    return AndroidReminderBridgeState(
      access: AndroidReminderAccess(
        supported: true,
        apiLevel: api,
        notificationsEnabled: value['notificationsEnabled'] as bool,
        permission: permission,
      ),
      consent: ReminderDeliveryOptIn(
        ownerToken: token,
        enabled: value['consentEnabled'] as bool,
        acceptedInexactTiming: value['inexactAcknowledged'] as bool,
      ),
      revision: revision,
    );
  }

  /// Read-only probing never requests permission or changes consent.
  Future<AndroidReminderBridgeState> readState() async {
    try {
      return _parseState(await _call('getState', const {}));
    } on ReminderBridgeException {
      return const AndroidReminderBridgeState();
    }
  }

  /// A future explicit enable UI may call this, after explaining approximate
  /// delivery. Native code must request POST_NOTIFICATIONS only in this handler
  /// on API 33+, and persist opt-in only after permission is actually granted.
  Future<AndroidReminderBridgeState> enableFromUserAction({
    required bool userInitiated,
    required bool acceptedInexactTiming,
  }) async {
    if (!userInitiated || !acceptedInexactTiming) {
      throw ArgumentError('Explicit acknowledged opt-in is required.');
    }
    final before = await readState();
    if (!before.access.supported) {
      throw const ReminderBridgeException(ReminderBridgeFailure.unavailable);
    }
    final reply = _parseState(
      await _call('enableFromUserAction', {
        'userInitiated': true,
        'acceptedInexactTiming': true,
        'expectedOwnerScope': before.ownerScope,
        'expectedRevision': before.revision,
      }),
    );
    if (!reply.access.supported ||
        reply.ownerScope != before.ownerScope ||
        reply.revision < before.revision) {
      throw const ReminderBridgeException(ReminderBridgeFailure.invalidReply);
    }
    if (reply.consent.enabled && !reply.authorized) {
      await disableAndCancelAll();
      throw const ReminderBridgeException(ReminderBridgeFailure.notAuthorized);
    }
    if (!reply.consent.enabled) await _cancelAllPending();
    return reply; // A denied/dismissed prompt returns disabled only after confirmed cleanup.
  }

  Future<void> _cancelAllPending() async {
    final reply = await _call('cancelAllPending', const {});
    if (reply['cancelledAll'] != true || reply['postedCleared'] != true) {
      throw const ReminderBridgeException(ReminderBridgeFailure.unconfirmed);
    }
  }

  /// Persist Off before cancelling jobs/posted reminders. No permission is
  /// required for this operation; a missing handler cannot confirm cleanup.
  Future<void> disableAndCancelAll() async {
    final reply = await _call('disableAndCancelAll', const {});
    if (reply['consentEnabled'] != false ||
        reply['cancelledAll'] != true ||
        reply['postedCleared'] != true) {
      throw const ReminderBridgeException(ReminderBridgeFailure.unconfirmed);
    }
  }

  /// Explicit lifecycle reconciliation clears pending/posted reminders when
  /// consent, permission or channel access is blocked. It never prompts.
  Future<AndroidReminderBridgeState> reconcileAccess() async {
    final state = await readState();
    if (!state.access.supported) {
      throw const ReminderBridgeException(ReminderBridgeFailure.unavailable);
    }
    if (!state.authorized) await _cancelAllPending();
    return state;
  }

  @override
  Future<void> cancel(String key) async {
    if (!_opaqueKey.hasMatch(key)) {
      throw ArgumentError('An opaque reminder key is required.');
    }
    final reply = await _call('cancel', {'key': key});
    if (reply['key'] != key ||
        reply['cancelled'] != true ||
        reply['postedCleared'] != true) {
      throw const ReminderBridgeException(ReminderBridgeFailure.unconfirmed);
    }
  }

  @override
  Future<void> upsert(PlannedAndroidTaskReminder reminder) async {
    if (!_opaqueKey.hasMatch(reminder.key) ||
        !_opaqueKey.hasMatch(reminder.ownerScope) ||
        !reminder.notBeforeUtc.isUtc ||
        !reminder.expiresAtUtc.isUtc ||
        !reminder.expiresAtUtc.isAfter(reminder.notBeforeUtc) ||
        !reminder.notBeforeUtc.isAfter(_clock().toUtc())) {
      throw ArgumentError('A valid future redacted reminder is required.');
    }
    final state = await reconcileAccess();
    if (!state.authorized) {
      throw const ReminderBridgeException(ReminderBridgeFailure.notAuthorized);
    }
    if (state.ownerScope != reminder.ownerScope) {
      throw const ReminderBridgeException(ReminderBridgeFailure.notAuthorized);
    }
    final reply = await _call('upsert', {
      ...reminder.toPayload(),
      'expectedRevision': state.revision,
      'deliveryMode': 'inexact',
      'redaction': 'generic',
    });
    if (reply['key'] != reminder.key ||
        reply['ownerScope'] != state.ownerScope ||
        reply['revision'] is! int ||
        reply['revision'] != state.revision ||
        reply['ledgerCommitted'] != true ||
        reply['inexact'] != true ||
        reply['redacted'] != true) {
      throw const ReminderBridgeException(ReminderBridgeFailure.unconfirmed);
    }
  }
}
