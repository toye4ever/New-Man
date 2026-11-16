import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../application/task_service.dart';
import '../domain/task.dart';
import '../domain/task_recurrence.dart';

class TaskRepeatDialog extends StatefulWidget {
  const TaskRepeatDialog({
    required this.service,
    required this.task,
    required this.today,
    super.key,
  });
  final TaskService service;
  final Task task;
  final DateTime today;

  @override
  State<TaskRepeatDialog> createState() => _TaskRepeatDialogState();
}

class _TaskRepeatDialogState extends State<TaskRepeatDialog> {
  bool daily = true;
  bool saving = false;
  final weekdays = <int>{};
  String? error;

  TaskRecurrence? get rule => daily
      ? const TaskRecurrence.daily()
      : weekdays.isEmpty
      ? null
      : TaskRecurrence.weekly(weekdays);

  DateTime? get nextDate {
    final selected = rule;
    if (selected == null) return null;
    try {
      return nextTaskOccurrence(selected, widget.task.dueDate, widget.today);
    } on StateError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  Future<void> save() async {
    final selected = rule;
    if (saving || selected == null || nextDate == null) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final next = await widget.service.repeatCompletedTask(
        widget.task,
        selected,
      );
      if (mounted) Navigator.pop(context, next);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error =
              'Could not schedule the next task. Check the original task and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = nextDate;
    return PopScope(
      canPop: !saving,
      child: AlertDialog(
        title: const Text('Schedule next occurrence'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.task.title),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool>(
                  initialValue: daily,
                  decoration: const InputDecoration(
                    labelText: 'Next date rule',
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Daily')),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Selected weekdays'),
                    ),
                  ],
                  onChanged: saving
                      ? null
                      : (value) => setState(() => daily = value ?? true),
                ),
                if (!daily)
                  Wrap(
                    spacing: 4,
                    children: [
                      for (var day = 1; day <= 7; day++)
                        FilterChip(
                          label: Text(
                            const [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ][day - 1],
                          ),
                          selected: weekdays.contains(day),
                          onSelected: saving
                              ? null
                              : (selected) => setState(() {
                                  selected
                                      ? weekdays.add(day)
                                      : weekdays.remove(day);
                                }),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                Text(
                  date == null
                      ? 'Choose weekdays with an available future date.'
                      : 'Next due: ${DateFormat.yMMMd().format(date)}',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Creates one independent task with automatic repeating Off and unchecked subtasks. The completed task stays in history. Missed dates are skipped. No time block or priority is copied. An already scheduled next task is returned unchanged, including its repeat rule.',
                ),
                if (error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: saving || date == null ? null : save,
            child: Text(saving ? 'Saving…' : 'Schedule task'),
          ),
        ],
      ),
    );
  }
}
