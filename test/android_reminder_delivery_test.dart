import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/tasks/application/android_reminder_scheduler.dart';
import 'package:scripture_planner/src/features/tasks/domain/android_reminder_delivery.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';
import 'package:scripture_planner/src/features/tasks/domain/task_reminder.dart';

void main() {
  final now = DateTime(2026, 11, 17, 8);
  const consent = ReminderDeliveryOptIn(
    ownerToken: 'opaque-local-profile-1',
    enabled: true,
    acceptedInexactTiming: true,
  );
  const allowed = AndroidReminderAccess(
    supported: true,
    apiLevel: 33,
    notificationsEnabled: true,
    permission: ReminderNotificationPermission.granted,
  );
  Task task(String id, {int minute = 540, DateTime? day}) => Task(
    id: id,
    title: 'Private prayer and sensitive task title',
    isCompleted: false,
    dueDate: day ?? DateTime(2026, 11, 17),
    createdAt: now,
    updatedAt: now,
    reminderMinutesLocal: minute,
  );
  AndroidReminderReconciliation plan(
    List<Task> tasks, {
    ReminderDeliveryOptIn opt = consent,
    AndroidReminderAccess access = allowed,
    Iterable<PlannedAndroidTaskReminder> existing = const [],
    Set<String> delivered = const {},
    DateTime? clock,
    int limit = 64,
  }) => planAndroidTaskReminders(
    tasks: tasks,
    consent: opt,
    access: access,
    now: clock ?? now,
    existing: existing,
    deliveredKeys: delivered,
    limit: limit,
  );

  test(
    'unsupported and default Off cancel existing schedules without scheduling',
    () {
      final previous = plan([task('private-id')]).desired;
      final off = plan(
        [task('private-id')],
        opt: const ReminderDeliveryOptIn(ownerToken: 'opaque-local-profile-1'),
        existing: previous,
      );
      expect(off.upsert, isEmpty);
      expect(off.cancel, previous.map((e) => e.key));
      final unsupported = plan(
        [task('private-id')],
        access: const AndroidReminderAccess(),
        existing: previous,
      );
      expect(unsupported.desired, isEmpty);
      expect(unsupported.cancel, hasLength(1));
    },
  );

  test(
    'API 33 permission request requires the explicit acknowledged enable action',
    () {
      const requestable = AndroidReminderAccess(
        supported: true,
        apiLevel: 33,
        permission: ReminderNotificationPermission.notRequested,
      );
      expect(
        shouldRequestReminderPermission(
          userInitiatedEnable: false,
          consent: consent,
          access: requestable,
        ),
        isFalse,
      );
      expect(
        shouldRequestReminderPermission(
          userInitiatedEnable: true,
          consent: consent,
          access: requestable,
        ),
        isTrue,
      );
      for (final permission in [
        ReminderNotificationPermission.denied,
        ReminderNotificationPermission.granted,
        ReminderNotificationPermission.unavailable,
      ]) {
        expect(
          shouldRequestReminderPermission(
            userInitiatedEnable: true,
            consent: consent,
            access: AndroidReminderAccess(
              supported: true,
              apiLevel: 33,
              permission: permission,
            ),
          ),
          isFalse,
        );
      }
      expect(
        shouldRequestReminderPermission(
          userInitiatedEnable: true,
          consent: const ReminderDeliveryOptIn(ownerToken: 'x', enabled: true),
          access: requestable,
        ),
        isFalse,
      );
      expect(
        shouldRequestReminderPermission(
          userInitiatedEnable: true,
          consent: consent,
          access: const AndroidReminderAccess(
            supported: true,
            apiLevel: 32,
            permission: ReminderNotificationPermission.notRequested,
          ),
        ),
        isFalse,
      );
    },
  );

  test(
    'permission denial, blocked notifications and unacknowledged inexact timing fail closed',
    () {
      for (final access in [
        const AndroidReminderAccess(
          supported: true,
          apiLevel: 33,
          notificationsEnabled: true,
          permission: ReminderNotificationPermission.denied,
        ),
        const AndroidReminderAccess(
          supported: true,
          apiLevel: 33,
          notificationsEnabled: true,
          permission: ReminderNotificationPermission.notRequested,
        ),
        const AndroidReminderAccess(
          supported: true,
          apiLevel: 33,
          permission: ReminderNotificationPermission.granted,
        ),
      ]) {
        expect(plan([task('a')], access: access).desired, isEmpty);
      }
      expect(
        plan(
          [task('a')],
          opt: const ReminderDeliveryOptIn(ownerToken: 'x', enabled: true),
        ).desired,
        isEmpty,
      );
      expect(
        plan(
          [task('a')],
          opt: const ReminderDeliveryOptIn(
            ownerToken: '',
            enabled: true,
            acceptedInexactTiming: true,
          ),
        ).desired,
        isEmpty,
      );
      expect(
        plan(
          [task('a')],
          access: const AndroidReminderAccess(
            supported: true,
            apiLevel: 32,
            notificationsEnabled: true,
            permission: ReminderNotificationPermission.notRequested,
          ),
        ).desired,
        hasLength(1),
      );
    },
  );

  test(
    'payload is generic and contains no raw owner, task identifier or title',
    () {
      final source = task('private-id');
      final payload = plan([source]).desired.single.toPayload();
      final encoded = jsonEncode(payload);
      expect(payload['title'], 'New Man');
      expect(payload['body'], 'You have a task to review.');
      for (final value in [source.title, source.id, consent.ownerToken]) {
        expect(encoded, isNot(contains(value)));
      }
      expect(payload['key'], matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(() => plan([source]).desired.clear(), throwsUnsupportedError);
    },
  );

  test(
    'completion, deletion, dismissal and schedule edits cancel the previous key',
    () {
      final source = task('a');
      final previous = plan([source]).desired;
      for (final tasks in <List<Task>>[
        [],
        [source.copyWith(isCompleted: true, completedAt: now)],
        [source.copyWith(reminderDismissedKey: taskReminderKey(source))],
        [source.copyWith(clearReminder: true)],
      ]) {
        final next = plan(tasks, existing: previous);
        expect(next.cancel, hasLength(1));
        expect(next.upsert, isEmpty);
      }
      final edited = plan([
        source.copyWith(reminderMinutesLocal: 600),
      ], existing: previous);
      expect(edited.cancel, hasLength(1));
      expect(edited.upsert, hasLength(1));
      expect(edited.upsert.single.key, isNot(previous.single.key));
      final titleOnly = plan([
        source.copyWith(title: 'Edited private title'),
      ], existing: previous);
      expect(titleOnly.cancel, isEmpty);
      expect(titleOnly.upsert, isEmpty);
    },
  );

  test(
    'owner switch cancels old owner schedules and uses distinct opaque keys',
    () {
      final previous = plan([task('a')]).desired;
      final next = plan(
        [task('a')],
        opt: const ReminderDeliveryOptIn(
          ownerToken: 'opaque-profile-2',
          enabled: true,
          acceptedInexactTiming: true,
        ),
        existing: previous,
      );
      expect(next.cancel, hasLength(1));
      expect(next.upsert, hasLength(1));
      expect(next.upsert.single.ownerScope, isNot(previous.single.ownerScope));
      expect(next.upsert.single.key, isNot(previous.single.key));
    },
  );

  test(
    'overdue reminders stay in-app, and durable receipts prevent clock-rollback re-alerts',
    () {
      final source = task('a');
      final scheduled = plan([source]).desired.single;
      expect(
        plan([source], clock: DateTime(2026, 11, 17, 10)).desired,
        isEmpty,
      );
      expect(
        plan(
          [source],
          delivered: {scheduled.key},
          clock: DateTime(2026, 11, 17, 8, 30),
        ).desired,
        isEmpty,
      );
      final fall = task('fall', minute: 90, day: DateTime(2026, 11, 1));
      final first = plan([
        fall,
      ], clock: DateTime(2026, 11, 1, 0, 30)).desired.single;
      expect(
        plan(
          [fall],
          delivered: {first.key},
          clock: DateTime(2026, 11, 1, 1),
        ).desired,
        isEmpty,
      );
    },
  );

  test(
    'DST gap resolves to the first valid local minute and expires at local midnight',
    () {
      final spring = task('spring', minute: 150, day: DateTime(2026, 3, 8));
      final selected = plan([
        spring,
      ], clock: DateTime(2026, 3, 8, 1)).desired.single;
      // Run with TZ=America/New_York: local 02:30 does not exist.
      if (DateTime(2026, 3, 8, 2, 30).hour != 2) {
        expect(selected.notBeforeUtc, DateTime(2026, 3, 8, 3).toUtc());
      } else {
        expect(selected.notBeforeUtc, DateTime(2026, 3, 8, 2, 30).toUtc());
      }
      expect(selected.expiresAtUtc, DateTime(2026, 3, 9).toUtc());
    },
  );

  test(
    'bounded schedules are deterministic, reject duplicate snapshots and reconcile clock changes',
    () {
      final tasks = [
        for (var i = 0; i < 70; i++) task('id-$i', minute: 540 + i),
      ];
      final first = plan(tasks);
      final reordered = plan(tasks.reversed.toList());
      expect(first.desired, hasLength(64));
      expect(first.deferredCount, 6);
      expect(
        first.desired.map((r) => r.key),
        reordered.desired.map((r) => r.key),
      );
      expect(() => plan([task('a'), task('a')]), throwsStateError);
      expect(() => plan(tasks, limit: 65), throwsArgumentError);
      final desired = plan([task('a')]).desired.single;
      final shifted = PlannedAndroidTaskReminder(
        key: desired.key,
        ownerScope: desired.ownerScope,
        notBeforeUtc: desired.notBeforeUtc.add(const Duration(hours: 1)),
        expiresAtUtc: desired.expiresAtUtc,
      );
      final change = plan([task('a')], existing: [shifted]);
      expect(change.cancel, [desired.key]);
      expect(change.upsert.single.matches(desired), isTrue);
    },
  );

  test(
    'duplicate native ledger entries are cancelled without adding schedules',
    () {
      final scheduled = plan([task('a')]).desired.single;
      final result = plan([task('a')], existing: [scheduled, scheduled]);
      expect(result.cancel, [scheduled.key]);
      expect(result.upsert, isEmpty);
      expect(result.desired, isEmpty);
    },
  );

  test(
    'cancellation failure blocks new schedules and a later retry remains usable',
    () async {
      final wanted = plan([task('a')]).desired.single;
      final port = _Port()..failCancel = true;
      final sync = AndroidReminderSynchronizer();
      Future<AndroidReminderReconciliation> builder() async =>
          AndroidReminderReconciliation(
            cancel: ['obsolete'],
            upsert: [wanted],
            desired: [wanted],
          );
      await expectLater(
        sync.reconcile(port: port, buildPlan: builder),
        throwsStateError,
      );
      expect(port.events, ['cancel:obsolete']);
      port.failCancel = false;
      await sync.reconcile(port: port, buildPlan: builder);
      expect(port.events.last, 'upsert:${wanted.key}');
    },
  );

  test(
    'a new opt-out request invalidates stale upserts while cancellation is pending',
    () async {
      final wanted = plan([task('a')]).desired.single;
      final port = _Port()..cancelGate = Completer<void>();
      final entered = Completer<void>();
      port.onCancel = () => entered.complete();
      final sync = AndroidReminderSynchronizer();
      final old = sync.reconcile(
        port: port,
        buildPlan: () async => AndroidReminderReconciliation(
          cancel: ['obsolete'],
          upsert: [wanted],
          desired: [wanted],
        ),
      );
      await entered.future;
      final off = sync.reconcile(
        port: port,
        buildPlan: () async =>
            AndroidReminderReconciliation(cancel: [], upsert: [], desired: []),
      );
      port.cancelGate!.complete();
      final statuses = await Future.wait([old, off]);
      expect(statuses, [
        ReminderReconciliationStatus.superseded,
        ReminderReconciliationStatus.applied,
      ]);
      expect(port.events, ['cancel:obsolete']);
    },
  );

  test(
    'uncertain upsert outcomes reconcile from the latest durable ledger without duplicates',
    () async {
      final source = task('a');
      final port = _Port()..failAfterUpsert = true;
      final sync = AndroidReminderSynchronizer();
      Future<AndroidReminderReconciliation> builder() async =>
          plan([source], existing: port.ledger.values);
      await expectLater(
        sync.reconcile(port: port, buildPlan: builder),
        throwsStateError,
      );
      port.failAfterUpsert = false;
      await sync.reconcile(port: port, buildPlan: builder);
      expect(port.ledger, hasLength(1));
      expect(port.events.where((e) => e.startsWith('upsert:')), hasLength(1));
    },
  );
}

class _Port implements AndroidTaskReminderPort {
  final ledger = <String, PlannedAndroidTaskReminder>{};
  final events = <String>[];
  bool failCancel = false;
  bool failAfterUpsert = false;
  Completer<void>? cancelGate;
  void Function()? onCancel;
  @override
  Future<void> cancel(String key) async {
    events.add('cancel:$key');
    onCancel?.call();
    if (cancelGate != null) await cancelGate!.future;
    if (failCancel) throw StateError('synthetic cancellation failure');
    ledger.remove(key);
  }

  @override
  Future<void> upsert(PlannedAndroidTaskReminder reminder) async {
    events.add('upsert:${reminder.key}');
    ledger[reminder.key] = reminder;
    if (failAfterUpsert) throw StateError('synthetic uncertain reply');
  }
}
