import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/tasks/application/task_service.dart';
import 'package:scripture_planner/src/features/tasks/data/drift_task_repository.dart';
import 'package:scripture_planner/src/features/tasks/data/local/task_dao.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';

void main() {
  test('checklists copy their input and reject duplicate identifiers', () {
    final item = TaskSubtask(id: 'one', title: 'First');
    final items = [item];
    final now = DateTime.utc(2026, 11, 17);
    Task make(List<TaskSubtask> values) => Task(
      id: 'parent',
      title: 'Parent',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      subtasks: values,
    );
    final task = make(items);
    items.clear();
    expect(task.subtasks, [item]);
    expect(() => task.subtasks.clear(), throwsUnsupportedError);
    expect(() => make([item, item]), throwsArgumentError);
  });

  test(
    'ordered checklist survives SQLite reopen and parent completion',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'newman-subtasks-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/tasks.sqlite');
      final day = DateTime(2026, 11, 17);
      final saved = await () async {
        final db = AppDatabase(NativeDatabase(file));
        final service = TaskService(DriftTaskRepository(TaskDao(db)));
        try {
          final first = service.newSubtask(title: 'First');
          final second = service.newSubtask(title: 'Second', isCompleted: true);
          final task = await service.createTask(
            title: 'Task',
            dueDate: day,
            subtasks: [first, second],
          );
          await service.createTask(title: 'Unrelated', dueDate: day);
          await service.setCompleted(task, true);
          return task;
        } finally {
          service.dispose();
          await db.close();
        }
      }();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final repo = DriftTaskRepository(TaskDao(db));
      final service = TaskService(repo);
      addTearDown(service.dispose);
      final reloaded = (await repo.loadTask(saved.id))!;
      expect(reloaded.isCompleted, isTrue);
      expect(reloaded.completedSubtaskCount, 1);
      expect(reloaded.subtasks, saved.subtasks);
      expect((await repo.loadOpenTasksDueBy(day)).single.title, 'Unrelated');
      await service.setCompleted(reloaded, false);
      final due = await repo.loadOpenTasksDueBy(day);
      expect(
        due.firstWhere((task) => task.id == saved.id).subtasks,
        saved.subtasks,
      );
      expect(due.firstWhere((task) => task.id != saved.id).subtasks, isEmpty);
      await service.deleteTask(saved.id);
      expect(await db.select(db.taskSubtasks).get(), isEmpty);
      expect((await repo.loadTasks()).single.title, 'Unrelated');
    },
  );

  test(
    'failed checklist write rolls back parent and existing children',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftTaskRepository(TaskDao(db));
      final service = TaskService(repo);
      addTearDown(service.dispose);
      final first = service.newSubtask(title: 'Original');
      final task = await service.createTask(title: 'Parent', subtasks: [first]);
      await db.customStatement("""
      CREATE TRIGGER reject_subtask_insert BEFORE INSERT ON task_subtasks
      WHEN NEW.title = 'Rejected'
      BEGIN SELECT RAISE(ABORT, 'synthetic subtask failure'); END
    """);
      await expectLater(
        service.saveEdit(
          original: task,
          title: 'New title',
          subtasks: [service.newSubtask(title: 'Rejected')],
        ),
        throwsA(anything),
      );
      final retained = (await repo.loadTask(task.id))!;
      expect(retained.title, 'Parent');
      expect(retained.subtasks, [first]);
      await service.saveEdit(original: task, title: 'Parent', subtasks: []);
      expect((await repo.loadTask(task.id))!.subtasks, isEmpty);
    },
  );

  test('stale editors preserve other checklist changes', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftTaskRepository(TaskDao(db));
    final service = TaskService(repo);
    addTearDown(service.dispose);
    final first = service.newSubtask(title: 'Original');
    final task = await service.createTask(title: 'Parent', subtasks: [first]);
    final changed = TaskSubtask(
      id: first.id,
      title: 'Changed',
      isCompleted: true,
    );
    await service.saveEdit(
      original: task,
      title: task.title,
      subtasks: [changed],
    );
    await service.saveEdit(
      original: task,
      title: 'Parent edited',
      subtasks: [first],
    );
    await expectLater(
      service.saveEdit(original: task, title: 'Clobber', subtasks: []),
      throwsA(isA<TaskSubtaskEditConflict>()),
    );
    final retained = (await repo.loadTask(task.id))!;
    expect(retained.title, 'Parent edited');
    expect(retained.subtasks, [changed]);
  });
}
