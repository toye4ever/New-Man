import 'reading_plan.dart';

/// A proposed schedule. It is deliberately a value object: displaying one
/// never writes a plan, and applying it is an explicit application action.
class SchedulePreview {
  const SchedulePreview({
    required this.planId,
    required this.assignments,
    required this.unfinishedReadingCount,
    required this.eligibleDayCount,
    required this.targetEndDate,
  });

  final String planId;
  final List<ScheduledReading> assignments;
  final int unfinishedReadingCount;
  final int eligibleDayCount;
  final DateTime targetEndDate;

  int get proposedReadingCount =>
      assignments.where((assignment) => !assignment.completed).length;

  double get proposedAverage => eligibleDayCount == 0
      ? 0
      : unfinishedReadingCount / eligibleDayCount;
}
