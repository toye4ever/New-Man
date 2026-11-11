import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../features/word/bible/application/bible_reader_request.dart';
import '../features/word/bible/domain/scripture_reference.dart';
import '../models/reading_plan.dart';
import '../widgets/page_header.dart';
import '../widgets/plan_progress_card.dart';
import '../widgets/responsive_content.dart';
import 'plan_details_screen.dart';
import 'reader_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final position = controller.continueReadingPosition;
    final continuity = _findPlanContinuity(DateTime.now());
    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PageHeader(
            title: 'Word',
            subtitle:
                'Scripture practice continues here.',
          ),
          if (position != null) ...<Widget>[
            const SizedBox(height: 28),
            Text(
              'CONTINUE READING',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: <Widget>[
                    const CircleAvatar(
                      radius: 26,
                      child: Icon(Icons.auto_stories_outlined),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${position.book} ${position.chapter}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(position.translation.shortLabel),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _continueReading(context),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
          Text('PLAN CONTINUITY', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          if (continuity != null)
            _PlanContinuityCard(
              item: continuity,
              controller: controller,
            )
          else if (controller.plans.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text('A plan can help guide your Scripture reading.'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => controller.selectWordDestination(1),
                      icon: const Icon(Icons.library_books_outlined),
                      label: const Text('View Plans'),
                    ),
                  ],
                ),
              ),
            )
          else
            PlanProgressCard(
              plan: controller.plans.first,
              onTap: () => _openPlan(context, controller.plans.first.id),
            ),
          const SizedBox(height: 30),
          Text('SAVED SCRIPTURE', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.bookmark_outline)),
              title: const Text('Saved Scripture'),
              subtitle: const Text('Bookmarks, highlights, notes, and history.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => controller.selectWordDestination(4),
            ),
          ),
          const SizedBox(height: 30),
          Text('BIBLE', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.menu_book_outlined)),
              title: const Text('Browse Bible'),
              subtitle: const Text('Choose a book and chapter. No plan is required.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => controller.selectWordDestination(2),
            ),
          ),
        ],
      ),
    );
  }

  void _continueReading(BuildContext context) {
    final position = controller.continueReadingPosition;
    if (position == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(
          controller: controller,
          request: BibleReaderRequest.manual(
            references: <ScriptureReference>[
              ScriptureReference(
                book: position.book,
                startChapter: position.chapter,
              ),
            ],
            initialTranslation: position.translation,
          ),
        ),
      ),
    );
  }

  void _openPlan(BuildContext context, String planId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PlanDetailsScreen(controller: controller, planId: planId),
      ),
    );
  }

  _PlanContinuity? _findPlanContinuity(DateTime today) {
    _PlanContinuity? nearest;
    for (final plan in controller.plans) {
      final resume = plan.lastReadAssignmentIndex;
      if (resume != null) {
        return _PlanContinuity(plan: plan, reading: plan.assignments[resume],
            assignmentIndex: resume);
      }
      for (var index = 0; index < plan.assignments.length; index++) {
        final reading = plan.assignments[index];
        if (DateUtils.isSameDay(reading.date, today) && !reading.completed) {
          return _PlanContinuity(
            plan: plan,
            reading: reading,
            assignmentIndex: index,
          );
        }
        if (!reading.completed &&
            reading.date.isAfter(DateTime(today.year, today.month, today.day)) &&
            (nearest == null || reading.date.isBefore(nearest.reading.date))) {
          nearest = _PlanContinuity(
            plan: plan,
            reading: reading,
            assignmentIndex: index,
          );
        }
      }
    }
    return nearest;
  }
}

class _PlanContinuityCard extends StatelessWidget {
  const _PlanContinuityCard({
    required this.item,
    required this.controller,
  });

  final _PlanContinuity item;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final references = item.reading.references
        .map((item) => item.display)
        .join(', ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(item.plan.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(references, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(DateFormat.yMMMd().format(item.reading.date)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlanDetailsScreen(controller: controller,
                    planId: item.plan.id, initialAssignmentIndex:
                        item.plan.lastReadAssignmentIndex ?? item.assignmentIndex),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continue Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanContinuity {
  const _PlanContinuity({
    required this.plan,
    required this.reading,
    required this.assignmentIndex,
  });

  final ReadingPlan plan;
  final ScheduledReading reading;
  final int assignmentIndex;
}
