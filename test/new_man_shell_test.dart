import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/app/new_man_app.dart';
import 'package:scripture_planner/src/controllers/app_controller.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';
import 'package:scripture_planner/src/services/plan_repository.dart';

void main() {
  testWidgets('shows the New Man destinations and opens Word', (tester) async {
    final controller = AppController(
      repository: _MemoryPlanRepository(),
      versionRepository: BibleVersionRepository(),
    );

    await tester.pumpWidget(NewManApp(controller: controller));

    expect(find.text('New Man'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Word'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Accountability'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('Word'));
    await tester.pumpAndSettle();

    expect(find.text('Browse Bible'), findsOneWidget);
    expect(find.text('Word'), findsAtLeastNWidgets(1));
    expect(find.text('Plans'), findsOneWidget);
    expect(find.text('Create'), findsNothing);
    expect(find.text('Bible'), findsOneWidget);
    expect(find.text('Versions'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);

    await tester.tap(find.text('Plans').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Create plan'), findsOneWidget);

    await tester.tap(find.byTooltip('Create plan'));
    await tester.pumpAndSettle();
    expect(find.text('Create a custom plan'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Saved plans'), findsOneWidget);
  });
}

class _MemoryPlanRepository implements PlanRepository {
  @override
  Future<List<ReadingPlan>> loadPlans() async => <ReadingPlan>[];

  @override
  Future<void> savePlans(List<ReadingPlan> plans) async {}
}
