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
import 'package:scripture_planner/src/features/tasks/domain/task_reminder.dart';
import 'package:scripture_planner/src/features/tasks/presentation/task_editor_dialog.dart';
import 'package:scripture_planner/src/features/tasks/presentation/task_reminder_inbox.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository repo;
  late TaskService service;
  var now = DateTime(2026, 11, 17, 9);
  setUp(() {
    now = DateTime(2026, 11, 17, 9);
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftTaskRepository(TaskDao(db));
    service = TaskService(repo, clock: () => now);
  });
  tearDown(() async {
    service.dispose();
    await db.close();
  });
  Future<Task> make({int? time = 540, DateTime? day}) => service.createTask(
    title: 'Read notes',
    dueDate: day ?? DateTime(2026, 11, 17),
    reminderMinutesLocal: time,
  );
  Future<List<Task>> due() async =>
      dueTaskReminders(await repo.loadTasks(), now);

  test(
    'opt-in triggers at local time; overdue survives while future and Off stay quiet',
    () async {
      final task = await make();
      await make(time: null);
      await make(day: DateTime(2026, 11, 18));
      now = DateTime(2026, 11, 17, 8, 59);
      expect(await due(), isEmpty);
      now = DateTime(2026, 11, 17, 9);
      expect((await due()).single.id, task.id);
      now = DateTime(2026, 11, 18, 0, 1);
      expect((await due()).single.id, task.id);
      await service.dismissTaskReminder(task);
      expect(await due(), isEmpty);
      await service.dismissTaskReminder(task);
      expect(await due(), isEmpty);
    },
  );

  test(
    'complete, reopen, edit, Off and delete reconcile the current occurrence',
    () async {
      final task = await make();
      await service.setCompleted(task, true);
      expect(await due(), isEmpty);
      await service.setCompleted(task, false);
      expect(await due(), hasLength(1));
      final current = (await repo.loadTask(task.id))!;
      await service.dismissTaskReminder(current);
      final dismissed = (await repo.loadTask(task.id))!;
      await service.saveEdit(
        original: dismissed,
        title: 'New title',
        dueDate: dismissed.dueDate,
      );
      expect(await due(), isEmpty);
      final titled = (await repo.loadTask(task.id))!;
      await service.saveEdit(
        original: titled,
        title: titled.title,
        dueDate: titled.dueDate,
        reminderMinutesLocal: 480,
        editReminder: true,
      );
      expect(await due(), hasLength(1));
      final changed = (await repo.loadTask(task.id))!;
      await service.saveEdit(
        original: changed,
        title: changed.title,
        dueDate: DateTime(2026, 11, 18),
      );
      expect(await due(), isEmpty);
      now = DateTime(2026, 11, 18, 9);
      expect(await due(), hasLength(1));
      final moved = (await repo.loadTask(task.id))!;
      await service.saveEdit(
        original: moved,
        title: moved.title,
        dueDate: moved.dueDate,
        editReminder: true,
      );
      expect((await repo.loadTask(task.id))!.reminderMinutesLocal, isNull);
      expect(await due(), isEmpty);
      await service.deleteTask(task.id);
      expect(await due(), isEmpty);
    },
  );

  test(
    'stale dismissal cannot silence a newly edited reminder; failed save retries',
    () async {
      final task = await make();
      now = now.add(const Duration(seconds: 1));
      await service.saveEdit(
        original: task,
        title: task.title,
        dueDate: task.dueDate,
        reminderMinutesLocal: 480,
        editReminder: true,
      );
      await service.dismissTaskReminder(task);
      expect(await due(), hasLength(1));
      final changed = (await repo.loadTask(task.id))!;
      await db.customStatement(
        "CREATE TRIGGER fail_dismiss BEFORE UPDATE ON tasks BEGIN SELECT RAISE(ABORT, 'synthetic reminder failure'); END",
      );
      await expectLater(
        service.dismissTaskReminder(changed),
        throwsA(anything),
      );
      expect(await due(), hasLength(1));
      await db.customStatement('DROP TRIGGER fail_dismiss');
      await service.dismissTaskReminder(changed);
      expect(await due(), isEmpty);
    },
  );

  test(
    'removing due date clears reminder; invalid local times are rejected',
    () async {
      for (final time in [-1, 1440]) {
        await expectLater(make(time: time), throwsArgumentError);
      }
      await expectLater(
        service.createTask(title: 'No date', reminderMinutesLocal: 540),
        throwsArgumentError,
      );
      final task = await make();
      await service.updateTask(
        task: task,
        title: task.title,
        clearDueDate: true,
      );
      final current = (await repo.loadTask(task.id))!;
      expect(current.dueDate, isNull);
      expect(current.reminderMinutesLocal, isNull);
      expect(await due(), isEmpty);
    },
  );

  test(
    'recurring successor inherits local time with a fresh acknowledgement',
    () async {
      final source = await service.createTask(
        title: 'Daily',
        dueDate: DateTime(2026, 11, 17),
        recurrence: const TaskRecurrence.daily(),
        reminderMinutesLocal: 540,
      );
      await service.dismissTaskReminder(source);
      await service.setCompleted(source, true);
      final next = (await repo.loadTasks()).singleWhere((t) => !t.isCompleted);
      expect(next.reminderMinutesLocal, 540);
      expect(next.reminderDismissedKey, isNull);
      now = DateTime(2026, 11, 18, 9);
      expect((await due()).single.id, next.id);
    },
  );

  test(
    'DST gaps show at next clock evaluation; repeated hours do not re-arm dismissal',
    () async {
      final spring = await make(time: 150, day: DateTime(2026, 3, 8));
      expect(dueTaskReminders([spring], DateTime(2026, 3, 8, 1, 59)), isEmpty);
      expect(dueTaskReminders([spring], DateTime(2026, 3, 8, 3)), hasLength(1));
      final fall = await make(time: 90, day: DateTime(2026, 11, 1));
      final first = DateTime(2026, 11, 1, 1, 30);
      expect(dueTaskReminders([fall], first), hasLength(1));
      await service.dismissTaskReminder(fall);
      final dismissed = (await repo.loadTask(fall.id))!;
      expect(
        dueTaskReminders([dismissed], first.add(const Duration(hours: 1))),
        isEmpty,
      );
      expect(
        dueTaskReminders([dismissed], DateTime(2026, 11, 1, 1, 15)),
        isEmpty,
      );
    },
  );

  test('reminder and dismissal survive a real SQLite reopen', () async {
    final dir = await Directory.systemTemp.createTemp('newman-reminder-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/tasks.sqlite');
    service.dispose();
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    repo = DriftTaskRepository(TaskDao(db));
    service = TaskService(repo, clock: () => now);
    final task = await make();
    await service.dismissTaskReminder(task);
    service.dispose();
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    repo = DriftTaskRepository(TaskDao(db));
    service = TaskService(repo, clock: () => now);
    final restored = (await repo.loadTask(task.id))!;
    expect(restored.reminderMinutesLocal, 540);
    expect(restored.reminderDismissedKey, taskReminderKey(restored));
    expect(await due(), isEmpty);
  });

  testWidgets(
    'foreground inbox ticks without duplicate prompts and persists Dismiss',
    (tester) async {
      final task = await make();
      now = DateTime(2026, 11, 17, 8, 59);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskReminderInbox(service: service, clock: () => now),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('In-app reminders'), findsNothing);
      now = DateTime(2026, 11, 17, 9);
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('In-app reminders'), findsOneWidget);
      expect(find.text(task.title), findsOneWidget);
      await tester.pump(const Duration(minutes: 2));
      await tester.pumpAndSettle();
      expect(find.text(task.title), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss reminder for ${task.title}'));
      await tester.pumpAndSettle();
      expect(find.text('In-app reminders'), findsNothing);
      await tester.pump(const Duration(minutes: 2));
      await tester.pumpAndSettle();
      expect(find.text(task.title), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('inbox pauses clock checks and reconciles on app resume', (
    tester,
  ) async {
    await make();
    now = DateTime(2026, 11, 17, 8, 59);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskReminderInbox(service: service, clock: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    now = DateTime(2026, 11, 17, 9);
    await tester.pump(const Duration(minutes: 2));
    expect(find.text('In-app reminders'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('In-app reminders'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'dated task saves an opted-in local time at narrow width and large text',
    (tester) async {
      final source = await make(time: null);
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
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
      final toggle = find.byType(SwitchListTile);
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final time = find.widgetWithText(TextField, 'Reminder time (HH:mm)');
      await tester.ensureVisible(time);
      await tester.enterText(time, '08:30');
      await tester.ensureVisible(find.text('Save task'));
      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();
      final stored = (await repo.loadTask(source.id))!;
      expect(stored.reminderMinutesLocal, 510);
      expect(stored.dueDate, source.dueDate);
      expect(tester.takeException(), isNull);
    },
  );

  for (final action in ['cancel', 'save', 'reselect']) {
    testWidgets('clearing saved due date clears draft reminder: $action', (
      tester,
    ) async {
      final created = await service.createTask(
        title: 'Synthetic dated task',
        dueDate: DateTime(2026, 11, 17),
        reminderMinutesLocal: 540,
        timeBlock: TaskTimeBlock(
          plannedDate: DateTime(2026, 11, 17),
          startMinutesLocal: 600,
          endMinutesLocal: 630,
        ),
        subtasks: [service.newSubtask(title: 'Synthetic step')],
      );
      await service.dismissTaskReminder(created);
      final source = (await repo.loadTask(created.id))!;
      expect(source.reminderDismissedKey, isNotNull);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showTaskEditor(
                  context,
                  service,
                  task: source,
                  initialDate: DateTime(2026, 11, 17),
                ),
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Clear due date'));
      await tester.tap(find.text('Clear due date'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(
        find.widgetWithText(TextField, 'Reminder time (HH:mm)'),
        findsNothing,
      );
      if (action == 'reselect') {
        await tester.ensureVisible(find.text('Add due date (optional)'));
        await tester.tap(find.text('Add due date (optional)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isFalse,
        );
      }
      final button = find.text(action == 'cancel' ? 'Cancel' : 'Save task');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(TaskEditorDialog), findsNothing);
      final stored = (await repo.loadTask(source.id))!;
      if (action == 'cancel') {
        expect(stored.dueDate, source.dueDate);
        expect(stored.reminderMinutesLocal, source.reminderMinutesLocal);
        expect(stored.reminderDismissedKey, source.reminderDismissedKey);
        expect(stored.updatedAt, source.updatedAt);
      } else {
        expect(stored.dueDate, action == 'reselect' ? source.dueDate : null);
        expect(stored.reminderMinutesLocal, isNull);
        expect(stored.reminderDismissedKey, isNull);
      }
      expect(stored.timeBlock?.plannedDate, source.timeBlock?.plannedDate);
      expect(stored.timeBlock?.startMinutesLocal, 600);
      expect(stored.timeBlock?.endMinutesLocal, 630);
      expect(stored.subtasks.single.id, source.subtasks.single.id);
      expect(stored.recurrence, source.recurrence);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('editor requires a due date and saves explicit local time', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTaskEditor(context, service),
              child: const Text('Add'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Task title'),
      'Remind me',
    );
    final toggle = find.byType(SwitchListTile);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save task'));
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'An in-app reminder needs a due date and a time from 00:00 to 23:59.',
      ),
      findsOneWidget,
    );
    expect(await repo.loadTasks(), isEmpty);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save task'));
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    expect((await repo.loadTasks()).single.reminderMinutesLocal, isNull);
  });
}
