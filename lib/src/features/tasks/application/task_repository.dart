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
