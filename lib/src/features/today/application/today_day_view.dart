import '../../tasks/application/task_service.dart';
import '../../tasks/domain/task.dart';

DateTime localDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class TodayDayView {
  const TodayDayView({
    required this.priorities,
    required this.overdue,
    required this.dueToday,
    required this.scheduled,
    required this.unscheduled,
    required this.overlappingIds,
  });
  final List<Task> priorities;
  final List<Task> overdue;
  final List<Task> dueToday;
  final List<Task> scheduled;
  final List<Task> unscheduled;
  final Set<String> overlappingIds;

  static Future<TodayDayView> load({
    required TaskService taskService,
    required DateTime localDate,
  }) async {
    final day = localDay(localDate);
    final results = await Future.wait<Object>([
      taskService.loadTasks(),
      taskService.loadDailyPriorities(day),
    ]);
    return TodayDayView.project(
      day,
      results[0] as List<Task>,
      results[1] as List<DailyPriority>,
    );
  }

  static TodayDayView project(
    DateTime date,
    List<Task> tasks,
    List<DailyPriority> priorityRows,
  ) {
    final day = localDay(date);
    final byId = <String, Task>{};
    for (final task in tasks) {
      byId.putIfAbsent(task.id, () => task);
    }
    final unique = byId.values.toList();
    int order(Task a, Task b) {
      final title = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return title != 0 ? title : a.id.compareTo(b.id);
    }

    final rows = [...priorityRows]
      ..sort((a, b) {
        final n = a.position.compareTo(b.position);
        return n != 0 ? n : a.taskId.compareTo(b.taskId);
      });
    final seen = <String>{};
    final priorities = <Task>[];
    for (final row in rows) {
      final task = byId[row.taskId];
      if (task != null && localDay(row.date) == day && seen.add(task.id)) {
        priorities.add(task);
      }
    }
    final scheduled =
        unique
            .where(
              (t) =>
                  t.timeBlock != null &&
                  localDay(t.timeBlock!.plannedDate) == day,
            )
            .toList()
          ..sort((a, b) {
            final n = a.timeBlock!.startMinutesLocal.compareTo(
              b.timeBlock!.startMinutesLocal,
            );
            return n != 0 ? n : order(a, b);
          });
    final overlap = <String>{};
    for (var i = 0; i < scheduled.length; i++) {
      for (var j = i + 1; j < scheduled.length; j++) {
        if (scheduled[j].timeBlock!.startMinutesLocal >=
            scheduled[i].timeBlock!.endMinutesLocal) {
          break;
        }
        overlap.addAll([scheduled[i].id, scheduled[j].id]);
      }
    }
    final open = unique.where((t) => !t.isCompleted).toList();
    final overdue =
        open
            .where(
              (t) => t.dueDate != null && localDay(t.dueDate!).isBefore(day),
            )
            .toList()
          ..sort(order);
    final due =
        open
            .where((t) => t.dueDate != null && localDay(t.dueDate!) == day)
            .toList()
          ..sort(order);
    final unscheduled =
        open
            .where(
              (t) =>
                  t.timeBlock == null &&
                  (t.dueDate == null || localDay(t.dueDate!).isAfter(day)),
            )
            .toList()
          ..sort(order);
    return TodayDayView(
      priorities: priorities,
      overdue: overdue,
      dueToday: due,
      scheduled: scheduled,
      unscheduled: unscheduled,
      overlappingIds: overlap,
    );
  }
}
