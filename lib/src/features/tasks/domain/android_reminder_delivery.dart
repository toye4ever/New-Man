import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'task.dart';
import 'task_reminder.dart';

enum ReminderNotificationPermission {
  notRequested,
  granted,
  denied,
  unavailable,
}

/// A snapshot supplied by a future qualified native adapter. Unsupported is the
/// default; this boundary neither requests permission nor posts notifications.
class AndroidReminderAccess {
  const AndroidReminderAccess({
    this.supported = false,
    this.apiLevel = 0,
    this.notificationsEnabled = false,
    this.permission = ReminderNotificationPermission.unavailable,
  });
  final bool supported;
  final int apiLevel;
  final bool notificationsEnabled;
  final ReminderNotificationPermission permission;
}

class ReminderDeliveryOptIn {
  const ReminderDeliveryOptIn({
    required this.ownerToken,
    this.enabled = false,
    this.acceptedInexactTiming = false,
  });

  /// An opaque local installation identifier, never a name or email address.
  final String ownerToken;
  final bool enabled;
  final bool acceptedInexactTiming;
}

/// Call only from the explicit enable action, never bootstrap or reconciliation.
bool shouldRequestReminderPermission({
  required bool userInitiatedEnable,
  required ReminderDeliveryOptIn consent,
  required AndroidReminderAccess access,
}) =>
    userInitiatedEnable &&
    consent.enabled &&
    consent.acceptedInexactTiming &&
    consent.ownerToken.trim().isNotEmpty &&
    access.supported &&
    access.apiLevel >= 33 &&
    access.permission == ReminderNotificationPermission.notRequested;

String _digest(String value) => sha256.convert(utf8.encode(value)).toString();

class PlannedAndroidTaskReminder {
  const PlannedAndroidTaskReminder({
    required this.key,
    required this.ownerScope,
    required this.notBeforeUtc,
    required this.expiresAtUtc,
  });
  final String key;
  final String ownerScope;
  final DateTime notBeforeUtc;
  final DateTime expiresAtUtc;

  /// No task title, scripture, checklist, notes, or raw user/task identifiers.
  Map<String, Object> toPayload() => {
    'key': key,
    'ownerScope': ownerScope,
    'notBeforeUtcMillis': notBeforeUtc.millisecondsSinceEpoch,
    'expiresAtUtcMillis': expiresAtUtc.millisecondsSinceEpoch,
    'title': 'New Man',
    'body': 'You have a task to review.',
  };

  bool matches(PlannedAndroidTaskReminder other) =>
      key == other.key &&
      ownerScope == other.ownerScope &&
      notBeforeUtc == other.notBeforeUtc &&
      expiresAtUtc == other.expiresAtUtc;
}

class AndroidReminderReconciliation {
  AndroidReminderReconciliation({
    required Iterable<String> cancel,
    required Iterable<PlannedAndroidTaskReminder> upsert,
    required Iterable<PlannedAndroidTaskReminder> desired,
    this.deferredCount = 0,
  }) : cancel = List.unmodifiable(cancel),
       upsert = List.unmodifiable(upsert),
       desired = List.unmodifiable(desired);
  final List<String> cancel;
  final List<PlannedAndroidTaskReminder> upsert;
  final List<PlannedAndroidTaskReminder> desired;
  final int deferredCount;
}

/// Resolve a local wall time. A spring-forward gap moves to the first valid
/// minute after the gap, not to a silently normalized minute within that hour.
DateTime? _resolveLocalTime(DateTime day, int minutes) {
  for (var value = minutes; value < 1440; value++) {
    final result = DateTime(
      day.year,
      day.month,
      day.day,
      value ~/ 60,
      value % 60,
    );
    if (result.year == day.year &&
        result.month == day.month &&
        result.day == day.day &&
        result.hour == value ~/ 60 &&
        result.minute == value % 60) {
      return result;
    }
  }
  return null; // Entire skipped local dates never produce a notification.
}

/// A pure proposal, not evidence of scheduling/delivery. Only future reminders
/// are scheduled; overdue items remain in the foreground inbox. Receipts must
/// be durably written by the eventual adapter to prevent repeated-hour alerts.
AndroidReminderReconciliation planAndroidTaskReminders({
  required Iterable<Task> tasks,
  required ReminderDeliveryOptIn consent,
  required AndroidReminderAccess access,
  required DateTime now,
  Iterable<PlannedAndroidTaskReminder> existing = const [],
  Set<String> deliveredKeys = const {},
  int limit = 64,
}) {
  if (limit < 1 || limit > 64) throw ArgumentError.value(limit, 'limit');
  final desired = <String, PlannedAndroidTaskReminder>{};
  final allowed =
      consent.enabled &&
      consent.acceptedInexactTiming &&
      consent.ownerToken.trim().isNotEmpty &&
      access.supported &&
      access.apiLevel >= 23 &&
      access.notificationsEnabled &&
      (access.permission == ReminderNotificationPermission.granted ||
          (access.apiLevel < 33 &&
              access.permission ==
                  ReminderNotificationPermission.notRequested));
  if (allowed) {
    final ownerScope = _digest(consent.ownerToken);
    final seenTasks = <String>{};
    for (final task in tasks) {
      if (!seenTasks.add(task.id)) throw StateError('Duplicate task snapshot.');
      final reminderKey = taskReminderKey(task);
      if (task.isCompleted ||
          reminderKey == null ||
          reminderKey == task.reminderDismissedKey) {
        continue;
      }
      final trigger = _resolveLocalTime(
        task.dueDate!,
        task.reminderMinutesLocal!,
      );
      if (trigger == null || !trigger.isAfter(now)) continue;
      final key = _digest(jsonEncode([ownerScope, task.id, reminderKey]));
      if (deliveredKeys.contains(key)) continue;
      desired[key] = PlannedAndroidTaskReminder(
        key: key,
        ownerScope: ownerScope,
        notBeforeUtc: trigger.toUtc(),
        expiresAtUtc: DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day + 1,
        ).toUtc(),
      );
    }
  }
  final ordered = desired.values.toList()
    ..sort((a, b) {
      final time = a.notBeforeUtc.compareTo(b.notBeforeUtc);
      return time != 0 ? time : a.key.compareTo(b.key);
    });
  final selected = {for (final item in ordered.take(limit)) item.key: item};
  final previous = <String, PlannedAndroidTaskReminder>{};
  var duplicateNativeKeys = false;
  for (final item in existing) {
    if (previous.containsKey(item.key)) duplicateNativeKeys = true;
    previous[item.key] = item;
  }
  if (duplicateNativeKeys) {
    final cancel = previous.keys.toList()..sort();
    return AndroidReminderReconciliation(
      cancel: cancel,
      upsert: const [],
      desired: const [],
      deferredCount: ordered.length,
    );
  }
  final cancel =
      previous.values
          .where(
            (item) =>
                !selected.containsKey(item.key) ||
                !selected[item.key]!.matches(item),
          )
          .map((item) => item.key)
          .toList()
        ..sort();
  return AndroidReminderReconciliation(
    cancel: cancel,
    upsert: selected.values.where(
      (item) => previous[item.key]?.matches(item) != true,
    ),
    desired: selected.values,
    deferredCount: ordered.length - selected.length,
  );
}
