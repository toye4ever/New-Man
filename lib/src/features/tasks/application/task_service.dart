import 'package:uuid/uuid.dart';

import '../domain/task.dart';
import 'task_repository.dart';

class TaskService {
  TaskService(this.repository, {Uuid? uuid, DateTime Function()? clock})
    : _uuid = uuid ?? const Uuid(),
      _clock = clock ?? DateTime.now;

  final TaskRepository repository;
  final Uuid _uuid;
  final DateTime Function() _clock;

  Future<List<Task>> loadTasks() => repository.loadTasks();
  Future<List<Task>> loadOpenTasksDueBy(DateTime date) =>
      repository.loadOpenTasksDueBy(date);
  Future<List<DailyPriority>> loadDailyPriorities(DateTime date) =>
      repository.loadDailyPriorities(date);

  Future<Task> createTask({required String title, DateTime? dueDate}) async {
    final now = _clock().toUtc();
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      dueDate: dueDate == null
          ? null
          : DateTime(dueDate.year, dueDate.month, dueDate.day),
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
    await repository.saveTask(task);
    return task;
  }

  Future<void> updateTask({
    required Task task,
    required String title,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    final updatedAt = _clock().toUtc();
    return repository.saveTask(
      task.copyWith(
        title: title.trim(),
        dueDate: dueDate == null
            ? null
            : DateTime(dueDate.year, dueDate.month, dueDate.day),
        clearDueDate: clearDueDate,
        updatedAt: updatedAt,
      ),
    );
  }

  Future<void> setCompleted(Task task, bool completed) {
    final now = _clock().toUtc();
    return repository.saveTask(
      task.copyWith(
        isCompleted: completed,
        completedAt: completed ? now : null,
        clearCompletedAt: !completed,
        updatedAt: now,
      ),
    );
  }

  Future<void> deleteTask(String id) => repository.deleteTask(id);
  Future<void> selectDailyPriority(DateTime date, String taskId) =>
      repository.selectDailyPriority(date, taskId);
  Future<void> unselectDailyPriority(DateTime date, String taskId) =>
      repository.unselectDailyPriority(date, taskId);
  Future<void> reorderDailyPriorities(DateTime date, List<String> taskIds) =>
      repository.reorderDailyPriorities(date, taskIds);
}
