import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/task_service.dart';
import '../domain/task.dart';
import '../domain/task_recurrence.dart';

Future<bool> showTaskEditor(
  BuildContext context,
  TaskService service, {
  Task? task,
  DateTime? initialDate,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskEditorDialog(
        service: service,
        task: task,
        initialDate: initialDate,
      ),
    ) ??
    false;

class TaskEditorDialog extends StatefulWidget {
  const TaskEditorDialog({
    required this.service,
    this.task,
    this.initialDate,
    super.key,
  });
  final TaskService service;
  final Task? task;
  final DateTime? initialDate;
  @override
  State<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _SubtaskDraft {
  _SubtaskDraft({this.id, this.title = '', this.isCompleted = false});

  final String? id;
  String title;
  bool isCompleted;

  TaskSubtask toSubtask(TaskService service) {
    final existingId = id;
    return existingId == null
        ? service.newSubtask(title: title, isCompleted: isCompleted)
        : TaskSubtask(id: existingId, title: title, isCompleted: isCompleted);
  }
}

class _TaskEditorDialogState extends State<TaskEditorDialog> {
  late final TextEditingController title;
  late final TextEditingController start;
  late final TextEditingController end;
  late final List<_SubtaskDraft> subtasks;
  int repeatMode = 0;
  final repeatWeekdays = <int>{};
  bool get canEditRepeat =>
      widget.service.supportsAutomaticRepeats &&
      widget.task?.isCompleted != true &&
      widget.task?.repeatHandled != true;
  TaskRecurrence? get repeatRule => repeatMode == 0
      ? null
      : repeatMode == 1
      ? const TaskRecurrence.daily()
      : TaskRecurrence.weekly(repeatWeekdays);
  late final TextEditingController reminderTime;
  bool reminderEnabled = false;
  DateTime? due;
  DateTime? blockDay;
  bool saving = false;
  bool saved = false;
  String? error;
  final errorKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    final task = widget.task;
    final rule = task?.recurrence;
    repeatMode = rule == null
        ? 0
        : rule.isDaily
        ? 1
        : 2;
    repeatWeekdays.addAll(rule?.weekdays ?? const []);
    subtasks = [
      for (final item in task?.subtasks ?? const <TaskSubtask>[])
        _SubtaskDraft(
          id: item.id,
          title: item.title,
          isCompleted: item.isCompleted,
        ),
    ];
    title = TextEditingController(text: task?.title ?? '');
    due = task?.dueDate;
    reminderEnabled = task?.reminderMinutesLocal != null;
    reminderTime = TextEditingController(
      text: _time(task?.reminderMinutesLocal ?? 540),
    );
    blockDay = task?.timeBlock?.plannedDate;
    start = TextEditingController(
      text: task?.timeBlock == null
          ? ''
          : _time(task!.timeBlock!.startMinutesLocal),
    );
    end = TextEditingController(
      text: task?.timeBlock == null
          ? ''
          : _time(task!.timeBlock!.endMinutesLocal),
    );
  }

  String _time(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
  int? _parse(String s) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s.trim());
    if (match == null) return null;
    final h = int.parse(match[1]!);
    final m = int.parse(match[2]!);
    if (h > 24 || m > 59 || (h == 24 && m != 0)) return null;
    return h * 60 + m;
  }

  @override
  void dispose() {
    reminderTime.dispose();
    title.dispose();
    start.dispose();
    end.dispose();
    super.dispose();
  }

  Future<DateTime?> _date(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(1),
    lastDate: DateTime(9999, 12, 31),
    builder: (context, child) {
      final inset = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              hitTestBehavior: HitTestBehavior.deferToChild,
              child: SizedBox(
                height: constraints.maxHeight < 600
                    ? 600
                    : constraints.maxHeight,
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
  Future<void> _save() async {
    if (saving) return;
    if (title.text.trim().isEmpty) {
      setState(() => error = 'Enter a task title.');
      return;
    }
    if (canEditRepeat && repeatMode == 2 && repeatWeekdays.isEmpty) {
      setState(() => error = 'Choose at least one repeat weekday.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final errorContext = errorKey.currentContext;
        if (mounted && errorContext != null) {
          Scrollable.ensureVisible(errorContext, alignment: 1);
        }
      });
      return;
    }
    final reminderMinutes = reminderEnabled ? _parse(reminderTime.text) : null;
    if (widget.service.supportsInAppReminders &&
        reminderEnabled &&
        (due == null || reminderMinutes == null || reminderMinutes >= 1440)) {
      setState(
        () => error =
            'An in-app reminder needs a due date and a time from 00:00 to 23:59.',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final errorContext = errorKey.currentContext;
        if (mounted && errorContext != null) {
          Scrollable.ensureVisible(errorContext, alignment: 1);
        }
      });
      return;
    }
    final emptySubtask = subtasks.indexWhere(
      (item) => item.title.trim().isEmpty,
    );
    if (emptySubtask != -1) {
      setState(() {
        error = 'Enter a title for subtask ${emptySubtask + 1} or remove it.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final errorContext = errorKey.currentContext;
        if (mounted && errorContext != null) {
          Scrollable.ensureVisible(errorContext, alignment: 1);
        }
      });
      return;
    }
    TaskTimeBlock? block;
    if (blockDay != null) {
      final a = _parse(start.text);
      final b = _parse(end.text);
      if (a == null || b == null || a >= b || a >= 1440) {
        setState(
          () => error =
              'Enter a valid start and end time (HH:MM); end may be 24:00.',
        );
        return;
      }
      block = TaskTimeBlock(
        plannedDate: blockDay!,
        startMinutesLocal: a,
        endMinutesLocal: b,
      );
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final task = widget.task;
      final checklist = [
        for (final item in subtasks) item.toSubtask(widget.service),
      ];
      if (task == null) {
        await widget.service.createTask(
          title: title.text,
          dueDate: due,
          timeBlock: block,
          subtasks: checklist,
          recurrence: canEditRepeat ? repeatRule : null,
          reminderMinutesLocal: reminderMinutes,
        );
      } else {
        await widget.service.saveEdit(
          original: task,
          title: title.text,
          dueDate: due,
          timeBlock: block,
          subtasks: checklist,
          recurrence: canEditRepeat ? repeatRule : task.recurrence,
          editRecurrence: canEditRepeat,
          reminderMinutesLocal: reminderMinutes,
          editReminder: widget.service.supportsInAppReminders,
        );
      }
      if (mounted) {
        setState(() => saved = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } on TaskSubtaskEditConflict {
      if (mounted) {
        setState(() {
          saving = false;
          error =
              'Subtasks changed elsewhere. Reopen this task to edit the current checklist.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'The task could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving || saved,
    child: AlertDialog(
      semanticLabel: widget.task == null ? 'Add task' : 'Edit task',
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                widget.task == null ? 'Add task' : 'Edit task',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: title,
              autofocus: true,
              enabled: !saving,
              decoration: const InputDecoration(labelText: 'Task title'),
            ),
            TextButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      final value = await _date(
                        due ?? widget.initialDate ?? DateTime.now(),
                      );
                      if (value != null && mounted) setState(() => due = value);
                    },
              icon: const Icon(Icons.event),
              label: Text(
                due == null
                    ? 'Add due date (optional)'
                    : 'Due date: ${DateFormat.yMMMd().format(due!)}',
              ),
            ),
            if (due != null)
              TextButton(
                onPressed: saving ? null : () => setState(() => due = null),
                child: const Text('Clear due date'),
              ),
            TextButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      final value = await _date(
                        blockDay ?? widget.initialDate ?? DateTime.now(),
                      );
                      if (value != null && mounted) {
                        setState(() => blockDay = value);
                      }
                    },
              icon: const Icon(Icons.schedule),
              label: Text(
                blockDay == null
                    ? 'Add time block (optional)'
                    : 'Block date: ${DateFormat.yMMMd().format(blockDay!)}',
              ),
            ),
            if (blockDay != null) ...[
              TextField(
                controller: start,
                enabled: !saving,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Start time (HH:MM)',
                ),
              ),
              TextField(
                controller: end,
                enabled: !saving,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'End time (HH:MM, 24:00 is end of day)',
                ),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () => setState(() => blockDay = null),
                child: const Text('Clear time block'),
              ),
            ],
            if (widget.service.supportsInAppReminders) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('In-app reminder'),
                subtitle: const Text(
                  'Shown in Today and Tasks while New Man is open. No background notifications.',
                ),
                value: reminderEnabled,
                onChanged: saving
                    ? null
                    : (value) => setState(() => reminderEnabled = value),
              ),
              if (reminderEnabled)
                TextField(
                  controller: reminderTime,
                  enabled: !saving,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Reminder time (HH:mm)',
                    helperText: 'Requires a due date. Local time, 00:00–23:59.',
                  ),
                ),
            ],
            if (widget.service.supportsAutomaticRepeats) ...[
              const SizedBox(height: 12),
              if (canEditRepeat) ...[
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: repeatMode,
                  decoration: const InputDecoration(
                    labelText: 'Repeat on completion',
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Off')),
                    DropdownMenuItem(value: 1, child: Text('Daily')),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(
                        'Selected weekdays',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: saving
                      ? null
                      : (value) => setState(() => repeatMode = value ?? 0),
                ),
                if (repeatMode == 2)
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
                          selected: repeatWeekdays.contains(day),
                          onSelected: saving
                              ? null
                              : (selected) => setState(() {
                                  selected
                                      ? repeatWeekdays.add(day)
                                      : repeatWeekdays.remove(day);
                                }),
                        ),
                    ],
                  ),
                if (repeatMode != 0)
                  const Text(
                    'Completion creates one next task with this rule and unchecked subtasks. Missed dates are skipped. Set the next open task to Off to stop. An already scheduled next task stays unchanged.',
                  ),
              ] else
                Text(
                  widget.task?.repeatHandled == true
                      ? 'To change or stop repeating, edit the next open occurrence. Reopening this task does not schedule another copy.'
                      : 'Reopen this task to enable or change repeating. If a next task already exists, edit its rule directly.',
                ),
            ],
            if (subtasks.isNotEmpty)
              Semantics(
                header: true,
                child: Text(
                  'Subtasks',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            for (final (index, item) in subtasks.indexed)
              Row(
                key: ObjectKey(item),
                children: [
                  Checkbox(
                    value: item.isCompleted,
                    semanticLabel:
                        '${item.isCompleted ? 'Reopen' : 'Complete'} subtask ${index + 1}',
                    onChanged: saving
                        ? null
                        : (value) =>
                              setState(() => item.isCompleted = value ?? false),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.title,
                      enabled: !saving,
                      onChanged: (value) => item.title = value,
                      decoration: InputDecoration(
                        labelText: 'Subtask ${index + 1}',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove subtask ${index + 1}',
                    onPressed: saving
                        ? null
                        : () => setState(() => subtasks.remove(item)),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            TextButton.icon(
              onPressed: saving
                  ? null
                  : () => setState(() => subtasks.add(_SubtaskDraft())),
              icon: const Icon(Icons.add),
              label: const Text('Add subtask'),
            ),
            if (error != null)
              Semantics(
                key: errorKey,
                liveRegion: true,
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Saving…' : 'Save task'),
        ),
      ],
    ),
  );
}
