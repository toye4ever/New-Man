import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../models/reading_plan.dart';
import '../features/word/bible/application/bible_reader_request.dart';
import 'create_plan_screen.dart';
import 'reader_screen.dart';

class PlanDetailsScreen extends StatelessWidget {
  const PlanDetailsScreen({
    required this.controller,
    required this.planId,
    super.key,
  });

  final AppController controller;
  final String planId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final plan = controller.plans
            .where((item) => item.id == planId)
            .firstOrNull;
        if (plan == null) {
          return const Scaffold(
            body: Center(child: Text('This plan no longer exists.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(plan.title),
            actions: <Widget>[
              IconButton(
                tooltip: 'Edit entire plan',
                onPressed: () {
                  controller.beginEditPlan(plan);
                  _openEditor(context, controller);
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete plan',
                onPressed: () => _confirmDelete(context, plan),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: plan.assignments.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _PlanSummary(
                  plan: plan,
                  onCatchUp: () => _catchUp(context, plan),
                  onEdit: () {
                    controller.beginEditPlan(plan);
                    _openEditor(context, controller);
                  },
                );
              }
              final assignmentIndex = index - 1;
              final reading = plan.assignments[assignmentIndex];
              final translation = reading.effectiveTranslation(
                plan.defaultTranslation,
              );
              return Card(
                child: ListTile(
                  leading: Checkbox(
                    value: reading.completed,
                    onChanged: (_) =>
                        controller.toggleReading(plan.id, assignmentIndex),
                  ),
                  title: Text(
                    reading.references.map((item) => item.display).join(', '),
                  ),
                  subtitle: Text(
                    '${DateFormat.yMMMd().format(reading.date)} • '
                    '${translation.shortLabel}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReaderScreen(
                        controller: controller,
                        request: BibleReaderRequest.fromPlanReading(
                          references: reading.references,
                          initialTranslation: translation,
                          planId: plan.id,
                          assignmentIndex: assignmentIndex,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openEditor(BuildContext context, AppController controller) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Edit plan')),
          body: CreatePlanScreen(
            controller: controller,
            template: controller.templateToCreate,
            planToEdit: controller.planToEdit,
          ),
        ),
      ),
    );
  }

  Future<void> _catchUp(BuildContext context, ReadingPlan plan) async {
    final remaining = plan.assignments.where((item) => !item.completed).length;
    if (remaining == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This plan is already complete.')),
      );
      return;
    }

    try {
      final preview = controller.previewCatchUpPlan(plan.id);
      final currentAverage = plan.assignments.isEmpty
          ? 0.0
          : remaining / plan.assignments.length;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Catch Me Up preview'),
          content: Text(
            '${preview.unfinishedReadingCount} unfinished readings\n'
            '${preview.eligibleDayCount} selected reading days remaining\n\n'
            'Current average: ${currentAverage.toStringAsFixed(1)} readings/day\n'
            'Proposed average: ${preview.proposedAverage.toStringAsFixed(1)} readings/day\n\n'
            'Finish date remains ${DateFormat.yMMMd().format(preview.targetEndDate)}.\n\n'
            '${preview.proposedReadingCount == 0 ? 'No redistribution is needed.' : 'The proposed schedule keeps completed readings in place and preserves source order.'}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Redistribute'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await controller.applyCatchUpPreview(preview);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The unfinished readings were spread across the remaining dates.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _confirmDelete(BuildContext context, ReadingPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete plan?'),
        content: Text('Delete ${plan.title} and its local progress?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await controller.deletePlan(plan.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({
    required this.plan,
    required this.onCatchUp,
    required this.onEdit,
  });

  final ReadingPlan plan;
  final VoidCallback onCatchUp;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Chip(
                  label: Text('${plan.defaultTranslation.shortLabel} default'),
                ),
                Text(
                  '${plan.completedCount}/${plan.assignments.length} complete',
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: plan.progress),
            const SizedBox(height: 12),
            Text(
              '${DateFormat.yMMMd().format(plan.startDate)} – '
              '${DateFormat.yMMMd().format(plan.endDate)}',
            ),
            const SizedBox(height: 4),
            Text('Reminder: ${plan.reminderTime}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: onCatchUp,
                  icon: const Icon(Icons.update),
                  label: const Text('Catch me up'),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit plan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
