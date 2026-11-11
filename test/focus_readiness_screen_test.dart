import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/focus/application/guard_qualification_service.dart';
import 'package:scripture_planner/src/features/focus/application/guard_readiness_service.dart';
import 'package:scripture_planner/src/features/focus/domain/guard_qualification.dart';
import 'package:scripture_planner/src/features/focus/domain/guard_readiness.dart';
import 'package:scripture_planner/src/features/focus/presentation/focus_screen.dart';

void main() {
  testWidgets('does not probe until the user chooses Check protection', (
    tester,
  ) async {
    final pending = Completer<GuardReadinessReport>();
    final service = _FakeService(<Future<GuardReadinessReport> Function()>[
      () => pending.future,
    ]);

    await tester.pumpWidget(_app(service));

    expect(service.calls, 0);
    expect(find.text('Not checked'), findsOneWidget);
    expect(find.textContaining('Nothing is blocked'), findsOneWidget);
    await tester.tap(find.byKey(const Key('check-protection-button')));
    await tester.pump();
    expect(service.calls, 1);
    expect(find.text('Checking protection status'), findsOneWidget);
    pending.complete(_unqualifiedReport());
    await tester.pump();
    expect(find.text('YouTube Shorts'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('TikTok'), findsOneWidget);
    expect(find.textContaining('not qualified'), findsNWidgets(6));
  });

  testWidgets('surfaces an active native TEST without a readiness probe', (
    tester,
  ) async {
    final readiness = _FakeService(<Future<GuardReadinessReport> Function()>[]);
    final qualification = _FakeQualificationService(
      <Future<GuardQualificationSnapshot> Function()>[
        () => Future.value(_runningQualification()),
        () => Future.value(_runningQualification()),
      ],
    );

    await tester.pumpWidget(
      _app(readiness, qualificationService: qualification),
    );
    await tester.pump();

    expect(readiness.calls, 0);
    expect(find.text('Return to active TEST'), findsOneWidget);
    expect(find.textContaining('TEST is active'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-guard-qualification-button')));
    await tester.pumpAndSettle();
    expect(find.text('Test running'), findsOneWidget);
    expect(readiness.calls, 0);
  });

  testWidgets('shows uncertain recovery and rechecks after route return', (
    tester,
  ) async {
    final readiness = _FakeService(<Future<GuardReadinessReport> Function()>[
      () => Future.value(_unqualifiedReport()),
    ]);
    final qualification = _FakeQualificationService(
      <Future<GuardQualificationSnapshot> Function()>[
        () => Future<GuardQualificationSnapshot>.error(StateError('timeout')),
        () => Future.value(_idleQualification()),
        () => Future.value(_idleQualification()),
      ],
    );
    await tester.pumpWidget(
      _app(readiness, qualificationService: qualification),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Recover whole-app TEST'), findsOneWidget);
    expect(find.textContaining('do not assume'), findsOneWidget);
    expect(readiness.calls, 0);

    await tester.tap(find.byKey(const Key('open-guard-qualification-button')));
    await tester.pumpAndSettle();
    expect(qualification.statusCalls, 2);
    // The route now has conclusive inactive status: this explicit entry probes.
    expect(readiness.calls, 1);
    expect(find.byType(CheckboxListTile), findsNWidgets(4));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(qualification.statusCalls, greaterThanOrEqualTo(3));
    expect(find.text('Open whole-app test'), findsOneWidget);
    expect(readiness.calls, 1);
  });

  testWidgets('inactive route uses injected availability and cancels on back', (
    tester,
  ) async {
    final pending = Completer<GuardReadinessReport>();
    final readiness = _FakeService([
      () => Future.value(
        GuardReadinessReport(
          platform: GuardPlatform.android,
          targets: const [
            GuardTargetReadiness(
              target: GuardTarget.youtubeApp,
              state: GuardReadinessState.versionUnqualified,
            ),
            GuardTargetReadiness(
              target: GuardTarget.instagramApp,
              state: GuardReadinessState.notInstalled,
            ),
          ],
        ),
      ),
      () => pending.future,
    ]);
    await tester.pumpWidget(_app(readiness));
    await tester.pumpAndSettle();
    expect(readiness.calls, 0);
    await tester.tap(find.byKey(const Key('open-guard-qualification-button')));
    await tester.pumpAndSettle();
    expect(readiness.calls, 1);
    expect(find.byKey(const Key('guard-target-youtube_app')), findsOneWidget);
    expect(find.byKey(const Key('guard-target-instagram_app')), findsNothing);
    expect(find.byType(CheckboxListTile), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(readiness.calls, 1);

    await tester.tap(find.byKey(const Key('open-guard-qualification-button')));
    await tester.pumpAndSettle();
    expect(readiness.calls, 2);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(readiness.calls, 2);
    // Leave the backend unresolved through disposal; do not elapse its deadline.
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(_unqualifiedReport());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows retryable unavailable state and retries explicitly', (
    tester,
  ) async {
    final service = _FakeService(<Future<GuardReadinessReport> Function()>[
      () => Future<GuardReadinessReport>.error(StateError('offline')),
      () => Future.value(_unqualifiedReport()),
    ]);
    await tester.pumpWidget(_app(service));

    await tester.tap(find.text('Check protection'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Protection status unavailable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('Nothing was changed'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(service.calls, 2);
    expect(find.text('Qualification status'), findsOneWidget);
  });

  testWidgets('refreshes on resume only after a prior explicit check', (
    tester,
  ) async {
    final service = _FakeService(<Future<GuardReadinessReport> Function()>[
      () => Future.value(_unqualifiedReport()),
      () => Future.value(_unqualifiedReport()),
    ]);
    await tester.pumpWidget(_app(service));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(service.calls, 0);

    await tester.tap(find.text('Check protection'));
    await tester.pump();
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(service.calls, 2);
  });

  testWidgets('ignores completion after disposal', (tester) async {
    final pending = Completer<GuardReadinessReport>();
    final service = _FakeService(<Future<GuardReadinessReport> Function()>[
      () => pending.future,
    ]);
    await tester.pumpWidget(_app(service));
    await tester.tap(find.text('Check protection'));
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    pending.complete(_unqualifiedReport());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('remains scrollable at large text on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeService(<Future<GuardReadinessReport> Function()>[
      () => Future.value(_unqualifiedReport()),
    ]);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _app(service),
      ),
    );
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
    await tester.pump();
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('focus-readiness-scroll')),
      const Offset(0, -300),
    );
    await tester.pump();

    expect(find.text('Instagram Reels'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('TikTok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  GuardReadinessService service, {
  GuardQualificationService? qualificationService,
}) => MaterialApp(
  home: Scaffold(
    body: FocusScreen(
      readinessService: service,
      qualificationService:
          qualificationService ?? _FakeQualificationService.idle(),
    ),
  ),
);

GuardQualificationSnapshot _idleQualification() => GuardQualificationSnapshot(
  platform: GuardPlatform.android,
  status: GuardQualificationStatus.idle,
  remainingMillis: 0,
  selectedTargets: const {},
  serviceConnected: true,
  disclosureAccepted: false,
  detailCode: null,
);

GuardQualificationSnapshot _runningQualification() =>
    GuardQualificationSnapshot(
      platform: GuardPlatform.android,
      status: GuardQualificationStatus.running,
      remainingMillis: 15 * 60 * 1000,
      selectedTargets: const {GuardQualificationTarget.youtubeApp},
      serviceConnected: true,
      disclosureAccepted: true,
      detailCode: null,
    );

GuardReadinessReport _unqualifiedReport() =>
    const GuardReadinessEvaluator().evaluate(
      GuardProbeSnapshot(
        platform: GuardPlatform.android,
        apps: const <GuardInstalledApp>[
          GuardInstalledApp(
            packageName: 'com.google.android.youtube',
            installed: true,
            enabled: true,
            versionName: '20.40.1',
            versionCode: 204001,
          ),
          GuardInstalledApp(
            packageName: 'com.instagram.android',
            installed: true,
            enabled: true,
            versionName: '401.0.0',
            versionCode: 401,
          ),
          GuardInstalledApp(
            packageName: 'com.facebook.katana',
            installed: true,
            enabled: true,
            versionName: '500.0.0',
            versionCode: 500,
          ),
          GuardInstalledApp(
            packageName: 'com.zhiliaoapp.musically',
            installed: true,
            enabled: true,
            versionName: '36.0.0',
            versionCode: 360,
          ),
        ],
      ),
    );

class _FakeService implements GuardReadinessService {
  _FakeService(this.results);

  final List<Future<GuardReadinessReport> Function()> results;
  int calls = 0;

  @override
  Future<GuardReadinessReport> checkReadiness() {
    final result = results[calls]();
    calls++;
    return result;
  }
}

class _FakeQualificationService implements GuardQualificationService {
  _FakeQualificationService(this.results);

  factory _FakeQualificationService.idle() =>
      _FakeQualificationService(<Future<GuardQualificationSnapshot> Function()>[
        () => Future.value(_idleQualification()),
      ]);

  final List<Future<GuardQualificationSnapshot> Function()> results;
  int statusCalls = 0;

  @override
  void cancelPending() {}

  @override
  Future<GuardQualificationSnapshot> getStatus() {
    final index = statusCalls < results.length
        ? statusCalls
        : results.length - 1;
    statusCalls++;
    return results[index]();
  }

  @override
  Future<GuardQualificationSnapshot> start(
    GuardQualificationStartRequest request,
  ) async => _runningQualification();

  @override
  Future<GuardQualificationSnapshot> pause() async => _runningQualification();

  @override
  Future<GuardQualificationSnapshot> resume() async => _runningQualification();

  @override
  Future<GuardQualificationSnapshot> end() async => _idleQualification();

  @override
  Future<void> openAccessibilitySettings() async {}
}
