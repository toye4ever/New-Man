import '../application/plan_repository.dart';
import '../domain/reading_plan.dart';
import 'local/word_plan_dao.dart';

class DriftPlanRepository implements PlanRepository {
  const DriftPlanRepository(this.dao);

  final WordPlanDao dao;

  @override
  Future<List<ReadingPlan>> loadPlans() => dao.loadPlans();

  @override
  Future<void> savePlans(List<ReadingPlan> plans) => dao.replacePlans(plans);
}
