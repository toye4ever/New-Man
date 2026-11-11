import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/task_service.dart';
import '../domain/task.dart';

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

class _TaskEditorDialogState extends State<TaskEditorDialog> {
  late final TextEditingController title;
  late final TextEditingController start;
  late final TextEditingController end;
  DateTime? due;
  DateTime? blockDay;
  bool saving = false;
  bool saved = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final task = widget.task;
    title = TextEditingController(text: task?.title ?? '');
    due = task?.dueDate;
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
      if (task == null) {
        await widget.service.createTask(
          title: title.text,
          dueDate: due,
          timeBlock: block,
        );
      } else {
        await widget.service.saveEdit(
          original: task,
          title: title.text,
          dueDate: due,
          timeBlock: block,
        );
      }
      if (mounted) {
        setState(() => saved = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, true);
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
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
