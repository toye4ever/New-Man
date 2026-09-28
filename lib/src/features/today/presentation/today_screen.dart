import 'package:flutter/material.dart';

import '../../../shared/widgets/milestone_placeholder.dart';
import '../../tasks/application/task_service.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({this.taskService, this.localDate, super.key});

  final TaskService? taskService;
  final DateTime? localDate;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late final Future<int>? _taskCount;

  @override
  void initState() {
    super.initState();
    final date = widget.localDate ?? DateTime.now();
    _taskCount = widget.taskService
        ?.loadOpenTasksDueBy(date)
        .then((tasks) => tasks.length);
  }

  @override
  Widget build(BuildContext context) {
    final taskCount = _taskCount;
    if (taskCount != null) {
      return FutureBuilder<int>(
        future: taskCount,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const MilestonePlaceholder(
              title: 'New Man',
              description: 'Tasks could not be loaded. Try reopening Today.',
              icon: Icons.wb_sunny_outlined,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return MilestonePlaceholder(
            title: 'New Man',
            description: snapshot.data == 0
                ? 'No open Tasks are due today.'
                : '${snapshot.data} open task${snapshot.data == 1 ? '' : 's'} due by today.',
            icon: Icons.wb_sunny_outlined,
          );
        },
      );
    }
    return const MilestonePlaceholder(
      title: 'New Man',
      description:
          'Today will become your daily place for Tasks and priorities. Your existing Bible experience is available in Word.',
      icon: Icons.wb_sunny_outlined,
    );
  }
}
