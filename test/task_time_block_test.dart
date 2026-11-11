import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/tasks/application/task_service.dart';
import 'package:scripture_planner/src/features/tasks/data/drift_task_repository.dart';
import 'package:scripture_planner/src/features/tasks/data/local/task_dao.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';

void main() {
  test(
    'boundaries and persistence through edit, completion and clear',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repository = DriftTaskRepository(TaskDao(db));
      final service = TaskService(repository);
      final task = await service.createTask(
        title: 'Plan',
        dueDate: DateTime(2026, 5, 3),
      );
      expect(
        () => TaskTimeBlock(
          plannedDate: DateTime(2026),
          startMinutesLocal: 5,
          endMinutesLocal: 5,
        ),
        throwsArgumentError,
      );
      expect(
        () => TaskTimeBlock(
          plannedDate: DateTime(2026),
          startMinutesLocal: -1,
          endMinutesLocal: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => TaskTimeBlock(
          plannedDate: DateTime(2026),
          startMinutesLocal: 0,
          endMinutesLocal: 1441,
        ),
        throwsArgumentError,
      );
      await service.setTimeBlock(
        task,
        TaskTimeBlock(
          plannedDate: DateTime(2026, 5, 4),
          startMinutesLocal: 0,
          endMinutesLocal: 1440,
        ),
      );
      var saved = (await repository.loadTask(task.id))!;
      expect(saved.timeBlock!.plannedDate, DateTime(2026, 5, 4));
      expect(saved.dueDate, DateTime(2026, 5, 3));
      await service.updateTask(task: saved, title: 'Edited');
      saved = (await repository.loadTask(task.id))!;
      await service.setCompleted(saved, true);
      saved = (await repository.loadTask(task.id))!;
      expect(saved.timeBlock!.endMinutesLocal, 1440);
      await service.setTimeBlock(
        saved,
        TaskTimeBlock(
          plannedDate: DateTime(2026, 5, 5),
          startMinutesLocal: 30,
          endMinutesLocal: 60,
        ),
      );
      saved = (await repository.loadTask(task.id))!;
      expect(saved.timeBlock!.plannedDate, DateTime(2026, 5, 5));
      await service.setCompleted(saved, false);
      saved = (await repository.loadTask(task.id))!;
      expect(saved.timeBlock!.startMinutesLocal, 30);
      await service.clearTimeBlock(saved);
      expect((await repository.loadTask(task.id))!.timeBlock, isNull);
      await db.close();
    },
  );

  test('failed save preserves the existing task and block', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = DriftTaskRepository(TaskDao(db));
    final service = TaskService(repo);
    final task = await service.createTask(title: 'Original');
    await service.setTimeBlock(
      task,
      TaskTimeBlock(
        plannedDate: DateTime(2026, 1, 2),
        startMinutesLocal: 60,
        endMinutesLocal: 120,
      ),
    );
    final saved = (await repo.loadTask(task.id))!;
    await db.customStatement(
      "CREATE TRIGGER reject_task_update BEFORE UPDATE ON tasks BEGIN SELECT RAISE(ABORT, 'synthetic failure'); END",
    );
    await expectLater(
      service.updateTask(task: saved, title: 'Changed'),
      throwsA(anything),
    );
    final retained = (await repo.loadTask(task.id))!;
    expect(retained.title, 'Original');
    expect(retained.timeBlock!.startMinutesLocal, 60);
    await db.customStatement('DROP TRIGGER reject_task_update');
    await service.updateTask(task: retained, title: 'Changed');
    expect((await repo.loadTask(task.id))!.timeBlock!.endMinutesLocal, 120);
    await db.close();
  });

  test('blocks survive a real SQLite close and reopen', () async {
    final directory = await Directory.systemTemp.createTemp('newman-block-');
    final file = File('${directory.path}/tasks.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var repo = DriftTaskRepository(TaskDao(db));
    final service = TaskService(repo);
    final task = await service.createTask(title: 'Durable');
    await service.setTimeBlock(
      task,
      TaskTimeBlock(
        plannedDate: DateTime(2026, 6, 1),
        startMinutesLocal: 60,
        endMinutesLocal: 90,
      ),
    );
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    repo = DriftTaskRepository(TaskDao(db));
    expect((await repo.loadTask(task.id))!.timeBlock!.startMinutesLocal, 60);
    await db.close();
    await directory.delete(recursive: true);
  });

  test('database rejects partial and invalid calendar blocks', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customStatement(
      "INSERT INTO tasks (id,title,is_completed,created_at_utc_micros,updated_at_utc_micros) VALUES ('x','x',0,1,1)",
    );
    for (final values in [
      "'2026-02-30', 1, 2",
      "'2026-01-01', NULL, 2",
      "'2026-01-01', 2, 2",
      "'2026-01-01', 3, 2",
      "NULL, 1, 2",
      "'2026-01-01', -1, 2",
      "'2026-01-01', 0, 1441",
    ]) {
      final parts = values.split(', ');
      await expectLater(
        db.customStatement(
          'UPDATE tasks SET planned_date = ${parts[0]}, start_minutes_local = ${parts[1]}, end_minutes_local = ${parts[2]}',
        ),
        throwsA(anything),
      );
    }
    await db.close();
  });
}
