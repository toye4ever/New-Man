import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
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
    database = AppDatabase(NativeDatabase.memory());
    service = TaskService(
      DriftTaskRepository(TaskDao(database)),
      clock: () => DateTime.utc(2026, 9, 3, 12),
    );
  });
  tearDown(() => database.close());
  Widget todayApp(TaskService taskService) => MaterialApp(
    home: TodayScreen(taskService: taskService, localDate: today),
  );

  testWidgets(
    'past undated block carries into Unscheduled and stays editable',
    (tester) async {
      final task = await service.createTask(
        title: 'Synthetic carryover',
        timeBlock: TaskTimeBlock(
          plannedDate: today.subtract(const Duration(days: 1)),
          startMinutesLocal: 600,
          endMinutesLocal: 660,
        ),
      );
      await tester.pumpWidget(todayApp(service));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Synthetic carryover'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Unscheduled'), findsOneWidget);
      expect(find.text('Synthetic carryover'), findsOneWidget);
      expect(find.text('Block: Sep 2, 2026 10:00–11:00'), findsOneWidget);
      await tester.tap(find.text('Synthetic carryover'));
      await tester.pumpAndSettle();
      expect(find.text('Block date: Sep 2, 2026'), findsOneWidget);
      final start = tester.widget<TextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Start time (HH:MM)',
        ),
      );
      expect(start.controller!.text, '10:00');
      await tester.ensureVisible(find.text('Save task'));
      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();
      final retained = (await service.loadTasks()).singleWhere(
        (item) => item.id == task.id,
      );
      expect(retained.dueDate, isNull);
      expect(retained.timeBlock!.plannedDate, DateTime(2026, 9, 2));
      expect(retained.timeBlock!.endMinutesLocal, 660);
      expect(tester.takeException(), isNull);
    },
  );
}
