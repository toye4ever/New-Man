import '../domain/reading_plan.dart';

/// Persistence boundary for Bible reading plans.
abstract interface class PlanRepository {
  Future<List<ReadingPlan>> loadPlans();

  Future<void> savePlans(List<ReadingPlan> plans);
}
