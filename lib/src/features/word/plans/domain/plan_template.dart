import '../../bible/domain/scripture_reference.dart';

class PlanTemplate {
  const PlanTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.defaultDurationDays,
    required this.references,
    required this.iconName,
  });

  final String id;
  final String title;
  final String description;
  final int defaultDurationDays;
  final List<ScriptureReference> references;
  final String iconName;
}
