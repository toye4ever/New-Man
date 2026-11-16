import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/task.dart';

typedef StoredTaskWithSubtasks = ({
  StoredTaskRecord task,
  List<StoredTaskSubtaskRecord> subtasks,
});

class TaskDao {
  const TaskDao(this.database);

  final AppDatabase database;

  Future<List<StoredTaskWithSubtasks>> _loadWithSubtasks({
    Expression<bool> Function(Tasks)? where,
    List<OrderingTerm Function(Tasks)> orderBy = const [],
  }) async {
    final tasks = database.tasks;
    final subtasks = database.taskSubtasks;
    final query = database.select(tasks).join([
      leftOuterJoin(subtasks, subtasks.taskId.equalsExp(tasks.id)),
    ]);
    if (where != null) query.where(where(tasks));
    query.orderBy([
      for (final order in orderBy) order(tasks),
      OrderingTerm.asc(subtasks.position),
    ]);
    final grouped = <String, StoredTaskWithSubtasks>{};
    for (final row in await query.get()) {
      final task = row.readTable(tasks);
      final result = grouped.putIfAbsent(
        task.id,
        () => (task: task, subtasks: <StoredTaskSubtaskRecord>[]),
      );
      final subtask = row.readTableOrNull(subtasks);
      if (subtask != null) result.subtasks.add(subtask);
    }
    return grouped.values.toList();
  }

  Future<List<StoredTaskWithSubtasks>> loadTasks() => _loadWithSubtasks(
    orderBy: [
      (t) => OrderingTerm.asc(t.isCompleted),
      (t) => OrderingTerm.desc(t.updatedAtUtcMicros),
      (t) => OrderingTerm.asc(t.id),
    ],
  );

  Future<List<StoredTaskWithSubtasks>> loadOpenTasksDueBy(DateTime date) =>
      _loadWithSubtasks(
        where: (t) =>
            t.isCompleted.equals(false) &
            t.dueDate.isSmallerOrEqualValue(localDateStorage(date)),
        orderBy: [
          (t) => OrderingTerm.asc(t.dueDate),
          (t) => OrderingTerm.asc(t.createdAtUtcMicros),
          (t) => OrderingTerm.asc(t.id),
        ],
      );

  Future<StoredTaskWithSubtasks?> loadTask(String id) async =>
      (await _loadWithSubtasks(where: (t) => t.id.equals(id))).singleOrNull;

  Future<void> saveTask(Task task) => database.transaction(() async {
    final existing = await (database.select(
      database.tasks,
    )..where((t) => t.id.equals(task.id))).getSingleOrNull();
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
    final subtasks = database.taskSubtasks;
    final stored =
        await (database.select(subtasks)
              ..where((t) => t.taskId.equals(task.id))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    final identical =
        stored.length == task.subtasks.length &&
        stored.indexed.every((entry) {
          final item = task.subtasks[entry.$1];
          final record = entry.$2;
          return record.id == item.id &&
              record.title == item.title &&
              record.isCompleted == item.isCompleted;
        });
    if (!identical) {
      await (database.delete(
        subtasks,
      )..where((t) => t.taskId.equals(task.id))).go();
      await database.batch((batch) {
        batch.insertAll(subtasks, [
          for (final (position, item) in task.subtasks.indexed)
            TaskSubtasksCompanion.insert(
              taskId: task.id,
              id: item.id,
              title: item.title,
              isCompleted: item.isCompleted,
              position: position,
            ),
        ]);
      });
    }
  });

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
