import '../domain/task_reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../domain/task_recurrence.dart';
import '../application/task_repository.dart';
import '../domain/task.dart';
import 'local/task_dao.dart';

class DriftTaskRepository
    implements
        TaskRepository,
        RepeatingTaskRepository,
        AutomaticRepeatingTaskRepository,
        TaskReminderRepository {
  const DriftTaskRepository(this.dao);
  final TaskDao dao;

  Task _task(StoredTaskWithSubtasks stored) {
    final record = stored.task;
    return Task(
      id: record.id,
      recurrence: record.recurrenceMask == null
          ? null
          : TaskRecurrence.fromWeekdayMask(record.recurrenceMask!),
      repeatHandled: record.repeatHandled,
      reminderMinutesLocal: record.reminderMinutesLocal,
      reminderDismissedKey: record.reminderDismissedKey,
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
  Future<void> setCompletedWithRecurrence(
    String taskId,
    bool completed,
    DateTime now,
    DateTime today,
  ) => dao.database.transaction(() async {
    final current = await loadTask(taskId);
    if (current == null) throw StateError('Task no longer exists.');
    if (current.isCompleted == completed) return;
    var updated = current.copyWith(
      isCompleted: completed,
      completedAt: completed ? now : null,
      clearCompletedAt: !completed,
      updatedAt: now,
    );
    final rule = current.recurrence;
    if (completed && rule != null && !current.repeatHandled) {
      await _ensureSuccessor(current, rule, today, now, inheritRule: true);
      updated = updated.copyWith(repeatHandled: true);
    }
    await dao.saveTask(updated);
  });

  Future<Task> _ensureSuccessor(
    Task current,
    TaskRecurrence rule,
    DateTime today,
    DateTime now, {
    required bool inheritRule,
  }) async {
    final id = const Uuid().v5(
      Namespace.url.value,
      'new-man/task-repeat/${current.id}',
    );
    final existing = await loadTask(id);
    if (existing != null) return existing;
    final next = Task(
      id: id,
      title: current.title,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      recurrence: inheritRule ? rule : null,
      reminderMinutesLocal: inheritRule ? current.reminderMinutesLocal : null,
      dueDate: nextTaskOccurrence(rule, current.dueDate, today),
      subtasks: [
        for (final item in current.subtasks)
          TaskSubtask(id: item.id, title: item.title),
      ],
    );
    await dao.saveTask(next);
    return next;
  }

  @override
  Future<Task> repeatCompletedTask({
    required Task source,
    required TaskRecurrence rule,
    required DateTime today,
    required DateTime now,
  }) => dao.database.transaction(() async {
    final current = await loadTask(source.id);
    if (current == null || !current.isCompleted) {
      throw StateError('Only an existing completed task can be repeated.');
    }
    // Stable across restarts and retries. An existing successor is returned
    // unchanged, even if the caller chooses another rule on a second attempt.
    final id = const Uuid().v5(
      Namespace.url.value,
      'new-man/task-repeat/${source.id}',
    );
    final existing = await loadTask(id);
    if (existing != null) return existing;
    if (current.updatedAt != source.updatedAt ||
        current.title != source.title ||
        current.dueDate != source.dueDate ||
        current.completedAt != source.completedAt ||
        !listEquals(current.subtasks, source.subtasks)) {
      throw StateError(
        'The task changed. Reopen it before scheduling a repeat.',
      );
    }
    return _ensureSuccessor(current, rule, today, now, inheritRule: false);
  });

  @override
  Future<void> dismissReminder(
    String taskId,
    String expectedKey,
    DateTime expectedUpdatedAt,
    DateTime now,
  ) => dao.database.transaction(() async {
    final current = await loadTask(taskId);
    if (current == null ||
        current.updatedAt != expectedUpdatedAt ||
        current.isCompleted ||
        taskReminderKey(current) != expectedKey ||
        current.reminderDismissedKey == expectedKey) {
      return;
    }
    await dao.saveTask(
      current.copyWith(reminderDismissedKey: expectedKey, updatedAt: now),
    );
  });

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
