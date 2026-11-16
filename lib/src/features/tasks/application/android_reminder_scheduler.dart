import '../domain/android_reminder_delivery.dart';

/// Future native implementations must use full opaque keys (not truncated
/// integer hashes), make upsert idempotent, recheck consent/permission at every
/// upsert and delivery, and maintain a durable scheduled/delivered ledger.
abstract interface class AndroidTaskReminderPort {
  Future<void> cancel(String key);
  Future<void> upsert(PlannedAndroidTaskReminder reminder);
}

enum ReminderReconciliationStatus { applied, superseded }

/// Serializes native mutations. A newer request invalidates queued older work.
/// Plans are built only after previous mutations finish so the next builder can
/// read the latest durable native ledger. Cancellation failure prevents upserts.
class AndroidReminderSynchronizer {
  Future<void> _tail = Future.value();
  int _generation = 0;

  Future<ReminderReconciliationStatus> reconcile({
    required AndroidTaskReminderPort port,
    required Future<AndroidReminderReconciliation> Function() buildPlan,
  }) {
    final generation = ++_generation;
    final result = _tail.then((_) async {
      if (generation != _generation) {
        return ReminderReconciliationStatus.superseded;
      }
      final plan = await buildPlan();
      for (final key in plan.cancel) {
        if (generation != _generation) {
          return ReminderReconciliationStatus.superseded;
        }
        await port.cancel(key);
      }
      for (final reminder in plan.upsert) {
        if (generation != _generation) {
          return ReminderReconciliationStatus.superseded;
        }
        await port.upsert(reminder);
      }
      return generation == _generation
          ? ReminderReconciliationStatus.applied
          : ReminderReconciliationStatus.superseded;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
