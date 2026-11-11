import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/tasks/application/task_repository.dart';
import 'package:scripture_planner/src/features/tasks/application/task_service.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';
import 'package:scripture_planner/src/features/today/application/today_day_view.dart';
import 'package:scripture_planner/src/features/today/application/today_planner_controller.dart';

Task task(
  String id, {
  String title = 'Same',
  DateTime? due,
  TaskTimeBlock? block,
}) => Task(
  id: id,
  title: title,
  isCompleted: false,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  dueDate: due,
  timeBlock: block,
);
void main() {
  final day = DateTime(2026, 9, 3);
  test(
    'projection retains distinct ids, removes duplicate ids and detects overlap',
    () {
      final a = task(
        'a',
        block: TaskTimeBlock(
          plannedDate: day,
          startMinutesLocal: 600,
          endMinutesLocal: 720,
        ),
      );
      final b = task(
        'b',
        block: TaskTimeBlock(
          plannedDate: day,
          startMinutesLocal: 660,
          endMinutesLocal: 1440,
        ),
      );
      final c = task('c', due: DateTime(2026, 9, 2));
      final view = TodayDayView.project(
        day,
        [b, a, a, c],
        [
          DailyPriority(date: DateTime(2026, 9, 2), taskId: 'a', position: 0),
          DailyPriority(date: day, taskId: 'b', position: 0),
          DailyPriority(date: day, taskId: 'a', position: 1),
          DailyPriority(date: day, taskId: 'a', position: 2),
        ],
      );
      expect(view.priorities.map((t) => t.id), ['b', 'a']);
      expect(view.scheduled.map((t) => t.id), ['a', 'b']);
      expect(view.overlappingIds, {'a', 'b'});
      expect(view.overdue.single.id, 'c');
    },
  );
  test('explicitly selected tomorrow remains fixed after midnight', () async {
    var now = day;
    final controller = TodayPlannerController(
      TaskService(_Repository()),
      clock: () => now,
    );
    controller.selectDay(DateTime(2026, 9, 4));
    now = DateTime(2026, 9, 4);
    controller.checkClock();
    now = DateTime(2026, 9, 5);
    controller.checkClock();
    expect(controller.selectedDay, DateTime(2026, 9, 4));
    controller.returnToToday();
    now = DateTime(2026, 9, 6);
    controller.checkClock();
    expect(controller.selectedDay, now);
    controller.dispose();
  });
  test(
    'Manage Tasks ignores a stale load and rejects duplicate writes',
    () async {
      final repo = _Repository();
      final old = Completer<List<Task>>();
      final newer = Completer<List<Task>>();
      repo.responses.addAll([old.future, newer.future]);
      final controller = ManageTasksController(
        TaskService(repo),
        clock: () => day,
      );
      final refresh = controller.refresh();
      newer.complete([task('new')]);
      await refresh;
      old.complete([task('old')]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.tasks.single.id, 'new');
      final gate = Completer<void>();
      final write = controller.write(() => gate.future);
      expect(
        await controller.write(() async => fail('duplicate write')),
        isFalse,
      );
      gate.complete();
      expect(await write, isTrue);
      controller.dispose();
    },
  );
  test('stale load cannot replace a newer selected day', () async {
    final repo = _Repository();
    final first = Completer<List<Task>>();
    final second = Completer<List<Task>>();
    repo.responses.addAll([first.future, second.future]);
    final controller = TodayPlannerController(
      TaskService(repo),
      selectedDate: day,
      clock: () => day,
    );
    controller.moveDay(1);
    second.complete([task('new', due: day.add(const Duration(days: 1)))]);
    await Future<void>.delayed(Duration.zero);
    first.complete([task('old', due: day)]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.selectedDay, day.add(const Duration(days: 1)));
    expect(controller.view!.dueToday.single.id, 'new');
    controller.dispose();
  });
  test(
    'clock boundary moves only a selected today and refreshes on resume',
    () async {
      final repo = _Repository();
      var now = day;
      final controller = TodayPlannerController(
        TaskService(repo),
        clock: () => now,
      );
      await Future<void>.delayed(Duration.zero);
      now = DateTime(2026, 9, 4);
      controller.checkClock();
      await Future<void>.delayed(Duration.zero);
      expect(controller.selectedDay, now);
      controller.selectDay(day);
      now = DateTime(2026, 9, 5);
      controller.checkClock();
      expect(controller.selectedDay, day);
      controller.dispose();
    },
  );
  test(
    'stale edit preserves newer completion and untouched block; failure leaves record intact',
    () async {
      final repo = _Repository();
      final service = TaskService(repo);
      final original = task('a');
      repo.tasks['a'] = original;
      final block = TaskTimeBlock(
        plannedDate: day,
        startMinutesLocal: 60,
        endMinutesLocal: 120,
      );
      await service.setTimeBlock(original, block);
      await service.setCompleted(original, true);
      await service.saveEdit(
        original: original,
        title: 'Changed',
        dueDate: null,
        timeBlock: null,
      );
      expect(repo.tasks['a']!.isCompleted, true);
      expect(repo.tasks['a']!.timeBlock, same(block));
      repo.failSave = true;
      await expectLater(
        service.saveEdit(
          original: repo.tasks['a']!,
          title: 'Lost',
          dueDate: null,
          timeBlock: block,
        ),
        throwsStateError,
      );
      expect(repo.tasks['a']!.title, 'Changed');
    },
  );
  test('writes serialize and retain a newer completion and block', () async {
    final repo = _Repository();
    final service = TaskService(repo);
    final original = task('a');
    repo.tasks['a'] = original;
    final gate = Completer<void>();
    repo.saveGate = gate;
    final completion = service.setCompleted(original, true);
    final block = TaskTimeBlock(
      plannedDate: day,
      startMinutesLocal: 20,
      endMinutesLocal: 40,
    );
    final scheduling = service.setTimeBlock(original, block);
    gate.complete();
    await Future.wait([completion, scheduling]);
    expect(repo.tasks['a']!.isCompleted, isTrue);
    expect(repo.tasks['a']!.timeBlock, same(block));
  });
  test(
    'controller rejects duplicate submissions while a save is pending',
    () async {
      final controller = TodayPlannerController(
        TaskService(_Repository()),
        clock: () => day,
      );
      await Future<void>.delayed(Duration.zero);
      final gate = Completer<void>();
      final first = controller.write(() => gate.future);
      expect(
        await controller.write(() async => fail('second action ran')),
        isFalse,
      );
      gate.complete();
      expect(await first, isTrue);
      controller.dispose();
    },
  );
  test(
    'invalid blocks reject reversed, out-of-range and zero-length times',
    () {
      for (final values in [
        [30, 30],
        [100, 50],
        [0, 1441],
        [-1, 1],
      ]) {
        expect(
          () => TaskTimeBlock(
            plannedDate: day,
            startMinutesLocal: values[0],
            endMinutesLocal: values[1],
          ),
          throwsArgumentError,
        );
      }
    },
  );
}

class _Repository implements TaskRepository {
  final tasks = <String, Task>{};
  final responses = <Future<List<Task>>>[];
  bool failSave = false;
  Completer<void>? saveGate;
  @override
  Future<List<Task>> loadTasks() => responses.isNotEmpty
      ? responses.removeAt(0)
      : Future.value(tasks.values.toList());
  @override
  Future<Task?> loadTask(String id) async => tasks[id];
  @override
  Future<void> saveTask(Task task) async {
    final gate = saveGate;
    saveGate = null;
    if (gate != null) await gate.future;
    if (failSave) throw StateError('save failed');
    tasks[task.id] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    tasks.remove(id);
  }

  @override
  Future<List<DailyPriority>> loadDailyPriorities(DateTime date) async => [];
  @override
  Future<List<Task>> loadOpenTasksDueBy(DateTime date) async => [];
  @override
  Future<void> selectDailyPriority(DateTime date, String taskId) async {}
  @override
  Future<void> unselectDailyPriority(DateTime date, String taskId) async {}
  @override
  Future<void> reorderDailyPriorities(
    DateTime date,
    List<String> taskIds,
  ) async {}
}
