import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/task.dart';

class TaskDao {
  const TaskDao(this.database);

  final AppDatabase database;

  Future<List<StoredTaskRecord>> loadTasks() =>
      (database.select(database.tasks)..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.desc(t.updatedAtUtcMicros),
          ]))
          .get();

  Future<List<StoredTaskRecord>> loadOpenTasksDueBy(DateTime date) =>
      (database.select(database.tasks)
            ..where(
              (task) =>
                  task.isCompleted.equals(false) &
                  task.dueDate.isSmallerOrEqualValue(localDateStorage(date)),
            )
            ..orderBy([
              (task) => OrderingTerm.asc(task.dueDate),
              (task) => OrderingTerm.asc(task.createdAtUtcMicros),
            ]))
          .get();

  Future<StoredTaskRecord?> loadTask(String id) => (database.select(
    database.tasks,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> saveTask(Task task) async {
    final existing = await loadTask(task.id);
    await database
        .into(database.tasks)
        .insertOnConflictUpdate(
          TasksCompanion.insert(
            id: task.id,
            title: task.title.trim(),
            dueDate: Value(
              task.dueDate == null ? null : localDateStorage(task.dueDate!),
            ),
            plannedDate: Value(
              task.timeBlock == null
                  ? null
                  : localDateStorage(task.timeBlock!.plannedDate),
            ),
            startMinutesLocal: Value(task.timeBlock?.startMinutesLocal),
            endMinutesLocal: Value(task.timeBlock?.endMinutesLocal),
            isCompleted: task.isCompleted,
            completedAtUtcMicros: Value(
              task.completedAt?.toUtc().microsecondsSinceEpoch,
            ),
            createdAtUtcMicros:
                existing?.createdAtUtcMicros ??
                task.createdAt.toUtc().microsecondsSinceEpoch,
            updatedAtUtcMicros: task.updatedAt.toUtc().microsecondsSinceEpoch,
          ),
        );
  }

  Future<void> deleteTask(String id) =>
      (database.delete(database.tasks)..where((t) => t.id.equals(id))).go();

  Future<List<DailyPriorityTaskRecord>> loadDailyPriorities(DateTime date) =>
      (database.select(database.dailyPriorityTasks)
            ..where((t) => t.priorityDate.equals(localDateStorage(date)))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

  Future<void> selectDailyPriority(DateTime date, String taskId) async {
    final day = localDateStorage(date);
    final existing =
        await (database.select(database.dailyPriorityTasks)..where(
              (t) => t.priorityDate.equals(day) & t.taskId.equals(taskId),
            ))
            .getSingleOrNull();
    if (existing != null) return;
    final positions = await loadDailyPriorities(date);
    final position = positions.isEmpty
        ? -1
        : positions
              .map((item) => item.position)
              .reduce((a, b) => a > b ? a : b);
    await database
        .into(database.dailyPriorityTasks)
        .insert(
          DailyPriorityTasksCompanion.insert(
            priorityDate: day,
            taskId: taskId,
            position: position + 1,
          ),
        );
  }

  Future<void> unselectDailyPriority(DateTime date, String taskId) =>
      (database.delete(database.dailyPriorityTasks)..where(
            (t) =>
                t.priorityDate.equals(localDateStorage(date)) &
                t.taskId.equals(taskId),
          ))
          .go();

  Future<void> reorderDailyPriorities(
    DateTime date,
    List<String> taskIds,
  ) async {
    if (taskIds.toSet().length != taskIds.length) {
      throw ArgumentError('A Task can appear only once in daily priorities.');
    }
    final day = localDateStorage(date);
    await database.transaction(() async {
      final existing = await loadDailyPriorities(date);
      final existingTaskIds = existing.map((item) => item.taskId).toSet();
      if (existingTaskIds.length != taskIds.length ||
          !existingTaskIds.containsAll(taskIds)) {
        throw ArgumentError(
          'Reordering must preserve the selected Tasks for that date.',
        );
      }
      await (database.delete(
        database.dailyPriorityTasks,
      )..where((t) => t.priorityDate.equals(day))).go();
      for (var position = 0; position < taskIds.length; position++) {
        await database
            .into(database.dailyPriorityTasks)
            .insert(
              DailyPriorityTasksCompanion.insert(
                priorityDate: day,
                taskId: taskIds[position],
                position: position,
              ),
            );
      }
    });
  }
}
