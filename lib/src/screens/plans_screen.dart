import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import 'create_plan_screen.dart';
import '../models/plan_template.dart';
import '../widgets/page_header.dart';
import '../widgets/plan_progress_card.dart';
import '../widgets/responsive_content.dart';
import 'plan_details_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PageHeader(
            title: 'Plans',
            subtitle:
              'Start with a common plan, then edit its reading days, duration, time, and translation.',
            action: Tooltip(
              message: 'Create plan',
              child: IconButton(
                onPressed: () => _openCreate(context, controller),
                icon: const Icon(Icons.add),
              ),
            ),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 580
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 14) / columns;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: controller.templates
                    .map(
                      (template) => SizedBox(
                        width: width,
                        child: _TemplateCard(
                          template: template,
                          onTap: () => _openCreate(
                            context,
                            controller,
                            template: template,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 34),
          Text('Saved plans', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          if (controller.plans.isEmpty)
            const Text('No saved plans yet.')
          else
            ...controller.plans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PlanProgressCard(
                  plan: plan,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlanDetailsScreen(
                        controller: controller,
                        planId: plan.id,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openCreate(
    BuildContext context,
    AppController controller, {
    PlanTemplate? template,
  }) {
    if (template == null) {
      controller.beginCustomPlan();
    } else {
      controller.beginTemplate(template);
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Create plan')),
          body: CreatePlanScreen(
            controller: controller,
            template: controller.templateToCreate,
            planToEdit: controller.planToEdit,
          ),
        ),
      ),
    );
  }
}


class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final PlanTemplate template;
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
              CircleAvatar(child: Icon(_iconFor(template.iconName))),
              const SizedBox(height: 16),
              Text(
                template.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(template.description),
              const SizedBox(height: 14),
              Text('${template.defaultDurationDays} calendar-day default'),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String name) => switch (name) {
    'speed' => Icons.speed,
    'menu_book' => Icons.menu_book,
    'auto_stories' => Icons.auto_stories,
    'music_note' => Icons.music_note,
    'history_edu' => Icons.history_edu,
    'favorite' => Icons.favorite,
    'lyrics' => Icons.lyrics,
    'lightbulb' => Icons.lightbulb,
    'account_balance' => Icons.account_balance,
    'psychology' => Icons.psychology,
    'groups' => Icons.groups,
    'campaign' => Icons.campaign,
    _ => Icons.calendar_month,
  };
}
