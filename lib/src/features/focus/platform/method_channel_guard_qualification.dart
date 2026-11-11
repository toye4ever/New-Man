import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/guard_qualification.dart';
import '../domain/guard_readiness.dart';

GuardQualificationGateway createGuardQualificationGateway({
  MethodChannel? channel,
}) {
  final platform = _guardPlatform();
  if (platform != GuardPlatform.android) {
    return UnsupportedGuardQualificationGateway(platform);
  }
  return MethodChannelGuardQualificationGateway(channel: channel);
}

class MethodChannelGuardQualificationGateway
    implements GuardQualificationGateway, GuardQualificationPendingCalls {
  MethodChannelGuardQualificationGateway({
    MethodChannel? channel,
    this.statusTimeout = const Duration(seconds: 5),
    this.commandTimeout = const Duration(seconds: 8),
    this.settingsTimeout = const Duration(seconds: 5),
  }) : assert(statusTimeout > Duration.zero),
       assert(commandTimeout > Duration.zero),
       assert(settingsTimeout > Duration.zero),
       _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.newman.newmanapp/guard_qualification';

  final MethodChannel _channel;
  final Duration statusTimeout;
  final Duration commandTimeout;
  final Duration settingsTimeout;
  final Set<void Function()> _pendingCancellations = {};

  @override
  Future<GuardQualificationSnapshot> getStatus() =>
      _invoke('getStatus', timeout: statusTimeout);

  @override
  Future<GuardQualificationSnapshot> start(
    GuardQualificationStartRequest request,
  ) {
    if (request.selectedTargets.isEmpty ||
        request.durationMinutes < 15 ||
        request.durationMinutes > 240 ||
        !request.disclosureAccepted) {
      throw const GuardQualificationUnavailable('Invalid start request.');
    }
    return _invoke(
      'start',
      arguments: <String, Object>{
        'schemaVersion': 1,
        'selectedTargetIds': request.selectedTargets
            .map((target) => target.id)
            .toList(growable: false),
        'durationMinutes': request.durationMinutes,
        'disclosureAccepted': request.disclosureAccepted,
      },
      timeout: commandTimeout,
    );
  }

  @override
  Future<GuardQualificationSnapshot> pause() =>
      _invoke('pause', timeout: commandTimeout);

  @override
  Future<GuardQualificationSnapshot> resume() =>
      _invoke('resume', timeout: commandTimeout);

  @override
  Future<GuardQualificationSnapshot> end() =>
      _invoke('end', timeout: commandTimeout);

  @override
  Future<void> openAccessibilitySettings() async {
    final result = await _bounded(
      _channel.invokeMethod<Object?>('openAccessibilitySettings'),
      settingsTimeout,
      'Android settings',
    );
    if (result != true) {
      throw const FormatException('Invalid settings response.');
    }
  }

  Future<GuardQualificationSnapshot> _invoke(
    String method, {
    Object? arguments,
    required Duration timeout,
  }) async {
    final payload = await _bounded(
      _channel.invokeMethod<Object?>(method, arguments),
      timeout,
      method,
    );
    return decodeGuardQualificationSnapshot(payload);
  }

  Future<T> _bounded<T>(Future<T> operation, Duration timeout, String label) {
    final completer = Completer<T>();
    late final Timer timer;
    late final void Function() cancel;

    void finishValue(T value) {
      if (completer.isCompleted) return;
      timer.cancel();
      _pendingCancellations.remove(cancel);
      completer.complete(value);
    }

    void finishError(Object error, [StackTrace? stackTrace]) {
      if (completer.isCompleted) return;
      timer.cancel();
      _pendingCancellations.remove(cancel);
      completer.completeError(error, stackTrace);
    }

    cancel = () => finishError(
      const GuardQualificationUnavailable(
        'The pending native call was closed.',
      ),
    );
    _pendingCancellations.add(cancel);
    timer = Timer(
      timeout,
      () => finishError(
        GuardQualificationUnavailable(
          '$label did not respond within the safety timeout.',
        ),
      ),
    );
    operation.then(finishValue, onError: finishError);
    return completer.future;
  }

  @override
  void cancelPending() {
    for (final cancel in List<void Function()>.of(_pendingCancellations)) {
      cancel();
    }
  }
}

abstract interface class GuardQualificationPendingCalls {
  void cancelPending();
}

class UnsupportedGuardQualificationGateway
    implements GuardQualificationGateway {
  const UnsupportedGuardQualificationGateway(this.platform);

  final GuardPlatform platform;

  @override
  Future<GuardQualificationSnapshot> getStatus() async =>
      GuardQualificationSnapshot.unavailable(platform);

  @override
  Future<GuardQualificationSnapshot> start(
    GuardQualificationStartRequest request,
  ) => _unsupported();

  @override
  Future<GuardQualificationSnapshot> pause() => _unsupported();

  @override
  Future<GuardQualificationSnapshot> resume() => _unsupported();

  @override
  Future<GuardQualificationSnapshot> end() => _unsupported();

  @override
  Future<void> openAccessibilitySettings() => _unsupported();

  Future<T> _unsupported<T>() => Future<T>.error(
    const GuardQualificationUnavailable(
      'The Android qualification test is not available on this platform.',
    ),
  );
}

GuardQualificationSnapshot decodeGuardQualificationSnapshot(Object? payload) {
  if (payload is! Map<Object?, Object?> ||
      payload.keys.toSet().difference(_snapshotKeys).isNotEmpty ||
      _snapshotKeys.difference(payload.keys.toSet()).isNotEmpty ||
      payload['schemaVersion'] != 1 ||
      payload['platform'] != 'android') {
    throw const FormatException('Invalid Guard qualification envelope.');
  }

  final rawStatus = payload['status'];
  final remainingMillis = payload['remainingMillis'];
  final rawTargets = payload['selectedTargetIds'];
  final serviceConnected = payload['serviceConnected'];
  final disclosureAccepted = payload['disclosureAccepted'];
  final detailCode = payload['detailCode'];
  if (rawStatus is! String ||
      remainingMillis is! int ||
      remainingMillis < 0 ||
      remainingMillis > 240 * 60 * 1000 ||
      rawTargets is! List<Object?> ||
      serviceConnected is! bool ||
      disclosureAccepted is! bool ||
      (detailCode != null && detailCode is! String)) {
    throw const FormatException('Invalid Guard qualification fields.');
  }

  final status = _statusByName[rawStatus];
  if (status == null || status == GuardQualificationStatus.unavailable) {
    throw const FormatException('Invalid Guard qualification status.');
  }
  final targets = <GuardQualificationTarget>{};
  for (final rawTarget in rawTargets) {
    if (rawTarget is! String) {
      throw const FormatException('Invalid Guard qualification target.');
    }
    final target = _targetById[rawTarget];
    if (target == null || !targets.add(target)) {
      throw const FormatException('Invalid Guard qualification target.');
    }
  }
  if (detailCode != null && !_detailCodes.contains(detailCode)) {
    throw const FormatException('Invalid Guard qualification detail.');
  }

  final active =
      status == GuardQualificationStatus.running ||
      status == GuardQualificationStatus.paused;
  if (active &&
          (remainingMillis <= 0 ||
              targets.isEmpty ||
              !serviceConnected ||
              !disclosureAccepted) ||
      !active &&
          (remainingMillis != 0 || targets.isNotEmpty || disclosureAccepted)) {
    throw const FormatException('Inconsistent Guard qualification state.');
  }

  return GuardQualificationSnapshot(
    platform: GuardPlatform.android,
    status: status,
    remainingMillis: remainingMillis,
    selectedTargets: targets,
    serviceConnected: serviceConnected,
    disclosureAccepted: disclosureAccepted,
    detailCode: detailCode as String?,
  );
}

GuardPlatform _guardPlatform() {
  if (kIsWeb) return GuardPlatform.unknown;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => GuardPlatform.android,
    TargetPlatform.iOS => GuardPlatform.ios,
    TargetPlatform.windows => GuardPlatform.windows,
    _ => GuardPlatform.unknown,
  };
}

const _snapshotKeys = <Object?>{
  'schemaVersion',
  'platform',
  'status',
  'remainingMillis',
  'selectedTargetIds',
  'serviceConnected',
  'disclosureAccepted',
  'detailCode',
};

const _statusByName = <String, GuardQualificationStatus>{
  'idle': GuardQualificationStatus.idle,
  'running': GuardQualificationStatus.running,
  'paused': GuardQualificationStatus.paused,
  'completed': GuardQualificationStatus.completed,
  'ended': GuardQualificationStatus.ended,
  'interrupted': GuardQualificationStatus.interrupted,
  'error': GuardQualificationStatus.error,
};

const _targetById = <String, GuardQualificationTarget>{
  'youtube_app': GuardQualificationTarget.youtubeApp,
  'instagram_app': GuardQualificationTarget.instagramApp,
  'facebook_app': GuardQualificationTarget.facebookApp,
  'tiktok_app': GuardQualificationTarget.tiktokApp,
};

const _detailCodes = <String>{
  'expired',
  'ended_by_user',
  'service_interrupted',
  'service_disconnected',
  'service_reconnected',
  'consent_withdrawn',
  'prerequisite_lost',
  'global_action_failed',
  'event_delivery_unavailable',
  'clock_invalid',
  'interrupted',
  'error',
};
