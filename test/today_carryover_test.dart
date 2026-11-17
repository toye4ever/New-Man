import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/today/application/today_day_view.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';

void main() {
  test('an unfinished zero-due-date block stays actionable after midnight', () {
    final task = Task(
      id: 'carryover',
      title: 'Prepare Sunday handout',
      isCompleted: false,
      createdAt: DateTime.utc(2026, 11, 16),
      updatedAt: DateTime.utc(2026, 11, 16),
      timeBlock: TaskTimeBlock(
        plannedDate: DateTime(2026, 11, 16),
        startMinutesLocal: 600,
        endMinutesLocal: 660,
      ),
    );
    expect(TodayDayView.project(DateTime(2026, 11, 16), [task], []).scheduled, [
      task,
    ]);
    final nextDay = TodayDayView.project(DateTime(2026, 11, 17), [task], []);
    expect(
      [
        ...nextDay.priorities,
        ...nextDay.scheduled,
        ...nextDay.overdue,
        ...nextDay.dueToday,
        ...nextDay.unscheduled,
      ],
      contains(task),
      reason:
          'An unfinished task should not disappear after its block date passes.',
    );
  });

  test(
    'carryover keeps block metadata and respects existing date/completion groups',
    () {
      final selected = DateTime(2026, 11, 17, 18, 45);
      final yesterday = DateTime(2026, 11, 16);
      final today = DateTime(2026, 11, 17);
      final tomorrow = DateTime(2026, 11, 18);
      Task fixture(
        String id, {
        DateTime? blockDay,
        DateTime? due,
        bool completed = false,
      }) => Task(
        id: id,
        title: id,
        isCompleted: completed,
        completedAt: completed ? DateTime.utc(2026, 11, 16, 12) : null,
        createdAt: DateTime.utc(2026, 11, 16),
        updatedAt: DateTime.utc(2026, 11, 16),
        dueDate: due,
        timeBlock: blockDay == null
            ? null
            : TaskTimeBlock(
                plannedDate: blockDay,
                startMinutesLocal: 600,
                endMinutesLocal: 660,
              ),
      );
      final carry = fixture('carry', blockDay: yesterday);
      final tasks = [
        carry,
        fixture('current', blockDay: today),
        fixture('future', blockDay: tomorrow),
        fixture('completed', blockDay: yesterday, completed: true),
        fixture('late', blockDay: yesterday, due: yesterday),
        fixture('due', blockDay: yesterday, due: today),
        fixture('future-dated-block', blockDay: yesterday, due: tomorrow),
        fixture('plain'),
        fixture('future-dated-unblocked', due: tomorrow),
      ];
      final view = TodayDayView.project(selected, tasks, []);
      expect(
        view.unscheduled.map((task) => task.id),
        unorderedEquals(['carry', 'plain', 'future-dated-unblocked']),
      );
      expect(view.scheduled.map((task) => task.id), ['current']);
      expect(view.overdue.map((task) => task.id), ['late']);
      expect(view.dueToday.map((task) => task.id), ['due']);
      expect(view.overlappingIds, isEmpty);
      final retained = view.unscheduled.singleWhere(
        (task) => task.id == carry.id,
      );
      expect(retained, same(carry));
      expect(retained.timeBlock, same(carry.timeBlock));
      expect(retained.timeBlock!.plannedDate, yesterday);
      expect(retained.timeBlock!.startMinutesLocal, 600);
      expect(retained.timeBlock!.endMinutesLocal, 660);
      expect(TodayDayView.project(tomorrow, [carry], []).unscheduled, [carry]);
    },
  );
}
