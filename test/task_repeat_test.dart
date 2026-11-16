import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/tasks/application/task_service.dart';
import 'package:scripture_planner/src/features/tasks/data/drift_task_repository.dart';
import 'package:scripture_planner/src/features/tasks/data/local/task_dao.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';
import 'package:scripture_planner/src/features/tasks/domain/task_recurrence.dart';
import 'package:scripture_planner/src/features/tasks/presentation/task_repeat_dialog.dart';
import 'package:scripture_planner/src/features/tasks/presentation/tasks_screen.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository repo;
  late TaskService service;
  final today = DateTime(2026, 11, 17);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftTaskRepository(TaskDao(db));
    service = TaskService(repo, clock: () => today);
  });
  tearDown(() async {
    service.dispose();
    await db.close();
  });
  Future<Task> completed() async {
    final task = await service.createTask(
      title: 'Read',
      dueDate: DateTime(2026, 11, 1),
      timeBlock: TaskTimeBlock(
        plannedDate: today,
        startMinutesLocal: 60,
        endMinutesLocal: 90,
      ),
      subtasks: [service.newSubtask(title: 'Notes', isCompleted: true)],
    );
    await service.selectDailyPriority(today, task.id);
    await service.setCompleted(task, true);
    return (await repo.loadTask(task.id))!;
  }

  test(
    'repeat persists an independent task and retries preserve edits',
    () async {
      final original = await completed();
      final next = await service.repeatCompletedTask(
        original,
        const TaskRecurrence.daily(),
      );
      expect(next.dueDate, DateTime(2026, 11, 18));
      expect(next.isCompleted, isFalse);
      expect(next.subtasks.single.isCompleted, isFalse);
      expect(next.timeBlock, isNull);
      expect(
        (await repo.loadDailyPriorities(today)).single.taskId,
        original.id,
      );
      expect(
        (await repo.loadTask(original.id))!.subtasks.single.isCompleted,
        isTrue,
      );
      await service.updateTask(
        task: next,
        title: 'Edited next',
        clearDueDate: true,
      );
      final restarted = TaskService(repo, clock: () => today);
      addTearDown(restarted.dispose);
      final retry = await restarted.repeatCompletedTask(
        original,
        TaskRecurrence.weekly([DateTime.friday]),
      );
      expect(retry.id, next.id);
      expect(retry.title, 'Edited next');
      expect(retry.dueDate, isNull);
      expect(await repo.loadTasks(), hasLength(2));
      await service.deleteTask(original.id);
      expect((await repo.loadTask(next.id))!.title, 'Edited next');
    },
  );

  test(
    'child insert failure leaves no partial successor and permits retry',
    () async {
      final original = await completed();
      await db.customStatement(
        "CREATE TRIGGER reject_repeat BEFORE INSERT ON task_subtasks BEGIN SELECT RAISE(ABORT, 'synthetic repeat failure'); END",
      );
      await expectLater(
        service.repeatCompletedTask(original, const TaskRecurrence.daily()),
        throwsA(anything),
      );
      expect(await repo.loadTasks(), hasLength(1));
      expect((await repo.loadTask(original.id))!.isCompleted, isTrue);
      await db.customStatement('DROP TRIGGER reject_repeat');
      final results = await Future.wait([
        service.repeatCompletedTask(original, const TaskRecurrence.daily()),
        service.repeatCompletedTask(original, const TaskRecurrence.daily()),
      ]);
      expect(results.first.id, results.last.id);
      expect(await repo.loadTasks(), hasLength(2));
    },
  );

  test('rejects open, changed and deleted source tasks', () async {
    final original = await completed();
    await service.setCompleted(original, false);
    await expectLater(
      service.repeatCompletedTask(original, const TaskRecurrence.daily()),
      throwsStateError,
    );
    await service.setCompleted(original, true);
    // Change a field with an independently newer timestamp.
    await repo.saveTask(
      (await repo.loadTask(original.id))!.copyWith(
        title: 'Changed',
        updatedAt: today.add(const Duration(seconds: 1)),
      ),
    );
    await expectLater(
      service.repeatCompletedTask(original, const TaskRecurrence.daily()),
      throwsStateError,
    );
    await service.deleteTask(original.id);
    await expectLater(
      service.repeatCompletedTask(original, const TaskRecurrence.daily()),
      throwsStateError,
    );
  });

  test(
    'next date skips overdue backlog and respects future dates and weekdays',
    () {
      final rule = TaskRecurrence.weekly([DateTime.monday, DateTime.friday]);
      expect(
        nextTaskOccurrence(rule, DateTime(2026, 11, 1), today),
        DateTime(2026, 11, 20),
      );
      expect(
        nextTaskOccurrence(rule, DateTime(2026, 11, 20), today),
        DateTime(2026, 11, 23),
      );
      expect(
        nextTaskOccurrence(
          const TaskRecurrence.daily(),
          null,
          DateTime(2026, 3, 8, 23),
        ),
        DateTime(2026, 3, 9),
      );
    },
  );

  testWidgets('completed Tasks row opens and saves the explicit repeat', (
    tester,
  ) async {
    final original = await completed();
    await tester.pumpWidget(
      MaterialApp(
        home: TasksScreen(service: service, clock: () => today),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip('Schedule next occurrence of ${original.title}'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Schedule next occurrence'), findsOneWidget);
    await tester.tap(find.text('Schedule task'));
    await tester.pumpAndSettle();
    expect(await repo.loadTasks(), hasLength(2));
    expect(find.text('Next task ready: Nov 18, 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('repeat dialog previews weekdays, cancels and explicitly saves', (
    tester,
  ) async {
    final original = await completed();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<Task>(
                context: context,
                builder: (_) => TaskRepeatDialog(
                  service: service,
                  task: original,
                  today: today,
                ),
              ),
              child: const Text('Repeat'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Repeat'));
    await tester.pumpAndSettle();
    expect(find.text('Next due: Nov 18, 2026'), findsOneWidget);
    await tester.tap(find.text('Daily'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selected weekdays').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Schedule task'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Fri'));
    await tester.pumpAndSettle();
    expect(find.text('Next due: Nov 20, 2026'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await repo.loadTasks(), hasLength(1));
    await tester.tap(find.text('Repeat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Schedule task'));
    await tester.pumpAndSettle();
    expect(await repo.loadTasks(), hasLength(2));
    expect(tester.takeException(), isNull);
  });
}
