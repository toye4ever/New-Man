import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/tasks/application/task_repository.dart';
import 'package:scripture_planner/src/features/tasks/application/task_service.dart';
import 'package:scripture_planner/src/features/tasks/data/drift_task_repository.dart';
import 'package:scripture_planner/src/features/tasks/data/local/task_dao.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';
import 'package:scripture_planner/src/features/today/presentation/today_screen.dart';
import 'package:scripture_planner/src/features/tasks/presentation/tasks_screen.dart';

void main() {
  late AppDatabase database;
  late TaskService service;
  final today = DateTime(2026, 9, 3);

  setUp(() {
    database = AppDatabase(
      NativeDatabase.memory(
        setup: (sqlite) => sqlite.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    service = TaskService(
      DriftTaskRepository(TaskDao(database)),
      clock: () => DateTime.utc(2026, 9, 3, 12),
    );
  });

  tearDown(() => database.close());

  Widget todayApp(TaskService taskService) => MaterialApp(
    home: TodayScreen(taskService: taskService, localDate: today),
  );

  testWidgets('undated open tasks remain manageable in Tasks and Today', (
    tester,
  ) async {
    final undated = await service.createTask(title: 'Undated task');
    await service.createTask(title: 'Due today task', dueDate: today);
    await service.createTask(
      title: 'Overdue task',
      dueDate: today.subtract(const Duration(days: 1)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TasksScreen(service: service, localDate: today),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Due today task'), findsOneWidget);
    expect(find.text('Overdue task'), findsOneWidget);
    expect(find.text('Undated task'), findsOneWidget);
    expect(
      (await service.loadTasks())
          .singleWhere((t) => t.id == undated.id)
          .dueDate,
      isNull,
    );
    await tester.pumpWidget(todayApp(service));
    await tester.pumpAndSettle();
    expect(find.text('Due today task'), findsOneWidget);
    expect(find.text('Overdue task'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Undated task'), 300);
    expect(find.text('Undated task'), findsOneWidget);
  });

  testWidgets(
    'Manage Tasks follows today on resume but preserves an explicitly selected date',
    (tester) async {
      final task = await service.createTask(title: 'Priority task');
      var now = today;
      await tester.pumpWidget(
        MaterialApp(
          home: TasksScreen(service: service, clock: () => now),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Priorities for Sep 3, 2026'), findsOneWidget);
      now = DateTime(2026, 9, 4);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Make priority for Sep 4, 2026'), findsOneWidget);
      await tester.tap(find.byTooltip('Make priority for Sep 4, 2026'));
      await tester.pumpAndSettle();
      expect((await service.loadDailyPriorities(now)).single.taskId, task.id);
      expect(await service.loadDailyPriorities(today), isEmpty);
      await tester.pumpWidget(
        MaterialApp(
          home: TasksScreen(
            service: service,
            localDate: today,
            clock: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();
      now = DateTime(2026, 9, 5);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Make priority for Sep 3, 2026'), findsOneWidget);
      await tester.tap(find.byTooltip('Make priority for Sep 3, 2026'));
      await tester.pumpAndSettle();
      expect((await service.loadDailyPriorities(today)).single.taskId, task.id);
      expect(find.byTooltip('Remove priority for Sep 3, 2026'), findsOneWidget);
    },
  );

  for (final selectedOffset in <int?>[null, 0, 1]) {
    testWidgets(
      'Manage Tasks automatic midnight ${selectedOffset == null ? 'follows today' : 'retains explicit day $selectedOffset'}',
      (tester) async {
        final current = await service.createTask(title: 'Current priority');
        final next = await service.createTask(title: 'Next priority');
        final unrelated = await service.createTask(title: 'Unrelated priority');
        final tomorrow = DateTime(2026, 9, 4);
        final otherDay = DateTime(2026, 9, 5);
        await service.selectDailyPriority(today, current.id);
        await service.selectDailyPriority(tomorrow, next.id);
        await service.selectDailyPriority(otherDay, unrelated.id);
        var now = DateTime(2026, 9, 3, 23, 59, 50);
        final selected = selectedOffset == null
            ? null
            : today.add(Duration(days: selectedOffset));
        await tester.pumpWidget(
          MaterialApp(
            home: TasksScreen(
              service: service,
              localDate: selected,
              clock: () => now,
            ),
          ),
        );
        await tester.pumpAndSettle();
        Finder action(String title, String label) => find.descendant(
          of: find.ancestor(
            of: find.text(title),
            matching: find.byType(ListTile),
          ),
          matching: find.byTooltip(label),
        );
        final initialLabel = selectedOffset == 1
            ? 'Sep 4, 2026'
            : 'Sep 3, 2026';
        expect(find.text('Priorities for $initialLabel'), findsOneWidget);
        now = tomorrow;
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpAndSettle();
        final day = selected ?? tomorrow;
        final label = selectedOffset == 0 ? 'Sep 3, 2026' : 'Sep 4, 2026';
        final selectedTask = selectedOffset == 0 ? current : next;
        final addedTask = selectedOffset == 0 ? next : current;
        expect(find.text('Priorities for $label'), findsOneWidget);
        expect(
          action(selectedTask.title, 'Remove priority for $label'),
          findsOneWidget,
        );
        expect(
          action(addedTask.title, 'Make priority for $label'),
          findsOneWidget,
        );
        if (selectedOffset == null) {
          expect(
            find.byTooltip('Remove priority for Sep 3, 2026'),
            findsNothing,
          );
          expect(find.byTooltip('Make priority for Sep 3, 2026'), findsNothing);
        }
        await tester.tap(
          action(selectedTask.title, 'Remove priority for $label'),
        );
        await tester.pumpAndSettle();
        await tester.tap(action(addedTask.title, 'Make priority for $label'));
        await tester.pumpAndSettle();
        expect((await service.loadDailyPriorities(day)).map((p) => p.taskId), [
          addedTask.id,
        ]);
        final untouched = day == today ? tomorrow : today;
        expect(
          (await service.loadDailyPriorities(untouched)).map((p) => p.taskId),
          [day == today ? next.id : current.id],
        );
        expect(
          (await service.loadDailyPriorities(otherDay)).map((p) => p.taskId),
          [unrelated.id],
        );
      },
    );
  }

  testWidgets('shows loading, then every empty daily section', (tester) async {
    await tester.pumpWidget(todayApp(service));
    expect(find.text('New Man'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(
      find.text(
        'Choose priorities for this day. Three is a helpful starting point.',
      ),
      findsOneWidget,
    );
    expect(find.text('No open overdue tasks.'), findsOneWidget);
    expect(find.text('No open tasks due on this day.'), findsOneWidget);
  });

  testWidgets('Today can create and prioritize a persisted task', (
    tester,
  ) async {
    await tester.pumpWidget(todayApp(service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save task'));
    await tester.pump();
    expect(find.text('Enter a task title.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Read and reflect');
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    expect((await service.loadTasks()).single.title, 'Read and reflect');
    await tester.tap(find.byTooltip('Make priority for Sep 3, 2026'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Read and reflect'), findsWidgets);
    expect((await service.loadDailyPriorities(today)), hasLength(1));
  });

  testWidgets(
    'shows every priority in saved order, including completed and undated Tasks',
    (tester) async {
      final fourth = await service.createTask(title: 'Fourth undated priority');
      final third = await service.createTask(
        title: 'Third completed priority',
        dueDate: DateTime(2026, 9, 9),
      );
      final second = await service.createTask(title: 'Second priority');
      final first = await service.createTask(title: 'First priority');
      await service.setCompleted(third, true);
      for (final task in [fourth, third, second, first]) {
        await service.selectDailyPriority(today, task.id);
      }
      await service.reorderDailyPriorities(today, [
        first.id,
        second.id,
        third.id,
        fourth.id,
      ]);

      await tester.pumpWidget(todayApp(service));
      await tester.pumpAndSettle();

      final positions = [first, second, third, fourth]
          .map((task) => tester.getTopLeft(find.text(task.title).first).dy)
          .toList();
      expect(positions[0], lessThan(positions[1]));
      expect(positions[1], lessThan(positions[2]));
      expect(positions[2], lessThan(positions[3]));
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byType(Checkbox), findsWidgets);
      expect(find.byType(ReorderableListView), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byTooltip('Move priority up'), findsWidgets);
      expect(find.text('Manage tasks'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(Dismissible), findsNothing);
    },
  );

  testWidgets(
    'splits open dated Tasks at the local-day boundary without duplicates',
    (tester) async {
      await service.createTask(
        title: 'Past-due item',
        dueDate: DateTime(2026, 9, 2, 23, 59),
      );
      await service.createTask(
        title: 'Due-today item',
        dueDate: DateTime(2026, 9, 3, 23, 59),
      );
      await service.createTask(title: 'Future', dueDate: DateTime(2026, 9, 4));
      await service.createTask(title: 'Open without a due date');
      final completed = await service.createTask(
        title: 'Completed today',
        dueDate: DateTime(2026, 9, 3),
      );
      await service.setCompleted(completed, true);

      await tester.pumpWidget(todayApp(service));
      await tester.pumpAndSettle();

      expect(find.text('Past-due item'), findsOneWidget);
      expect(find.text('Due-today item'), findsOneWidget);
      expect(find.text('Completed today'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Open without a due date'),
        300,
      );
      expect(find.text('Open without a due date'), findsOneWidget);
      expect(find.text('Future'), findsOneWidget);
    },
  );

  testWidgets('priority reordering only changes the selected day', (
    tester,
  ) async {
    final first = await service.createTask(title: 'First');
    final second = await service.createTask(title: 'Second');
    final tomorrow = DateTime(2026, 9, 4);
    for (final task in [first, second]) {
      await service.selectDailyPriority(today, task.id);
      await service.selectDailyPriority(tomorrow, task.id);
    }
    await tester.pumpWidget(todayApp(service));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Move priority down').first);
    await tester.pumpAndSettle();
    expect((await service.loadDailyPriorities(today)).map((p) => p.taskId), [
      second.id,
      first.id,
    ]);
    expect((await service.loadDailyPriorities(tomorrow)).map((p) => p.taskId), [
      first.id,
      second.id,
    ]);
  });

  testWidgets('narrow and wide layouts handle large text and long task titles', (
    tester,
  ) async {
    final item = await service.createTask(
      title:
          'A very long task title that should remain readable as the available width changes and text becomes larger',
    );
    await service.selectDailyPriority(today, item.id);
    for (final size in [const Size(320, 700), const Size(1200, 800)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: TodayScreen(taskService: service, localDate: today),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(item.title), findsWidgets);
      expect(tester.takeException(), isNull);
    }
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Complete ${item.title}'), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.context, isNotNull);
    semantics.dispose();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows a bounded failure state when Task loading fails', (
    tester,
  ) async {
    final completer = Completer<List<Task>>();
    final failingService = TaskService(
      _LoadOnlyTaskRepository((_) => completer.future),
    );

    await tester.pumpWidget(todayApp(failingService));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.completeError(StateError('synthetic load failure'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tasks could not be loaded. Please try again.'),
      findsOneWidget,
    );
  });
}

class _LoadOnlyTaskRepository implements TaskRepository {
  _LoadOnlyTaskRepository(this.loadOpenTasks);

  final Future<List<Task>> Function(DateTime date) loadOpenTasks;

  @override
  Future<List<Task>> loadOpenTasksDueBy(DateTime date) => loadOpenTasks(date);

  @override
  Future<void> deleteTask(String id) => throw UnsupportedError('not used');

  @override
  Future<List<DailyPriority>> loadDailyPriorities(DateTime date) =>
      Future.value([]);

  @override
  Future<Task?> loadTask(String id) => throw UnsupportedError('not used');

  @override
  Future<List<Task>> loadTasks() => loadOpenTasks(DateTime(2026, 9, 3));

  @override
  Future<void> reorderDailyPriorities(DateTime date, List<String> taskIds) =>
      throw UnsupportedError('not used');

  @override
  Future<void> saveTask(Task task) => throw UnsupportedError('not used');

  @override
  Future<void> selectDailyPriority(DateTime date, String taskId) =>
      throw UnsupportedError('not used');

  @override
  Future<void> unselectDailyPriority(DateTime date, String taskId) =>
      throw UnsupportedError('not used');
}
