import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reading_plan.dart';

class PlanProgressCard extends StatelessWidget {
  const PlanProgressCard({required this.plan, required this.onTap, super.key});

  final ReadingPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      plan.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Chip(label: Text(plan.defaultTranslation.shortLabel)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${plan.completedCount} of ${plan.assignments.length} readings completed',
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: plan.progress),
              const SizedBox(height: 10),
              Text(
                'Finishes ${DateFormat.yMMMd().format(plan.endDate)} • '
                'Reminder ${plan.reminderTime}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
