import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../tasks/application/task_service.dart';
import '../../tasks/domain/task.dart';
import 'today_day_view.dart';

class TodayPlannerController extends ChangeNotifier {
  TodayPlannerController(
    this.service, {
    DateTime? selectedDate,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    followsToday = selectedDate == null;
    selectedDay = localDay(selectedDate ?? _clock());
    _observedDay = localDay(_clock());
    _observedOffset = _clock().timeZoneOffset;
    service.addListener(refresh);
    _scheduleBoundary();
    _clockCheck = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = _clock();
      if (localDay(now) != _observedDay ||
          now.timeZoneOffset != _observedOffset) {
        checkClock();
      }
    });
    refresh();
  }
  final TaskService service;
  final DateTime Function() _clock;
  late DateTime selectedDay;
  late bool followsToday;
  late DateTime _observedDay;
  late Duration _observedOffset;
  TodayDayView? view;
  bool loading = true;
  bool saving = false;
  String? error;
  int _generation = 0;
  bool _disposed = false;
  Timer? _timer;
  Timer? _clockCheck;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _scheduleBoundary() {
    _timer?.cancel();
    final now = _clock();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now), checkClock);
  }

  void checkClock() {
    final now = _clock();
    final day = localDay(now);
    _observedOffset = now.timeZoneOffset;
    if (day != _observedDay) {
      if (followsToday) selectedDay = day;
      _observedDay = day;
    }
    _scheduleBoundary();
    refresh();
  }

  void selectDay(DateTime date) {
    followsToday = false;
    selectedDay = localDay(date);
    refresh();
  }

  void moveDay(int days) => selectDay(
    DateTime(selectedDay.year, selectedDay.month, selectedDay.day + days),
  );
  void returnToToday() {
    followsToday = true;
    selectedDay = localDay(_clock());
    refresh();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final day = selectedDay;
    loading = true;
    error = null;
    _emit();
    try {
      final result = await TodayDayView.load(
        taskService: service,
        localDate: day,
      );
      if (_disposed || generation != _generation) return;
      view = result;
      loading = false;
      _emit();
    } catch (_) {
      if (_disposed || generation != _generation) return;
      loading = false;
      error = 'Tasks could not be loaded. Please try again.';
      _emit();
    }
  }

  Future<bool> write(Future<void> Function() action) async {
    if (saving) return false;
    saving = true;
    ++_generation;
    _emit();
    try {
      await action();
      await refresh();
      return true;
    } catch (_) {
      error = 'The task could not be saved. Please try again.';
      return false;
    } finally {
      saving = false;
      _emit();
    }
  }

  Future<bool> toggleCompletion(Task task) =>
      write(() => service.setCompleted(task, !task.isCompleted));
  Future<bool> togglePriority(Task task) {
    final day = selectedDay;
    final selected = view?.priorities.any((t) => t.id == task.id) ?? false;
    return write(
      () => selected
          ? service.unselectDailyPriority(day, task.id)
          : service.selectDailyPriority(day, task.id),
    );
  }

  Future<bool> movePriority(int index, int offset) {
    final ids = view!.priorities.map((t) => t.id).toList();
    final target = index + offset;
    if (target < 0 || target >= ids.length) return Future.value(false);
    final item = ids.removeAt(index);
    ids.insert(target, item);
    final day = selectedDay;
    return write(() => service.reorderDailyPriorities(day, ids));
  }

  @override
  void dispose() {
    _disposed = true;
    service.removeListener(refresh);
    ++_generation;
    _timer?.cancel();
    _clockCheck?.cancel();
    super.dispose();
  }
}

/// Coordinates the task list and the priority date independently of its UI.
class ManageTasksController extends ChangeNotifier {
  ManageTasksController(
    this.service, {
    DateTime? selectedDate,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       followsToday = selectedDate == null {
    day = localDay(selectedDate ?? _clock());
    _observedDay = localDay(_clock());
    _offset = _clock().timeZoneOffset;
    service.addListener(refresh);
    _schedule();
    _clockCheck = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = _clock();
      if (localDay(now) != _observedDay || now.timeZoneOffset != _offset) {
        checkClock();
      }
    });
    refresh();
  }
  final TaskService service;
  final DateTime Function() _clock;
  final bool followsToday;
  late DateTime day;
  late DateTime _observedDay;
  late Duration _offset;
  List<Task> tasks = [];
  List<String> priorities = [];
  bool loading = true, saving = false;
  String? error;
  int _generation = 0;
  bool _disposed = false;
  Timer? _boundary, _clockCheck;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _schedule() {
    _boundary?.cancel();
    final now = _clock();
    _boundary = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      checkClock,
    );
  }

  void checkClock() {
    final now = _clock();
    _observedDay = localDay(now);
    _offset = now.timeZoneOffset;
    if (followsToday && day != _observedDay) {
      day = _observedDay;
      loading = true;
      _emit();
    }
    _schedule();
    refresh();
  }

  Future<void> refresh() async {
    final revision = ++_generation;
    final date = day;
    try {
      final values = await Future.wait<Object>([
        service.loadTasks(),
        service.loadDailyPriorities(date),
      ]);
      if (_disposed || revision != _generation) return;
      tasks = values[0] as List<Task>;
      priorities = (values[1] as List<DailyPriority>)
          .map((p) => p.taskId)
          .toList();
      loading = false;
      error = null;
      _emit();
    } catch (_) {
      if (_disposed || revision != _generation) return;
      loading = false;
      error = 'Tasks could not be loaded. Try again.';
      _emit();
    }
  }

  Future<bool> write(Future<void> Function() action) async {
    if (saving) return false;
    saving = true;
    ++_generation;
    _emit();
    try {
      await action();
      await refresh();
      return true;
    } catch (_) {
      return false;
    } finally {
      saving = false;
      _emit();
    }
  }

  Future<bool> togglePriority(Task task) {
    final date = day;
    final selected = priorities.contains(task.id);
    return write(
      () => selected
          ? service.unselectDailyPriority(date, task.id)
          : service.selectDailyPriority(date, task.id),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    service.removeListener(refresh);
    _boundary?.cancel();
    _clockCheck?.cancel();
    super.dispose();
  }
}
