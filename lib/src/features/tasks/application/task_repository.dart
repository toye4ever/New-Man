import '../domain/task_recurrence.dart';
import '../domain/task.dart';

abstract interface class TaskRepository {
  Future<List<Task>> loadTasks();
  Future<List<Task>> loadOpenTasksDueBy(DateTime date);
  Future<Task?> loadTask(String id);
  Future<void> saveTask(Task task);
  Future<void> deleteTask(String id);
  Future<List<DailyPriority>> loadDailyPriorities(DateTime date);
  Future<void> selectDailyPriority(DateTime date, String taskId);
  Future<void> unselectDailyPriority(DateTime date, String taskId);
  Future<void> reorderDailyPriorities(DateTime date, List<String> taskIds);
}

/// Optional capability for atomic, explicit repeats of completed tasks.
abstract interface class RepeatingTaskRepository {
  Future<Task> repeatCompletedTask({
    required Task source,
    required TaskRecurrence rule,
    required DateTime today,
    required DateTime now,
  });
}

abstract interface class AutomaticRepeatingTaskRepository {
  Future<void> setCompletedWithRecurrence(
    String taskId,
    bool completed,
    DateTime now,
    DateTime today,
  );
}

abstract interface class TaskReminderRepository {
  Future<void> dismissReminder(
    String taskId,
    String expectedKey,
    DateTime expectedUpdatedAt,
    DateTime now,
  );
}
