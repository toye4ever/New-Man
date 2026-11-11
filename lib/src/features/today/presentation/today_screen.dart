import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../tasks/application/task_service.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_editor_dialog.dart';
import '../../tasks/presentation/tasks_screen.dart';
import '../application/today_planner_controller.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    this.taskService,
    this.localDate,
    this.onOpenWord,
    super.key,
  });
  final TaskService? taskService;
  final DateTime? localDate;
  final VoidCallback? onOpenWord;
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  TodayPlannerController? controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  void _setup() {
    final service = widget.taskService;
    if (service != null) {
      controller = TodayPlannerController(
        service,
        selectedDate: widget.localDate,
      );
    }
  }

  @override
  void didUpdateWidget(covariant TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskService != widget.taskService ||
        oldWidget.localDate != widget.localDate) {
      controller?.dispose();
      controller = null;
      _setup();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller?.checkClock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  Future<void> _edit([Task? task]) async {
    final c = controller!;
    if (await showTaskEditor(
      context,
      c.service,
      task: task,
      initialDate: c.selectedDay,
    )) {
      await c.refresh();
    }
  }

  Future<void> _manage() async {
    final c = controller!;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TasksScreen(
          service: c.service,
          localDate: c.followsToday ? null : c.selectedDay,
        ),
      ),
    );
    await c.refresh();
  }

  Future<void> _delete(Task task) async {
    final c = controller!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete ${task.title}?'),
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
    if (confirmed == true) await c.write(() => c.service.deleteTask(task.id));
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Man')),
        body: const Center(
          child: Text('Today is unavailable while Tasks are loading.'),
        ),
      );
    }
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('New Man')),
        body: c.loading && c.view == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Previous day',
                        onPressed: () => c.moveDay(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(DateFormat.yMMMd().format(c.selectedDay)),
                      IconButton(
                        tooltip: 'Next day',
                        onPressed: () => c.moveDay(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                      TextButton(
                        onPressed: c.returnToToday,
                        child: const Text('Today'),
                      ),
                      TextButton.icon(
                        onPressed: c.saving ? null : () => _edit(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add task'),
                      ),
                      TextButton(
                        onPressed: c.saving ? null : _manage,
                        child: const Text('Manage tasks'),
                      ),
                      if (widget.onOpenWord != null)
                        TextButton(
                          onPressed: widget.onOpenWord,
                          child: const Text('Start With God / Open Word'),
                        ),
                    ],
                  ),
                  if (c.loading) const LinearProgressIndicator(),
                  if (c.error != null)
                    Row(
                      children: [
                        Expanded(child: Text(c.error!)),
                        TextButton(
                          onPressed: c.refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  if (!c.loading && c.error == null && c.view != null) ...[
                    _section(
                      'Priorities',
                      c.view!.priorities,
                      'Choose priorities for this day. Three is a helpful starting point.',
                      priority: true,
                    ),
                    _section(
                      'Scheduled',
                      c.view!.scheduled,
                      'No time blocks for this day.',
                    ),
                    _section(
                      'Overdue',
                      c.view!.overdue,
                      'No open overdue tasks.',
                    ),
                    _section(
                      'Due on this day',
                      c.view!.dueToday,
                      'No open tasks due on this day.',
                    ),
                    _section(
                      'Unscheduled',
                      c.view!.unscheduled,
                      'No unscheduled tasks.',
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _section(
    String name,
    List<Task> tasks,
    String empty, {
    bool priority = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(name, style: Theme.of(context).textTheme.titleLarge),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(empty),
          ),
        for (var i = 0; i < tasks.length; i++)
          _row(tasks[i], priority ? i : null),
      ],
    );
  }

  Widget _row(Task task, int? priorityIndex) {
    final c = controller!;
    final block = task.timeBlock;
    String time(int n) => n == 1440
        ? 'end of day'
        : '${(n ~/ 60).toString().padLeft(2, '0')}:${(n % 60).toString().padLeft(2, '0')}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: task.isCompleted,
                  semanticLabel:
                      '${task.isCompleted ? 'Reopen' : 'Complete'} ${task.title}',
                  onChanged: c.saving ? null : (_) => c.toggleCompletion(task),
                ),
                Expanded(
                  child: InkWell(
                    onTap: c.saving ? null : () => _edit(task),
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            if (task.isCompleted) const Text('Completed'),
            if (task.dueDate != null)
              Text('Due: ${DateFormat.yMMMd().format(task.dueDate!)}'),
            if (block != null)
              Text(
                'Block: ${DateFormat.yMMMd().format(block.plannedDate)} ${time(block.startMinutesLocal)}–${time(block.endMinutesLocal)}',
              ),
            if (c.view!.overlappingIds.contains(task.id))
              Text(
                'Overlaps another time block',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Wrap(
              children: [
                TextButton(
                  onPressed: c.saving ? null : () => _edit(task),
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: c.saving ? null : () => c.togglePriority(task),
                  child: Text(
                    c.view!.priorities.any((t) => t.id == task.id)
                        ? 'Remove priority'
                        : 'Make priority',
                  ),
                ),
                if (priorityIndex != null) ...[
                  IconButton(
                    tooltip: 'Move priority up',
                    onPressed: c.saving || priorityIndex == 0
                        ? null
                        : () => c.movePriority(priorityIndex, -1),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    tooltip: 'Move priority down',
                    onPressed:
                        c.saving ||
                            priorityIndex == c.view!.priorities.length - 1
                        ? null
                        : () => c.movePriority(priorityIndex, 1),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                ],
                TextButton(
                  onPressed: c.saving ? null : () => _delete(task),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
