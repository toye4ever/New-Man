import '../application/task_repository.dart';
import '../domain/task.dart';
import 'local/task_dao.dart';

class DriftTaskRepository implements TaskRepository {
  const DriftTaskRepository(this.dao);
  final TaskDao dao;

  Task _task(StoredTaskWithSubtasks stored) {
    final record = stored.task;
    return Task(
      id: record.id,
      subtasks: [
        for (final item in stored.subtasks)
          TaskSubtask(
            id: item.id,
            title: item.title,
            isCompleted: item.isCompleted,
          ),
      ],
      title: record.title,
      dueDate: record.dueDate == null
          ? null
          : localDateFromStorage(record.dueDate!),
      timeBlock: record.plannedDate == null
          ? null
          : TaskTimeBlock(
              plannedDate: localDateFromStorage(record.plannedDate!),
              startMinutesLocal: record.startMinutesLocal!,
              endMinutesLocal: record.endMinutesLocal!,
            ),
      isCompleted: record.isCompleted,
      completedAt: record.completedAtUtcMicros == null
          ? null
          : DateTime.fromMicrosecondsSinceEpoch(
              record.completedAtUtcMicros!,
              isUtc: true,
            ),
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        record.createdAtUtcMicros,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMicrosecondsSinceEpoch(
        record.updatedAtUtcMicros,
        isUtc: true,
      ),
    );
  }

  @override
  Future<List<Task>> loadTasks() async =>
      (await dao.loadTasks()).map(_task).toList();
  @override
  Future<List<Task>> loadOpenTasksDueBy(DateTime date) async =>
      (await dao.loadOpenTasksDueBy(date)).map(_task).toList();
  @override
  Future<Task?> loadTask(String id) async {
    final record = await dao.loadTask(id);
    return record == null ? null : _task(record);
  }

  @override
  Future<void> saveTask(Task task) => dao.saveTask(task);
  @override
  Future<void> deleteTask(String id) => dao.deleteTask(id);
  @override
  Future<List<DailyPriority>> loadDailyPriorities(DateTime date) async =>
      (await dao.loadDailyPriorities(date))
          .map(
            (record) => DailyPriority(
              date: localDateFromStorage(record.priorityDate),
              taskId: record.taskId,
              position: record.position,
            ),
          )
          .toList();
  @override
  Future<void> selectDailyPriority(DateTime date, String taskId) =>
      dao.selectDailyPriority(date, taskId);
  @override
  Future<void> unselectDailyPriority(DateTime date, String taskId) =>
      dao.unselectDailyPriority(date, taskId);
  @override
  Future<void> reorderDailyPriorities(DateTime date, List<String> taskIds) =>
      dao.reorderDailyPriorities(date, taskIds);
}
