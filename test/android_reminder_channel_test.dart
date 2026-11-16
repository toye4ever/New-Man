import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/tasks/data/platform/android_task_reminder_channel.dart';
import 'package:scripture_planner/src/features/tasks/domain/android_reminder_delivery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/newman/task-reminders');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final now = DateTime.utc(2026, 11, 17, 8);
  const token = 'opaque-installation-token-123';
  final scope = sha256.convert(utf8.encode(token)).toString();
  final key = 'a' * 64;
  late MethodChannelAndroidTaskReminderPort bridge;
  late List<MethodCall> calls;
  Map<String, Object> state({
    bool enabled = false,
    String permission = 'notRequested',
    bool notifications = false,
    int revision = 1,
  }) => {
    'protocol': 1,
    'supported': true,
    'platform': 'android',
    'apiLevel': 33,
    'deliveryMode': 'inexact',
    'redaction': 'generic',
    'installationToken': token,
    'revision': revision,
    'notificationsEnabled': notifications,
    'permission': permission,
    'consentEnabled': enabled,
    'inexactAcknowledged': enabled,
  };
  PlannedAndroidTaskReminder reminder({String? owner, DateTime? trigger}) =>
      PlannedAndroidTaskReminder(
        key: key,
        ownerScope: owner ?? scope,
        notBeforeUtc: trigger ?? now.add(const Duration(hours: 1)),
        expiresAtUtc: now.add(const Duration(hours: 16)),
      );
  void mock(FutureOr<Object?> Function(MethodCall) handler) =>
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return handler(call);
      });
  Matcher fails(ReminderBridgeFailure failure) => throwsA(
    isA<ReminderBridgeException>().having((e) => e.failure, 'failure', failure),
  );
  setUp(() {
    calls = [];
    bridge = MethodChannelAndroidTaskReminderPort(
      channel: channel,
      clock: () => now,
    );
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'missing handler is unsupported and cannot confirm cancellation',
    () async {
      expect((await bridge.readState()).access.supported, isFalse);
      await expectLater(
        bridge.cancel(key),
        fails(ReminderBridgeFailure.unavailable),
      );
      await expectLater(
        bridge.disableAndCancelAll(),
        fails(ReminderBridgeFailure.unavailable),
      );
    },
  );

  test(
    'read-only probe defaults Off without permission or mutation calls',
    () async {
      mock((call) => state());
      final result = await bridge.readState();
      expect(result.access.supported, isTrue);
      expect(result.consent.enabled, isFalse);
      expect(result.authorized, isFalse);
      expect(calls.map((c) => c.method), ['getState']);
    },
  );

  test(
    'malformed, unknown or exact-alarm protocols never authorize delivery',
    () async {
      for (final invalid in <Object?>[
        null,
        [],
        {'protocol': 2, 'supported': true},
        {...state(), 'protocol': 1.0},
        {...state(), 'deliveryMode': 'exact'},
        {...state(), 'platform': 'ios'},
        {...state(), 'redaction': 'taskTitle'},
        {...state(), 'apiLevel': '33'},
        {...state(), 'installationToken': 'person@example.com'},
        {...state(), 'revision': -1},
        {...state(), 'permission': 'probablyGranted'},
        {...state(), 'consentEnabled': 'true'},
      ]) {
        mock((call) => invalid);
        expect((await bridge.readState()).access.supported, isFalse);
      }
      expect(calls.every((c) => c.method == 'getState'), isTrue);
    },
  );

  test(
    'enable rejects implicit or unacknowledged intent before any channel call',
    () async {
      mock((call) => state());
      await expectLater(
        bridge.enableFromUserAction(
          userInitiated: false,
          acceptedInexactTiming: true,
        ),
        throwsArgumentError,
      );
      await expectLater(
        bridge.enableFromUserAction(
          userInitiated: true,
          acceptedInexactTiming: false,
        ),
        throwsArgumentError,
      );
      expect(calls, isEmpty);
    },
  );

  test(
    'explicit enable includes scope/revision guards and accepts only confirmed state',
    () async {
      mock((call) {
        if (call.method == 'getState') return state();
        expect(call.method, 'enableFromUserAction');
        expect(call.arguments, {
          'protocol': 1,
          'userInitiated': true,
          'acceptedInexactTiming': true,
          'expectedOwnerScope': scope,
          'expectedRevision': 1,
        });
        return state(
          enabled: true,
          permission: 'granted',
          notifications: true,
          revision: 2,
        );
      });
      final result = await bridge.enableFromUserAction(
        userInitiated: true,
        acceptedInexactTiming: true,
      );
      expect(result.authorized, isTrue);
      expect(result.revision, 2);
      expect(calls.map((c) => c.method), ['getState', 'enableFromUserAction']);
      expect(jsonEncode(calls.last.arguments), isNot(contains(token)));
    },
  );

  test('stale installation/revision replies cannot confirm enable', () async {
    for (final reply in [
      {
        ...state(
          enabled: true,
          permission: 'granted',
          notifications: true,
          revision: 2,
        ),
        'installationToken': 'different-installation-token',
      },
      state(
        enabled: true,
        permission: 'granted',
        notifications: true,
        revision: 0,
      ),
    ]) {
      mock((call) => call.method == 'getState' ? state() : reply);
      await expectLater(
        bridge.enableFromUserAction(
          userInitiated: true,
          acceptedInexactTiming: true,
        ),
        fails(ReminderBridgeFailure.invalidReply),
      );
    }
  });

  test(
    'permission denial remains disabled and never produces an upsert',
    () async {
      mock((call) {
        if (call.method == 'getState') return state();
        if (call.method == 'enableFromUserAction') {
          return state(permission: 'denied', revision: 2);
        }
        return {'protocol': 1, 'cancelledAll': true, 'postedCleared': true};
      });
      final result = await bridge.enableFromUserAction(
        userInitiated: true,
        acceptedInexactTiming: true,
      );
      expect(result.consent.enabled, isFalse);
      expect(result.authorized, isFalse);
      expect(calls.any((c) => c.method == 'upsert'), isFalse);
    },
  );

  test(
    'native enabled-without-permission violation triggers confirmed disable cleanup',
    () async {
      mock((call) {
        if (call.method == 'getState') return state();
        if (call.method == 'enableFromUserAction') {
          return state(enabled: true, permission: 'denied', revision: 2);
        }
        return {
          'protocol': 1,
          'consentEnabled': false,
          'cancelledAll': true,
          'postedCleared': true,
        };
      });
      await expectLater(
        bridge.enableFromUserAction(
          userInitiated: true,
          acceptedInexactTiming: true,
        ),
        fails(ReminderBridgeFailure.notAuthorized),
      );
      expect(calls.last.method, 'disableAndCancelAll');
    },
  );

  test(
    'upsert sends only opaque generic inexact payload with revision guard',
    () async {
      mock((call) {
        if (call.method == 'getState') {
          return state(
            enabled: true,
            permission: 'granted',
            notifications: true,
            revision: 4,
          );
        }
        final args = Map<Object?, Object?>.from(call.arguments as Map);
        expect(args['title'], 'New Man');
        expect(args['body'], 'You have a task to review.');
        expect(args['deliveryMode'], 'inexact');
        expect(args['redaction'], 'generic');
        expect(args['expectedRevision'], 4);
        expect(args.containsKey('taskId'), isFalse);
        expect(args.containsKey('installationToken'), isFalse);
        return {
          'protocol': 1,
          'key': key,
          'ledgerCommitted': true,
          'ownerScope': scope,
          'revision': 4,
          'inexact': true,
          'redacted': true,
        };
      });
      await bridge.upsert(reminder());
      expect(calls.map((c) => c.method), ['getState', 'upsert']);
    },
  );

  test(
    'permission/channel revocation clears pending jobs and posted reminders without prompting',
    () async {
      mock((call) {
        if (call.method == 'getState') {
          return state(enabled: true, permission: 'denied');
        }
        expect(call.method, 'cancelAllPending');
        return {'protocol': 1, 'cancelledAll': true, 'postedCleared': true};
      });
      final blocked = await bridge.reconcileAccess();
      expect(blocked.authorized, isFalse);
      await expectLater(
        bridge.upsert(reminder()),
        fails(ReminderBridgeFailure.notAuthorized),
      );
      expect(
        calls.any(
          (c) => c.method == 'enableFromUserAction' || c.method == 'upsert',
        ),
        isFalse,
      );
      expect(calls.where((c) => c.method == 'cancelAllPending'), hasLength(2));
    },
  );

  test(
    'partial revocation cleanup is unconfirmed and cannot authorize new jobs',
    () async {
      mock(
        (call) => call.method == 'getState'
            ? state(enabled: true, permission: 'denied')
            : {'protocol': 1, 'cancelledAll': true, 'postedCleared': false},
      );
      await expectLater(
        bridge.reconcileAccess(),
        fails(ReminderBridgeFailure.unconfirmed),
      );
      expect(calls.map((c) => c.method), ['getState', 'cancelAllPending']);
    },
  );

  test(
    'cancellation works without permission and requires matching key/posted cleanup',
    () async {
      for (final invalid in [
        {
          'protocol': 1,
          'key': 'b' * 64,
          'cancelled': true,
          'postedCleared': true,
        },
        {'protocol': 1, 'key': key, 'cancelled': false, 'postedCleared': true},
        {'protocol': 1, 'key': key, 'cancelled': true, 'postedCleared': false},
      ]) {
        mock((call) => invalid);
        await expectLater(
          bridge.cancel(key),
          fails(ReminderBridgeFailure.unconfirmed),
        );
      }
      mock(
        (call) => {
          'protocol': 1,
          'key': key,
          'cancelled': true,
          'postedCleared': true,
        },
      );
      await bridge.cancel(key);
      await bridge.cancel(key);
      expect(calls.every((c) => c.method == 'cancel'), isTrue);
    },
  );

  test(
    'Off cleanup cannot be claimed if disabled state or job cleanup is missing',
    () async {
      mock(
        (call) => {
          'protocol': 1,
          'consentEnabled': true,
          'cancelledAll': true,
          'postedCleared': true,
        },
      );
      await expectLater(
        bridge.disableAndCancelAll(),
        fails(ReminderBridgeFailure.unconfirmed),
      );
      mock(
        (call) => {
          'protocol': 1,
          'consentEnabled': false,
          'cancelledAll': true,
          'postedCleared': true,
        },
      );
      await bridge.disableAndCancelAll();
      expect(calls.every((c) => c.method == 'disableAndCancelAll'), isTrue);
    },
  );

  test(
    'expired or malformed requests fail locally, and wrong installation scope cannot upsert',
    () async {
      mock(
        (call) =>
            state(enabled: true, permission: 'granted', notifications: true),
      );
      await expectLater(
        bridge.cancel('private task identifier'),
        throwsArgumentError,
      );
      await expectLater(
        bridge.upsert(reminder(trigger: now)),
        throwsArgumentError,
      );
      expect(calls, isEmpty);
      await expectLater(
        bridge.upsert(reminder(owner: 'b' * 64)),
        fails(ReminderBridgeFailure.notAuthorized),
      );
      expect(calls.map((c) => c.method), ['getState']);
    },
  );

  test(
    'wrong-scope or stale upsert acknowledgement stays unconfirmed',
    () async {
      for (final reply in [
        {
          'protocol': 1,
          'key': key,
          'ownerScope': 'b' * 64,
          'revision': 4,
          'ledgerCommitted': true,
          'inexact': true,
          'redacted': true,
        },
        {
          'protocol': 1,
          'key': key,
          'ownerScope': scope,
          'revision': 3,
          'ledgerCommitted': true,
          'inexact': true,
          'redacted': true,
        },
        {
          'protocol': 1,
          'key': key,
          'ownerScope': scope,
          'revision': 4.0,
          'ledgerCommitted': true,
          'inexact': true,
          'redacted': true,
        },
      ]) {
        mock(
          (call) => call.method == 'getState'
              ? state(
                  enabled: true,
                  permission: 'granted',
                  notifications: true,
                  revision: 4,
                )
              : reply,
        );
        await expectLater(
          bridge.upsert(reminder()),
          fails(ReminderBridgeFailure.unconfirmed),
        );
      }
    },
  );

  test(
    'unconfirmed native ledger replies do not count as successful scheduling',
    () async {
      mock(
        (call) => call.method == 'getState'
            ? state(enabled: true, permission: 'granted', notifications: true)
            : {
                'protocol': 1,
                'key': key,
                'ownerScope': scope,
                'revision': 1,
                'ledgerCommitted': false,
                'inexact': true,
                'redacted': true,
              },
      );
      await expectLater(
        bridge.upsert(reminder()),
        fails(ReminderBridgeFailure.unconfirmed),
      );
      expect(calls.where((c) => c.method == 'upsert'), hasLength(1));
    },
  );

  test(
    'timeouts are uncertain and late replies never trigger retries or state changes',
    () async {
      final pending = Completer<Object?>();
      mock((call) => pending.future);
      bridge = MethodChannelAndroidTaskReminderPort(
        channel: channel,
        clock: () => now,
        timeout: const Duration(milliseconds: 10),
      );
      await expectLater(
        bridge.disableAndCancelAll(),
        fails(ReminderBridgeFailure.unconfirmed),
      );
      expect(calls, hasLength(1));
      pending.complete({
        'protocol': 1,
        'consentEnabled': false,
        'cancelledAll': true,
        'postedCleared': true,
      });
      await Future<void>.delayed(Duration.zero);
      expect(calls, hasLength(1));
    },
  );

  test(
    'native error diagnostics are redacted and never forwarded as success',
    () async {
      mock(
        (call) => throw PlatformException(
          code: 'sensitive',
          message: 'private task and user data',
        ),
      );
      try {
        await bridge.cancel(key);
        fail('Expected failure');
      } on ReminderBridgeException catch (error) {
        expect(error.failure, ReminderBridgeFailure.unconfirmed);
        expect(error.toString(), isNot(contains('private')));
      }
      expect((await bridge.readState()).access.supported, isFalse);
    },
  );
}
