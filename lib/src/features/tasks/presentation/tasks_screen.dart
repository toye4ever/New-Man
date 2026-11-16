import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/task_service.dart';
import '../domain/task.dart';
import '../../today/application/today_planner_controller.dart';
import 'task_editor_dialog.dart';
import 'task_repeat_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    required this.service,
    this.localDate,
    this.clock,
    super.key,
  });
  final TaskService service;
  final DateTime? localDate;
  final DateTime Function()? clock;
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with WidgetsBindingObserver {
  late ManageTasksController controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  void _setup() => controller = ManageTasksController(
    widget.service,
    selectedDate: widget.localDate,
    clock: widget.clock,
  );
  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service ||
        oldWidget.localDate != widget.localDate ||
        oldWidget.clock != widget.clock) {
      controller.dispose();
      _setup();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller.checkClock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  Future<void> write(Future<bool> Function() action) async {
    if (!await action() && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The task could not be saved. Please try again.'),
        ),
      );
    }
  }

  Future<void> edit([Task? task]) async {
    if (await showTaskEditor(
      context,
      widget.service,
      task: task,
      initialDate: controller.day,
    )) {
      await controller.refresh();
    }
  }

  Future<void> repeat(Task task) async {
    final next = await showDialog<Task>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskRepeatDialog(
        service: widget.service,
        task: task,
        today: (widget.clock ?? DateTime.now)(),
      ),
    );
    if (next != null && mounted) {
      await controller.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next.dueDate == null
                ? 'Next task ready: ${next.title}'
                : 'Next task ready: ${DateFormat.yMMMd().format(next.dueDate!)}',
          ),
        ),
      );
    }
  }

  Future<void> delete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          task.subtasks.isEmpty
              ? 'Delete ${task.title}?'
              : 'Delete ${task.title} and its subtasks?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await write(
        () => controller.write(() => widget.service.deleteTask(task.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final tasks = controller.tasks;
      final priorities = controller.priorities;
      final saving = controller.saving;
      final loading = controller.loading;
      final error = controller.error;
      final dateLabel = DateFormat.yMMMd().format(controller.day);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tasks'),
          actions: [
            TextButton.icon(
              onPressed: saving ? null : () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Add task'),
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error),
                    TextButton(
                      onPressed: controller.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Priorities for $dateLabel'),
                  if (tasks.isEmpty)
                    const Text(
                      'No tasks yet. Add a task with an optional due date.',
                    ),
                  for (final task in tasks)
                    ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        semanticLabel:
                            '${task.isCompleted ? 'Reopen' : 'Complete'} ${task.title}',
                        onChanged: saving
                            ? null
                            : (value) => write(
                                () => controller.write(
                                  () => widget.service.setCompleted(
                                    task,
                                    value ?? false,
                                  ),
                                ),
                              ),
                      ),
                      title: Text(task.title),
                      subtitle: task.dueDate == null && task.subtasks.isEmpty
                          ? null
                          : Text(
                              [
                                if (task.dueDate != null)
                                  'Due ${DateFormat.yMMMd().format(task.dueDate!)}',
                                if (task.subtasks.isNotEmpty)
                                  '${task.completedSubtaskCount} of ${task.subtasks.length} subtasks complete',
                              ].join(' • '),
                            ),
                      onTap: saving ? null : () => edit(task),
                      trailing: Wrap(
                        children: [
                          if (task.isCompleted &&
                              widget.service.supportsExplicitRepeats)
                            IconButton(
                              tooltip:
                                  'Schedule next occurrence of ${task.title}',
                              icon: const Icon(Icons.repeat),
                              onPressed: saving ? null : () => repeat(task),
                            ),
                          IconButton(
                            tooltip: priorities.contains(task.id)
                                ? 'Remove priority for $dateLabel'
                                : 'Make priority for $dateLabel',
                            icon: Icon(
                              priorities.contains(task.id)
                                  ? Icons.star
                                  : Icons.star_border,
                            ),
                            onPressed: saving
                                ? null
                                : () => write(
                                    () => controller.togglePriority(task),
                                  ),
                          ),
                          IconButton(
                            tooltip: 'Delete ${task.title}',
                            onPressed: saving ? null : () => delete(task),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      );
    },
  );
}
