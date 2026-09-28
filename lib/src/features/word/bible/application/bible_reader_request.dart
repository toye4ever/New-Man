import '../../../../models/reading_plan.dart';
import '../../../../models/scripture_reference.dart';

class BibleReaderRequest {
  BibleReaderRequest({
    required Iterable<ScriptureReference> references,
    required this.initialTranslation,
    this.planProgress,
    this.goToTarget,
    this.expandGoTo = false,
  }) : references = List<ScriptureReference>.unmodifiable(references);

  factory BibleReaderRequest.manual({
    required Iterable<ScriptureReference> references,
    BibleTranslation initialTranslation = BibleTranslation.kjv,
  }) {
    return BibleReaderRequest(
      references: references,
      initialTranslation: initialTranslation,
    );
  }

  factory BibleReaderRequest.fromPlanReading({
    required Iterable<ScriptureReference> references,
    required BibleTranslation initialTranslation,
    required String planId,
    required int assignmentIndex,
  }) {
    return BibleReaderRequest(
      references: references,
      initialTranslation: initialTranslation,
      planProgress: PlanReadingProgressTarget(
        planId: planId,
        assignmentIndex: assignmentIndex,
      ),
    );
  }

  final List<ScriptureReference> references;
  final BibleTranslation initialTranslation;
  final PlanReadingProgressTarget? planProgress;
  /// A non-persisted verse range to reveal after the containing chapter loads.
  final ScriptureReference? goToTarget;
  final bool expandGoTo;
}

class PlanReadingProgressTarget {
  const PlanReadingProgressTarget({
    required this.planId,
    required this.assignmentIndex,
  });

  final String planId;
  final int assignmentIndex;
}
