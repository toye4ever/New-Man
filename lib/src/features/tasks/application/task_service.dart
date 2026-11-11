import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../domain/task.dart';
import 'task_repository.dart';

class TaskService extends ChangeNotifier {
  TaskService(this.repository, {Uuid? uuid, DateTime Function()? clock})
    : _uuid = uuid ?? const Uuid(),
      _clock = clock ?? DateTime.now;

  final TaskRepository repository;
  final Uuid _uuid;
  final DateTime Function() _clock;
  Future<void> _writes = Future.value();
  int _pending = 0;

  Future<T> _write<T>(Future<T> Function() operation) {
    Future<T> run() async {
      try {
        final value = await operation();
        notifyListeners();
        return value;
      } finally {
        _pending--;
      }
    }

    final queued = _pending++ > 0;
    final result = queued ? _writes.then((_) => run()) : run();
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _writes = tail;
    return result;
  }

  Future<Task> _current(String id) async =>
      await repository.loadTask(id) ??
      (throw StateError('Task no longer exists.'));

  Future<List<Task>> loadTasks() => repository.loadTasks();
  Future<List<Task>> loadOpenTasksDueBy(DateTime date) =>
      repository.loadOpenTasksDueBy(date);
  Future<List<DailyPriority>> loadDailyPriorities(DateTime date) =>
      repository.loadDailyPriorities(date);

  Future<Task> createTask({
    required String title,
    DateTime? dueDate,
    TaskTimeBlock? timeBlock,
  }) => _write(() async {
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
      timeBlock: timeBlock,
    );
    await repository.saveTask(task);
    return task;
  });

  Future<void> saveEdit({
    required Task original,
    required String title,
    DateTime? dueDate,
    TaskTimeBlock? timeBlock,
  }) => _write(() async {
    final task = await _current(original.id);
    final titleChanged = title.trim() != original.title;
    final dueChanged = dueDate != original.dueDate;
    final before = original.timeBlock;
    final blockChanged =
        before?.plannedDate != timeBlock?.plannedDate ||
        before?.startMinutesLocal != timeBlock?.startMinutesLocal ||
        before?.endMinutesLocal != timeBlock?.endMinutesLocal;
    await repository.saveTask(
      task.copyWith(
        title: titleChanged ? title.trim() : null,
        dueDate: dueChanged ? dueDate : null,
        clearDueDate: dueChanged && dueDate == null,
        timeBlock: blockChanged ? timeBlock : null,
        clearTimeBlock: blockChanged && timeBlock == null,
        updatedAt: _clock().toUtc(),
      ),
    );
  });

  Future<void> updateTask({
    required Task task,
    required String title,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) => _write(() async {
    final updatedAt = _clock().toUtc();
    final current = await _current(task.id);
    await repository.saveTask(
      current.copyWith(
        title: title.trim(),
        dueDate: dueDate == null
            ? null
            : DateTime(dueDate.year, dueDate.month, dueDate.day),
        clearDueDate: clearDueDate,
        updatedAt: updatedAt,
      ),
    );
  });

  Future<void> setCompleted(Task task, bool completed) => _write(() async {
    final now = _clock().toUtc();
    final current = await _current(task.id);
    await repository.saveTask(
      current.copyWith(
        isCompleted: completed,
        completedAt: completed ? now : null,
        clearCompletedAt: !completed,
        updatedAt: now,
      ),
    );
  });

  Future<void> setTimeBlock(Task task, TaskTimeBlock block) => _write(
    () async => repository.saveTask(
      (await _current(
        task.id,
      )).copyWith(timeBlock: block, updatedAt: _clock().toUtc()),
    ),
  );

  Future<void> clearTimeBlock(Task task) => _write(
    () async => repository.saveTask(
      (await _current(
        task.id,
      )).copyWith(clearTimeBlock: true, updatedAt: _clock().toUtc()),
    ),
  );

  Future<void> deleteTask(String id) => _write(() => repository.deleteTask(id));
  Future<void> selectDailyPriority(DateTime date, String taskId) =>
      _write(() => repository.selectDailyPriority(date, taskId));
  Future<void> unselectDailyPriority(DateTime date, String taskId) =>
      _write(() => repository.unselectDailyPriority(date, taskId));
  Future<void> reorderDailyPriorities(DateTime date, List<String> taskIds) =>
      _write(() => repository.reorderDailyPriorities(date, taskIds));
}
