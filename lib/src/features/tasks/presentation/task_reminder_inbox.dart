import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../application/task_service.dart';
import '../domain/task.dart';
import '../domain/task_reminder.dart';

/// Foreground-only presentation. It never posts platform notifications.
class TaskReminderInbox extends StatefulWidget {
  const TaskReminderInbox({required this.service, this.clock, super.key});
  final TaskService service;
  final DateTime Function()? clock;
  @override
  State<TaskReminderInbox> createState() => _TaskReminderInboxState();
}

class _TaskReminderInboxState extends State<TaskReminderInbox>
    with WidgetsBindingObserver {
  List<Task> tasks = const [];
  final pending = <String>{};
  String? error;
  bool loadFailed = false;
  int generation = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.service.addListener(reload);
    _startClock();
    reload();
  }

  void _startClock() {
    timer?.cancel();
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _startClock();
    if (state == AppLifecycleState.resumed) reload();
  }

  @override
  void didUpdateWidget(covariant TaskReminderInbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      oldWidget.service.removeListener(reload);
      widget.service.addListener(reload);
      tasks = const [];
      reload();
    }
  }

  Future<void> reload() async {
    final request = ++generation;
    try {
      final loaded = await widget.service.loadTasks();
      if (!mounted || request != generation) return;
      setState(() {
        tasks = loaded;
        loadFailed = false;
        error = null;
      });
    } catch (_) {
      if (!mounted || request != generation) return;
      setState(() {
        loadFailed = true;
        error = 'In-app reminders could not be refreshed.';
      });
    }
  }

  Future<void> dismiss(Task task) async {
    if (!pending.add(task.id)) return;
    setState(() {});
    try {
      await widget.service.dismissTaskReminder(task);
      if (mounted) await reload();
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Reminder could not be dismissed. Try again.');
      }
    } finally {
      pending.remove(task.id);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    generation++;
    timer?.cancel();
    widget.service.removeListener(reload);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final due = loadFailed
        ? const <Task>[]
        : dueTaskReminders(tasks, (widget.clock ?? DateTime.now)());
    if (due.isEmpty && error == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'In-app reminders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'Shown while New Man is open. No background notifications.',
            ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (loadFailed)
              TextButton(
                onPressed: reload,
                child: const Text('Retry reminders'),
              ),
            for (final task in due)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(task.title),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(task.dueDate!)} at ${TimeOfDay(hour: task.reminderMinutesLocal! ~/ 60, minute: task.reminderMinutesLocal! % 60).format(context)}',
                ),
                trailing: IconButton(
                  tooltip: 'Dismiss reminder for ${task.title}',
                  onPressed: pending.contains(task.id)
                      ? null
                      : () => dismiss(task),
                  icon: const Icon(Icons.done),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
