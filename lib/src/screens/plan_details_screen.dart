import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../models/reading_plan.dart';
import '../features/word/bible/application/bible_reader_request.dart';
import 'create_plan_screen.dart';
import 'reader_screen.dart';

class PlanDetailsScreen extends StatefulWidget {
  const PlanDetailsScreen({
    required this.controller,
    required this.planId,
    this.initialAssignmentIndex,
    super.key,
  });

  final AppController controller;
  final String planId;
  final int? initialAssignmentIndex;

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  final _scroll = ScrollController();
  final _summaryKey = GlobalKey();
  bool _initialScrollScheduled = false;
  AppController get controller => widget.controller;
  String get planId => widget.planId;
  double _rowExtent = 112;
  double _summaryHeight = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jumpTo(int index, {bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final box = _summaryKey.currentContext?.findRenderObject();
      if (box is RenderBox) _summaryHeight = box.size.height;
      final plan = controller.plans.where((p) => p.id == planId).firstOrNull;
      final preceding = plan == null
          ? index * _rowExtent
          : plan.assignments
                .take(index)
                .fold<double>(
                  0,
                  (sum, day) =>
                      sum +
                      _rowExtent +
                      day.chapters.length * 56 * (_rowExtent / 112),
                );
      final offset = (_summaryHeight + preceding).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      if (animate) {
        _scroll.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(offset);
      }
    });
  }

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

        _rowExtent =
            112 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2.5);
        if (!_initialScrollScheduled) {
          _initialScrollScheduled = true;
          final target = widget.initialAssignmentIndex;
          if (target != null && plan.assignments.isNotEmpty) {
            _jumpTo(
              target.clamp(0, plan.assignments.length - 1),
              animate: false,
            );
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(plan.title),
            actions: <Widget>[
              TextButton(
                onPressed: plan.assignments.isEmpty
                    ? null
                    : () => _jumpTo(plan.progressAssignmentIndex),
                child: const Text('Return to progress'),
              ),
              IconButton(
                tooltip: 'Delete plan',
                onPressed: () => _confirmDelete(context, plan),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  key: _summaryKey,
                  padding: const EdgeInsets.all(20),
                  child: _PlanSummary(
                    plan: plan,
                    onCatchUp: () => _catchUp(context, plan),
                    onEdit: () {
                      controller.beginEditPlan(plan);
                      _openEditor(context, controller);
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverVariedExtentList(
                  itemExtentBuilder: (index, _) =>
                      _rowExtent +
                      plan.assignments[index].chapters.length *
                          56 *
                          (_rowExtent / 112),
                  delegate: SliverChildBuilderDelegate((
                    context,
                    assignmentIndex,
                  ) {
                    final reading = plan.assignments[assignmentIndex];
                    final translation = reading.effectiveTranslation(
                      plan.defaultTranslation,
                    );
                    return Card(
                      key: ValueKey('plan-day-$assignmentIndex'),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Checkbox(
                              value: reading.completed,
                              onChanged: (_) async {
                                try {
                                  await controller.toggleReading(
                                    plan.id,
                                    assignmentIndex,
                                  );
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not save reading progress. Please retry.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            title: Text(
                              'Day ${assignmentIndex + 1}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${reading.completedChapterCount}/${reading.chapters.length} chapters · ${DateFormat.yMMMd().format(reading.date)} • '
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
                                    initialChapterIndex: plan
                                        .readingStartChapterIndex(
                                          assignmentIndex,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          LinearProgressIndicator(
                            value: reading.chapters.isEmpty
                                ? 0
                                : reading.completedChapterCount /
                                      reading.chapters.length,
                          ),
                          for (
                            var chapterIndex = 0;
                            chapterIndex < reading.chapters.length;
                            chapterIndex++
                          )
                            ListTile(
                              dense: true,
                              minTileHeight: 56 * (_rowExtent / 112),
                              title: Text(
                                reading.chapters[chapterIndex].display,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                reading.isChapterCompleted(
                                      reading.chapters[chapterIndex],
                                    )
                                    ? Icons.check
                                    : Icons.chevron_right,
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ReaderScreen(
                                    controller: controller,
                                    request: BibleReaderRequest.fromPlanReading(
                                      references: reading.references,
                                      initialTranslation: translation,
                                      planId: plan.id,
                                      assignmentIndex: assignmentIndex,
                                      initialChapterIndex: chapterIndex,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }, childCount: plan.assignments.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
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
            onSaved: () {
              Navigator.of(context).pop(); // Editor.
              Navigator.of(context).pop(); // Details, back to Plans.
            },
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
                Text(
                  '${plan.completedChapterCount}/${plan.totalChapterCount} chapters',
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
