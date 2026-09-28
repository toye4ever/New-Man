import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/tasks/application/task_repository.dart';
import 'package:scripture_planner/src/features/tasks/application/task_service.dart';
import 'package:scripture_planner/src/features/tasks/data/drift_task_repository.dart';
import 'package:scripture_planner/src/features/tasks/data/local/task_dao.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';
import 'package:scripture_planner/src/features/today/presentation/today_screen.dart';

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

  testWidgets('shows loading, then the empty persisted Task state', (
    tester,
  ) async {
    await tester.pumpWidget(todayApp(service));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('No open Tasks are due today.'), findsOneWidget);
  });

  testWidgets(
    'shows persisted open-due Tasks through the application boundary',
    (tester) async {
      await service.createTask(title: 'Overdue', dueDate: DateTime(2026, 9, 2));
      await service.createTask(
        title: 'Due today',
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

      expect(find.text('2 open tasks due by today.'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(ReorderableListView), findsNothing);
    },
  );

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
      find.text('Tasks could not be loaded. Try reopening Today.'),
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
      throw UnsupportedError('not used');

  @override
  Future<Task?> loadTask(String id) => throw UnsupportedError('not used');

  @override
  Future<List<Task>> loadTasks() => throw UnsupportedError('not used');

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
