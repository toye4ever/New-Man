import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/app/developer_tools_policy.dart';
import 'package:scripture_planner/src/app/new_man_app.dart';
import 'package:scripture_planner/src/controllers/app_controller.dart';
import 'package:scripture_planner/src/features/focus/presentation/focus_screen.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';
import 'package:scripture_planner/src/services/plan_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('release and profile builds ignore the developer define', () {
    expect(
      developerGuardToolsEnabled(isDebugMode: false, optedIn: true),
      isFalse,
    );
    expect(
      developerGuardToolsEnabled(isDebugMode: true, optedIn: false),
      isFalse,
    );
    expect(
      developerGuardToolsEnabled(isDebugMode: true, optedIn: true),
      isTrue,
    );
  });

  testWidgets('default beta shell defers Focus without a Guard probe', (
    tester,
  ) async {
    var qualificationCalls = 0;
    var readinessCalls = 0;
    const qualification = MethodChannel(
      'com.newman.newmanapp/guard_qualification',
    );
    const readiness = MethodChannel('com.newman.newmanapp/guard_readiness');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(qualification, (call) async {
        qualificationCalls++;
        return null;
      })
      ..setMockMethodCallHandler(readiness, (call) async {
        readinessCalls++;
        return null;
      });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(qualification, null)
        ..setMockMethodCallHandler(readiness, null);
    });

    final controller = _controller();
    await tester.pumpWidget(NewManApp(controller: controller));

    expect(find.byType(FocusScreen, skipOffstage: false), findsNothing);
    expect(
      find.byKey(
        const Key('open-guard-qualification-button'),
        skipOffstage: false,
      ),
      findsNothing,
    );
    expect(qualificationCalls, 0);
    expect(readinessCalls, 0);

    await tester.tap(find.text('Focus').last);
    await tester.pumpAndSettle();

    expect(find.text('Focus tools are not part of this beta.'), findsOneWidget);
    expect(find.byType(FocusScreen, skipOffstage: false), findsNothing);
    expect(
      find.byKey(const Key('open-guard-qualification-button')),
      findsNothing,
    );
    expect(qualificationCalls, 0);
    expect(readinessCalls, 0);

    await tester.tap(find.text('Word'));
    await tester.pumpAndSettle();
    expect(find.text('Browse Bible'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsAtLeastNWidgets(1));
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.ensureVisible(find.text('Open-source licenses'));
    await tester.tap(find.text('Open-source licenses'));
    await tester.pumpAndSettle();
    expect(find.text('New Man'), findsOneWidget);
    expect(find.text('Licenses'), findsOneWidget);
    expect(qualificationCalls, 0);
    expect(readinessCalls, 0);
  });

  testWidgets('explicit debug opt-in retains the developer Focus route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewManShell(
            controller: _controller(),
            developerToolsOptIn: true,
          ),
        ),
      ),
    );

    expect(find.byType(FocusScreen, skipOffstage: false), findsOneWidget);
    expect(
      find.byKey(
        const Key('open-guard-qualification-button'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}

AppController _controller() => AppController(
  repository: _MemoryPlanRepository(),
  versionRepository: BibleVersionRepository(),
);

class _MemoryPlanRepository implements PlanRepository {
  @override
  Future<List<ReadingPlan>> loadPlans() async => <ReadingPlan>[];

  @override
  Future<void> savePlans(List<ReadingPlan> plans) async {}
}
