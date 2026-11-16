import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/tasks/application/task_service.dart';
import 'package:scripture_planner/src/features/tasks/data/drift_task_repository.dart';
import 'package:scripture_planner/src/features/tasks/data/local/task_dao.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';
import 'package:scripture_planner/src/features/tasks/domain/task_recurrence.dart';
import 'package:scripture_planner/src/features/tasks/presentation/task_editor_dialog.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository repo;
  late TaskService service;
  var today = DateTime(2026, 11, 17, 12);
  setUp(() {
    today = DateTime(2026, 11, 17, 12);
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftTaskRepository(TaskDao(db));
    service = TaskService(repo, clock: () => today);
  });
  tearDown(() async {
    service.dispose();
    await db.close();
  });
  Future<Task> make({TaskRecurrence? rule = const TaskRecurrence.daily()}) =>
      service.createTask(
        title: 'Study',
        recurrence: rule,
        dueDate: DateTime(2026, 11, 1),
        subtasks: [service.newSubtask(title: 'Notes', isCompleted: true)],
      );
  Future<Task> successor(Task source) async =>
      (await repo.loadTasks()).singleWhere((t) => t.id != source.id);

  test(
    'daily completion is atomic and idempotent, preserving source history',
    () async {
      final source = await make();
      final otherService = TaskService(repo, clock: () => today);
      addTearDown(otherService.dispose);
      await Future.wait([
        service.setCompleted(source, true),
        otherService.setCompleted(source, true),
      ]);
      final next = await successor(source);
      expect(next.dueDate, DateTime(2026, 11, 18));
      expect(next.recurrence!.isDaily, isTrue);
      expect(next.subtasks.single.isCompleted, isFalse);
      final original = (await repo.loadTask(source.id))!;
      expect(original.isCompleted, isTrue);
      expect(original.repeatHandled, isTrue);
      expect(original.subtasks.single.isCompleted, isTrue);
      today = DateTime(2026, 11, 19);
      await service.setCompleted(source, true);
      expect(
        (await repo.loadTask(source.id))!.completedAt,
        original.completedAt,
      );
      expect(await repo.loadTasks(), hasLength(2));
      await service.setCompleted(source, false);
      await service.setCompleted(source, true);
      expect(await repo.loadTasks(), hasLength(2));
      await service.deleteTask(next.id);
      await service.setCompleted(source, false);
      await service.setCompleted(source, true);
      expect(await repo.loadTasks(), hasLength(1));
    },
  );

  test(
    'selected weekdays persist; editing and Off affect the next open occurrence',
    () async {
      final source = await make(rule: TaskRecurrence.weekly([DateTime.friday]));
      await service.setCompleted(source, true);
      final next = await successor(source);
      expect(next.dueDate, DateTime(2026, 11, 20));
      expect(next.recurrence!.weekdays, [DateTime.friday]);
      await service.saveEdit(
        original: next,
        title: 'Changed next',
        dueDate: next.dueDate,
        recurrence: TaskRecurrence.weekly([DateTime.monday]),
        editRecurrence: true,
      );
      final edited = (await repo.loadTask(next.id))!;
      await service.setCompleted(edited, true);
      final third = (await repo.loadTasks()).singleWhere((t) => !t.isCompleted);
      expect(third.title, 'Changed next');
      expect(third.dueDate, DateTime(2026, 11, 23));
      expect(third.recurrence!.weekdays, [DateTime.monday]);
      await service.saveEdit(
        original: third,
        title: third.title,
        dueDate: third.dueDate,
        editRecurrence: true,
      );
      final off = (await repo.loadTask(third.id))!;
      expect(off.recurrence, isNull);
      await service.setCompleted(off, true);
      expect(await repo.loadTasks(), hasLength(3));
    },
  );

  test(
    'failed successor children and failed parent commit both roll back',
    () async {
      final source = await make();
      for (final failure in ['child', 'parent']) {
        await db.customStatement(
          failure == 'child'
              ? "CREATE TRIGGER fail_auto BEFORE INSERT ON task_subtasks BEGIN SELECT RAISE(ABORT, 'synthetic child failure'); END"
              : "CREATE TRIGGER fail_auto BEFORE UPDATE ON tasks WHEN NEW.is_completed = 1 BEGIN SELECT RAISE(ABORT, 'synthetic parent failure'); END",
        );
        await expectLater(
          service.setCompleted(source, true),
          throwsA(anything),
        );
        final retained = (await repo.loadTask(source.id))!;
        expect(retained.isCompleted, isFalse);
        expect(retained.repeatHandled, isFalse);
        expect(retained.subtasks.single.isCompleted, isTrue);
        expect(await repo.loadTasks(), hasLength(1));
        await db.customStatement('DROP TRIGGER fail_auto');
      }
      await service.setCompleted(source, true);
      expect(await repo.loadTasks(), hasLength(2));
    },
  );

  test(
    'manual and automatic repeats share the successor and preserve its edits',
    () async {
      final source = await make();
      await service.setCompleted(source, true);
      final next = await successor(source);
      await service.updateTask(
        task: next,
        title: 'Edited successor',
        clearDueDate: true,
      );
      final manual = await service.repeatCompletedTask(
        (await repo.loadTask(source.id))!,
        TaskRecurrence.weekly([DateTime.sunday]),
      );
      expect(manual.id, next.id);
      expect(manual.title, 'Edited successor');
      expect(manual.dueDate, isNull);
      expect(manual.recurrence!.isDaily, isTrue);
      expect(await repo.loadTasks(), hasLength(2));
    },
  );

  test(
    'a manually scheduled successor is never overwritten by later opt-in',
    () async {
      final source = await make(rule: null);
      await service.setCompleted(source, true);
      final manual = await service.repeatCompletedTask(
        (await repo.loadTask(source.id))!,
        const TaskRecurrence.daily(),
      );
      await service.setCompleted(source, false);
      final reopened = (await repo.loadTask(source.id))!;
      await service.saveEdit(
        original: reopened,
        title: reopened.title,
        recurrence: TaskRecurrence.weekly([DateTime.friday]),
        editRecurrence: true,
      );
      await service.setCompleted(source, true);
      final retained = (await repo.loadTask(manual.id))!;
      expect(retained.recurrence, isNull);
      expect(retained.dueDate, manual.dueDate);
      expect((await repo.loadTask(source.id))!.repeatHandled, isTrue);
      expect(await repo.loadTasks(), hasLength(2));
    },
  );

  test(
    'Off default never creates a successor; stale rule edits cannot overwrite changes',
    () async {
      final plain = await make(rule: null);
      await service.setCompleted(plain, true);
      expect(await repo.loadTasks(), hasLength(1));
      final source = await make();
      await service.saveEdit(
        original: source,
        title: source.title,
        recurrence: TaskRecurrence.weekly([DateTime.monday]),
        editRecurrence: true,
      );
      await expectLater(
        service.saveEdit(
          original: source,
          title: 'Stale',
          recurrence: null,
          editRecurrence: true,
        ),
        throwsStateError,
      );
      expect((await repo.loadTask(source.id))!.recurrence!.weekdays, [
        DateTime.monday,
      ]);
    },
  );

  test(
    'date rules advance calendar labels across DST and skip overdue backlog',
    () async {
      for (final day in [DateTime(2026, 3, 8, 23), DateTime(2026, 11, 1, 23)]) {
        today = day;
        final source = await service.createTask(
          title: 'DST',
          recurrence: const TaskRecurrence.daily(),
          dueDate: DateTime(day.year, day.month, day.day - 1),
        );
        await service.setCompleted(source, true);
        final next = (await repo.loadTasks()).singleWhere(
          (t) => !t.isCompleted,
        );
        expect(next.dueDate, DateTime(day.year, day.month, day.day + 1));
        await service.deleteTask(next.id);
      }
    },
  );

  test('rule and handled marker survive SQLite close and reopen', () async {
    final directory = await Directory.systemTemp.createTemp('newman-auto-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/tasks.sqlite');
    service.dispose();
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    repo = DriftTaskRepository(TaskDao(db));
    service = TaskService(repo, clock: () => today);
    final source = await service.createTask(
      title: 'Persistent',
      recurrence: TaskRecurrence.weekly([DateTime.wednesday]),
    );
    await service.setCompleted(source, true);
    service.dispose();
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    repo = DriftTaskRepository(TaskDao(db));
    service = TaskService(repo, clock: () => today);
    final original = (await repo.loadTask(source.id))!;
    expect(original.repeatHandled, isTrue);
    await service.setCompleted(original, true);
    final next = (await repo.loadTasks()).singleWhere((t) => !t.isCompleted);
    expect(next.recurrence!.weekdays, [DateTime.wednesday]);
    await service.setCompleted(next, true);
    expect(await repo.loadTasks(), hasLength(3));
  });

  testWidgets('repeat controls save at narrow width and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = await make(rule: TaskRecurrence.weekly([DateTime.friday]));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTaskEditor(context, service, task: source),
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    final weekdays = find.text('Selected weekdays');
    await tester.ensureVisible(weekdays);
    await tester.tap(weekdays);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save task'));
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    expect((await repo.loadTask(source.id))!.recurrence!.isDaily, isTrue);
    expect((await repo.loadTask(source.id))!.subtasks, source.subtasks);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor saves weekday opt-in and explicitly turns it Off', (
    tester,
  ) async {
    Task? current;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTaskEditor(context, service, task: current),
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    Future<void> tap(String text) async {
      final target = find.text(text).last;
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await tap('Edit');
    await tester.enterText(
      find.widgetWithText(TextField, 'Task title'),
      'From editor',
    );
    await tap('Off');
    await tap('Selected weekdays');
    await tap('Save task');
    expect(find.text('Choose at least one repeat weekday.'), findsOneWidget);
    expect(await repo.loadTasks(), isEmpty);
    await tap('Fri');
    await tap('Save task');
    current = (await repo.loadTasks()).single;
    expect(current.recurrence!.weekdays, [DateTime.friday]);
    await tap('Edit');
    await tap('Selected weekdays');
    await tap('Off');
    await tap('Save task');
    current = (await repo.loadTasks()).single;
    expect(current.recurrence, isNull);
    await service.setCompleted(current, true);
    expect(await repo.loadTasks(), hasLength(1));
  });
}
