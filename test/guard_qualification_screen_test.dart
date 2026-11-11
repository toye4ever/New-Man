import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/focus/application/guard_qualification_controller.dart';
import 'package:scripture_planner/src/features/focus/application/guard_qualification_service.dart';
import 'package:scripture_planner/src/features/focus/application/guard_readiness_service.dart';
import 'package:scripture_planner/src/features/focus/domain/guard_qualification.dart';
import 'package:scripture_planner/src/features/focus/domain/guard_readiness.dart';
import 'package:scripture_planner/src/features/focus/presentation/guard_qualification_screen.dart';

void main() {
  GuardReadinessReport availabilityReport(
    Map<GuardTarget, GuardReadinessState> states,
  ) => GuardReadinessReport(
    platform: GuardPlatform.android,
    targets: GuardTarget.values.map(
      (target) => GuardTargetReadiness(
        target: target,
        state: states[target] ?? GuardReadinessState.versionUnqualified,
      ),
    ),
  );

  testWidgets(
    'stale rows survive checking and timeout with selection visible',
    (tester) async {
      var now = DateTime.utc(2026);
      final availability = _Availability()
        ..report = availabilityReport({
          GuardTarget.tiktokApp: GuardReadinessState.notInstalled,
        });
      final controller = GuardQualificationController(
        service: _ScreenService(),
        readinessService: availability,
        availabilityClock: () => now,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      controller.acceptDisclosure();
      controller.setSelected(GuardQualificationTarget.youtubeApp, true);
      now = now.add(const Duration(seconds: 31));
      await controller.refreshStatus(); // Render ageing without a package poll.
      await tester.pump();
      expect(_checkbox(tester, 'youtube_app').value, isTrue);
      expect(_checkbox(tester, 'youtube_app').onChanged, isNull);
      expect(find.textContaining('stale'), findsOneWidget);
      expect(find.byKey(const Key('guard-target-tiktok_app')), findsNothing);
      expect(availability.calls, 1);
      final pending = Completer<GuardReadinessReport>();
      availability.response = () => pending.future;
      final refresh = controller.refreshAvailability();
      await tester.pump();
      expect(_checkbox(tester, 'youtube_app').value, isTrue);
      expect(find.textContaining('Checking installed'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await refresh;
      await tester.pump();
      expect(_checkbox(tester, 'youtube_app').value, isTrue);
      expect(_checkbox(tester, 'youtube_app').onChanged, isNull);
      expect(find.textContaining('not authorized'), findsOneWidget);
      expect(controller.canStart, isFalse);
      expect(controller.canOpenAccessibilitySettings, isTrue);
      pending.complete(availabilityReport({}));
      await tester.pump();
      expect(find.byKey(const Key('guard-target-tiktok_app')), findsNothing);
    },
  );

  testWidgets('stale draft confirmed Start shows checking then starts once', (
    tester,
  ) async {
    var now = DateTime.utc(2026);
    final availability = _Availability();
    final service = _ScreenService();
    final controller = GuardQualificationController(
      service: service,
      readinessService: availability,
      availabilityClock: () => now,
      pollingInterval: null,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    controller.acceptDisclosure();
    controller.setSelected(GuardQualificationTarget.youtubeApp, true);
    now = now.add(const Duration(seconds: 31));
    await controller.refreshStatus();
    await tester.pump();
    await _scrollTo(tester, find.byKey(const Key('start-guard-test-button')));
    await tester.tap(find.byKey(const Key('start-guard-test-button')));
    await tester.pumpAndSettle();
    final pending = Completer<GuardReadinessReport>();
    availability.response = () => pending.future;
    await tester.tap(find.byKey(const Key('confirm-start-button')));
    await tester.pumpAndSettle();
    expect(find.text('Checking apps before Start...'), findsOneWidget);
    expect(service.startCalls, 0);
    expect(controller.startChecking, isTrue);
    pending.complete(availabilityReport({}));
    await tester.pumpAndSettle();
    expect(service.startCalls, 1);
    expect(find.text('Test running'), findsOneWidget);
  });

  testWidgets(
    'confirmation for changed draft cannot start a different selection',
    (tester) async {
      final service = _ScreenService();
      final controller = _controller(service);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      controller.acceptDisclosure();
      controller.setSelected(GuardQualificationTarget.youtubeApp, true);
      await _scrollTo(tester, find.byKey(const Key('start-guard-test-button')));
      await tester.tap(find.byKey(const Key('start-guard-test-button')));
      await tester.pumpAndSettle();
      controller.setSelected(GuardQualificationTarget.instagramApp, true);
      await tester.tap(find.byKey(const Key('confirm-start-button')));
      await tester.pumpAndSettle();
      expect(service.startCalls, 0);
    },
  );

  testWidgets(
    'availability reconciliation rejects old confirmation and requires fresh one',
    (tester) async {
      final service = _ScreenService();
      final availability = _Availability();
      final controller = GuardQualificationController(
        service: service,
        readinessService: availability,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      controller.acceptDisclosure();
      controller.setSelected(GuardQualificationTarget.youtubeApp, true);
      controller.setSelected(GuardQualificationTarget.instagramApp, true);
      await _scrollTo(tester, find.byKey(const Key('start-guard-test-button')));
      await tester.tap(find.byKey(const Key('start-guard-test-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('YouTube and Instagram apps'), findsOneWidget);

      availability.report = availabilityReport({
        GuardTarget.youtubeApp: GuardReadinessState.notInstalled,
      });
      await controller.refreshOnReturn();
      await tester.pumpAndSettle();
      expect(controller.selection, {GuardQualificationTarget.instagramApp});
      expect(find.textContaining('YouTube and Instagram apps'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-start-button')));
      await tester.pumpAndSettle();
      expect(service.startCalls, 0);

      await tester.tap(find.byKey(const Key('start-guard-test-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('The entire Instagram app'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-start-button')));
      await tester.pumpAndSettle();
      expect(service.startCalls, 1);
      expect(service.current.selectedTargets, {
        GuardQualificationTarget.instagramApp,
      });
    },
  );

  testWidgets('absent disabled and unknown apps have no selectable checkbox', (
    tester,
  ) async {
    final availability = _Availability()
      ..report = availabilityReport({
        GuardTarget.instagramApp: GuardReadinessState.notInstalled,
        GuardTarget.facebookApp: GuardReadinessState.disabled,
        GuardTarget.tiktokApp: GuardReadinessState.versionUnknown,
      });
    final controller = GuardQualificationController(
      service: _ScreenService(),
      readinessService: availability,
      pollingInterval: null,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(find.byKey(const Key('guard-target-youtube_app')), findsOneWidget);
    for (final id in ['instagram_app', 'facebook_app', 'tiktok_app']) {
      expect(find.byKey(Key('guard-target-$id')), findsNothing);
    }
    expect(find.textContaining('does not mean qualified'), findsOneWidget);
  });

  testWidgets(
    'empty availability explains install and refresh without losing Settings',
    (tester) async {
      final availability = _Availability()
        ..report = availabilityReport({
          for (final target in GuardTarget.values)
            target: GuardReadinessState.notInstalled,
        });
      final controller = GuardQualificationController(
        service: _ScreenService(),
        readinessService: availability,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.textContaining('None of the four'), findsOneWidget);
      expect(controller.canStart, isFalse);
      expect(controller.canOpenAccessibilitySettings, isTrue);
      await _scrollTo(
        tester,
        find.byKey(const Key('refresh-guard-availability-button')),
      );
      await tester.tap(
        find.byKey(const Key('refresh-guard-availability-button')),
      );
      await tester.pumpAndSettle();
      expect(availability.calls, 2);
    },
  );

  testWidgets(
    'return from Settings refreshes choices and newly installed stays unchecked',
    (tester) async {
      final availability = _Availability()
        ..report = availabilityReport({
          GuardTarget.instagramApp: GuardReadinessState.notInstalled,
        });
      final controller = GuardQualificationController(
        service: _ScreenService(),
        readinessService: availability,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      controller.acceptDisclosure();
      await tester.tap(find.byKey(const Key('guard-target-youtube_app')));
      availability.report = availabilityReport({
        GuardTarget.youtubeApp: GuardReadinessState.notInstalled,
      });
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(availability.calls, 2);
      expect(find.byKey(const Key('guard-target-youtube_app')), findsNothing);
      expect(_checkbox(tester, 'instagram_app').value, isFalse);
      expect(controller.selection, isEmpty);
      expect(controller.disclosureAccepted, isTrue);
    },
  );

  testWidgets(
    'recovered active then uncertain lease retains End and Settings during late probe failure',
    (tester) async {
      final availability = _Availability();
      final service = _ScreenService();
      final controller = GuardQualificationController(
        service: service,
        readinessService: availability,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();
      final pending = Completer<GuardReadinessReport>();
      availability.response = () => pending.future;
      final refresh = controller.refreshAvailability();
      await controller.refreshStatus();
      service.current = _running();
      await controller.refreshStatus();
      service.statusError = StateError('uncertain status');
      await controller.refreshOnReturn();
      await tester.pump();
      expect(find.byKey(const Key('end-guard-test-button')), findsOneWidget);
      expect(controller.canOpenAccessibilitySettings, isTrue);
      expect(availability.calls, 2);
      pending.completeError(StateError('unavailable'));
      await refresh;
      await tester.pump();
      expect(controller.selection, {GuardQualificationTarget.youtubeApp});
      expect(controller.canOpenAccessibilitySettings, isTrue);
      expect(find.byKey(const Key('end-guard-test-button')), findsOneWidget);
      service.statusError = null;
      await _scrollTo(tester, find.byKey(const Key('end-guard-test-button')));
      await tester.tap(find.byKey(const Key('end-guard-test-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-end-button')));
      await tester.pumpAndSettle();
      expect(service.endCalls, 1);
      // T20 keeps last-confirmed rows visible after recovery, without authority.
      expect(find.byType(CheckboxListTile), findsNWidgets(4));
      expect(_checkbox(tester, 'youtube_app').onChanged, isNull);
      expect(find.textContaining('stale'), findsOneWidget);
    },
  );

  testWidgets('disclosure gates enable-settings without starting a test', (
    tester,
  ) async {
    final service = _ScreenService(initial: _idle(connected: false));
    final controller = _controller(service);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pump();

    // Disconnected native state permits disclosure/Settings recovery only.
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('start-guard-test-button')),
          )
          .onPressed,
      isNull,
    );

    await _scrollTo(tester, find.byKey(const Key('review-disclosure-button')));
    await tester.tap(find.byKey(const Key('review-disclosure-button')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('app-change identities from other apps'),
      findsOneWidget,
    );
    expect(find.textContaining('reads no screen content'), findsOneWidget);
    expect(
      find.textContaining('saves no app history and sends nothing'),
      findsOneWidget,
    );
    expect(
      find.textContaining('YouTube, Instagram, Facebook, or TikTok'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Enabling the service alone does not'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('decline-disclosure-button')));
    await tester.pumpAndSettle();
    expect(service.startCalls, 0);
    expect(service.settingsCalls, 0);

    await _scrollTo(
      tester,
      find.byKey(const Key('open-accessibility-settings-button')),
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('open-accessibility-settings-button')),
          )
          .onPressed,
      isNull,
    );
    await _scrollTo(tester, find.byKey(const Key('review-disclosure-button')));
    await tester.tap(find.byKey(const Key('review-disclosure-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accept-disclosure-button')));
    await tester.pumpAndSettle();
    await _scrollTo(
      tester,
      find.byKey(const Key('open-accessibility-settings-button')),
    );
    await tester.tap(
      find.byKey(const Key('open-accessibility-settings-button')),
    );
    await tester.pump();
    expect(service.settingsCalls, 1);
    expect(service.startCalls, 0);
    service.current = _idle();
    await controller.refreshOnReturn();
    await tester.pumpAndSettle();
    expect(find.textContaining('connection changed'), findsOneWidget);
    expect(controller.disclosureAccepted, isFalse);
    expect(controller.selection, isEmpty);
    expect(service.startCalls, 0);
    await _scrollTo(tester, find.byKey(const Key('review-disclosure-button')));
    await tester.tap(find.byKey(const Key('review-disclosure-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('agree again for a fresh test'), findsOneWidget);
    await tester.tap(find.byKey(const Key('accept-disclosure-button')));
    await tester.pumpAndSettle();
    controller.setSelected(GuardQualificationTarget.youtubeApp, true);
    expect(controller.canStart, isTrue);
    expect(service.startCalls, 0);
  });

  testWidgets('all four choices start unchecked after screen recreation', (
    tester,
  ) async {
    final firstController = _controller(_ScreenService());
    addTearDown(firstController.dispose);
    await tester.pumpWidget(_app(firstController));
    await tester.pump();
    await _scrollTo(tester, find.byKey(const Key('guard-target-facebook_app')));
    await tester.tap(find.byKey(const Key('guard-target-facebook_app')));
    await tester.pump();
    expect(_checkbox(tester, 'facebook_app').value, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    final secondController = _controller(_ScreenService());
    addTearDown(secondController.dispose);
    await tester.pumpWidget(_app(secondController));
    await tester.pump();

    for (final id in <String>[
      'youtube_app',
      'instagram_app',
      'facebook_app',
      'tiktok_app',
    ]) {
      expect(_checkbox(tester, id).value, isFalse, reason: id);
    }
    expect(find.text('All choices start unchecked.'), findsOneWidget);
  });

  testWidgets('already-enabled service keeps revocation settings available', (
    tester,
  ) async {
    final service = _ScreenService();
    final controller = _controller(service);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pump();

    expect(controller.disclosureAccepted, isFalse);
    await _scrollTo(
      tester,
      find.byKey(const Key('open-accessibility-settings-button')),
    );
    await tester.tap(
      find.byKey(const Key('open-accessibility-settings-button')),
    );
    await tester.pump();

    expect(service.settingsCalls, 1);
    expect(service.startCalls, 0);
  });

  for (final terminal in <(String, String)>[
    ('interrupted', 'service_interrupted'),
    ('disconnected', 'service_disconnected'),
  ]) {
    testWidgets(
      'initial ${terminal.$1} snapshot keeps revocation route without consent',
      (tester) async {
        final service = _ScreenService(
          initial: _terminalInterrupted(terminal.$2),
        );
        final controller = _controller(service);
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(controller));
        await tester.pump();

        expect(controller.disclosureAccepted, isFalse);
        expect(controller.snapshot?.serviceConnected, isFalse);
        expect(find.text('Test interrupted'), findsOneWidget);
        await _scrollTo(
          tester,
          find.byKey(const Key('open-accessibility-settings-button')),
        );
        expect(
          find.text('Review or revoke Android Accessibility'),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const Key('open-accessibility-settings-button')),
        );
        await tester.pump();

        expect(service.settingsCalls, 1);
        expect(service.startCalls, 0);
      },
    );
  }

  testWidgets(
    'new targets require selection, disclosure, and confirmed whole-app start',
    (tester) async {
      final service = _ScreenService();
      final controller = _controller(service);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      await tester.pump();

      await _scrollTo(
        tester,
        find.byKey(const Key('guard-target-facebook_app')),
      );
      await tester.tap(find.byKey(const Key('guard-target-facebook_app')));
      await _scrollTo(tester, find.byKey(const Key('guard-target-tiktok_app')));
      await tester.tap(find.byKey(const Key('guard-target-tiktok_app')));
      await _scrollTo(
        tester,
        find.byKey(const Key('review-disclosure-button')),
      );
      await tester.tap(find.byKey(const Key('review-disclosure-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accept-disclosure-button')));
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.byKey(const Key('start-guard-test-button')));
      await tester.tap(find.byKey(const Key('start-guard-test-button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('entire Facebook and TikTok apps'),
        findsOneWidget,
      );
      expect(find.textContaining('not a Shorts-'), findsOneWidget);
      expect(service.startCalls, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.startCalls, 0);
      expect(service.current.isActive, isFalse);

      await tester.tap(find.byKey(const Key('start-guard-test-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-start-button')));
      await tester.pumpAndSettle();

      expect(service.startCalls, 1);
      expect(service.current.selectedTargets, {
        GuardQualificationTarget.facebookApp,
        GuardQualificationTarget.tiktokApp,
      });
      expect(find.text('Test running'), findsOneWidget);
      expect(find.byKey(const Key('pause-guard-test-button')), findsOneWidget);
      expect(find.byKey(const Key('end-guard-test-button')), findsOneWidget);
    },
  );

  testWidgets('pause, resume, and confirmed end use separate commands', (
    tester,
  ) async {
    final service = _ScreenService(initial: _running());
    final controller = _controller(service);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pump();

    await tester.tap(find.byKey(const Key('pause-guard-test-button')));
    await tester.pumpAndSettle();
    expect(service.pauseCalls, 0);
    await tester.tap(find.byKey(const Key('confirm-pause-button')));
    await tester.pumpAndSettle();
    expect(service.pauseCalls, 1);
    expect(find.byKey(const Key('resume-guard-test-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('resume-guard-test-button')));
    await tester.pumpAndSettle();
    expect(service.resumeCalls, 1);

    await _scrollTo(tester, find.byKey(const Key('end-guard-test-button')));
    await tester.tap(find.byKey(const Key('end-guard-test-button')));
    await tester.pumpAndSettle();
    expect(service.endCalls, 0);
    await tester.tap(find.byKey(const Key('confirm-end-button')));
    await tester.pumpAndSettle();
    expect(service.endCalls, 1);
    expect(find.text('Test ended'), findsOneWidget);
  });

  testWidgets(
    'end then fresh draft survives polling and starts a second session',
    (tester) async {
      final service = _ScreenService(initial: _running());
      final controller = _controller(service);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      await tester.pump();

      await _scrollTo(tester, find.byKey(const Key('end-guard-test-button')));
      await tester.tap(find.byKey(const Key('end-guard-test-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-end-button')));
      await tester.pumpAndSettle();
      expect(service.endCalls, 1);
      expect(find.text('Test ended'), findsOneWidget);

      // Active entry skipped package probing. Choose a new inactive test by
      // explicitly refreshing availability before creating the next draft.
      await _scrollTo(
        tester,
        find.byKey(const Key('refresh-guard-availability-button')),
      );
      await tester.tap(
        find.byKey(const Key('refresh-guard-availability-button')),
      );
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.byKey(const Key('guard-target-tiktok_app')));
      await tester.tap(find.byKey(const Key('guard-target-tiktok_app')));
      await _scrollTo(
        tester,
        find.byKey(const Key('review-disclosure-button')),
      );
      await tester.tap(find.byKey(const Key('review-disclosure-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accept-disclosure-button')));
      await tester.pumpAndSettle();

      await controller.refreshStatus();
      await tester.pump();

      expect(_checkbox(tester, 'tiktok_app').value, isTrue);
      expect(controller.disclosureAccepted, isTrue);
      await _scrollTo(tester, find.byKey(const Key('start-guard-test-button')));
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('start-guard-test-button')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('start-guard-test-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('entire TikTok app'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-start-button')));
      await tester.pumpAndSettle();

      expect(service.startCalls, 1);
      expect(service.current.status, GuardQualificationStatus.running);
      expect(service.current.selectedTargets, {
        GuardQualificationTarget.tiktokApp,
      });
      expect(find.text('Test running'), findsOneWidget);
    },
  );

  testWidgets('back keeps an active test visible until confirmed end', (
    tester,
  ) async {
    final service = _ScreenService(initial: _running());
    final controller = _controller(service);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_routeApp(controller));
    await tester.tap(find.text('Open test'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('End this test?'), findsOneWidget);
    await tester.tap(find.text('Keep test'));
    await tester.pumpAndSettle();
    expect(find.text('Test running'), findsOneWidget);
    expect(service.endCalls, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-end-button')));
    await tester.pumpAndSettle();
    expect(service.endCalls, 1);
    expect(find.text('Launcher'), findsOneWidget);
  });

  testWidgets('unknown native status keeps exit and recovery controls safe', (
    tester,
  ) async {
    final service = _PendingStatusService();
    final controller = GuardQualificationController(
      readinessService: _Availability(),
      service: service,
      pollingInterval: null,
    );
    addTearDown(() {
      controller.dispose();
      if (!service.status.isCompleted) {
        service.status.complete(_idle(connected: false));
      }
    });
    await tester.pumpWidget(_routeApp(controller));
    await tester.tap(find.text('Open test'));
    await tester.pumpAndSettle();

    expect(find.textContaining('status is not confirmed'), findsOneWidget);
    expect(find.byKey(const Key('end-guard-test-button')), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('open-accessibility-settings-button')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('End this test?'), findsOneWidget);
    await tester.tap(find.text('Keep test'));
    await tester.pumpAndSettle();
    expect(find.textContaining('status is not confirmed'), findsOneWidget);
    expect(service.endCalls, 0);
  });

  testWidgets(
    'unsupported platforms show no Android test or settings controls',
    (tester) async {
      final service = _ScreenService(
        initial: GuardQualificationSnapshot.unavailable(GuardPlatform.windows),
      );
      final controller = _controller(service);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      await tester.pump();

      expect(find.text('Android-only test unavailable'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byKey(const Key('review-disclosure-button')), findsNothing);
      expect(find.byKey(const Key('start-guard-test-button')), findsNothing);
      expect(
        find.byKey(const Key('open-accessibility-settings-button')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'large text remains scrollable and feature fallback stays explicit',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _controller(_ScreenService());
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _app(controller),
        ),
      );
      await tester.pump();
      await tester.drag(
        find.byKey(const Key('guard-qualification-scroll')),
        const Offset(0, -600),
      );
      await tester.pump();

      expect(find.text('Feature-only tests are not available'), findsOneWidget);
      expect(find.textContaining('never expanded'), findsOneWidget);
      expect(
        find.byKey(const Key('guard-target-facebook_app')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('guard-target-tiktok_app')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

CheckboxListTile _checkbox(WidgetTester tester, String id) =>
    tester.widget<CheckboxListTile>(find.byKey(Key('guard-target-$id')));

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find
        .descendant(
          of: find.byKey(const Key('guard-qualification-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

GuardQualificationController _controller(_ScreenService service) =>
    GuardQualificationController(
      readinessService: _Availability(),
      service: service,
      pollingInterval: null,
    );

Widget _app(GuardQualificationController controller) =>
    MaterialApp(home: GuardQualificationScreen(controller: controller));

Widget _routeApp(GuardQualificationController controller) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: Column(
        children: <Widget>[
          const Text('Launcher'),
          FilledButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    GuardQualificationScreen(controller: controller),
              ),
            ),
            child: const Text('Open test'),
          ),
        ],
      ),
    ),
  ),
);

GuardQualificationSnapshot _idle({bool connected = true}) =>
    GuardQualificationSnapshot(
      platform: GuardPlatform.android,
      status: GuardQualificationStatus.idle,
      remainingMillis: 0,
      selectedTargets: const {},
      serviceConnected: connected,
      disclosureAccepted: false,
      detailCode: null,
    );

GuardQualificationSnapshot _running() => GuardQualificationSnapshot(
  platform: GuardPlatform.android,
  status: GuardQualificationStatus.running,
  remainingMillis: 15 * 60 * 1000,
  selectedTargets: const {GuardQualificationTarget.youtubeApp},
  serviceConnected: true,
  disclosureAccepted: true,
  detailCode: null,
);

GuardQualificationSnapshot _paused() => GuardQualificationSnapshot(
  platform: GuardPlatform.android,
  status: GuardQualificationStatus.paused,
  remainingMillis: 14 * 60 * 1000,
  selectedTargets: const {GuardQualificationTarget.youtubeApp},
  serviceConnected: true,
  disclosureAccepted: true,
  detailCode: null,
);

GuardQualificationSnapshot _ended() => GuardQualificationSnapshot(
  platform: GuardPlatform.android,
  status: GuardQualificationStatus.ended,
  remainingMillis: 0,
  selectedTargets: const {},
  serviceConnected: true,
  disclosureAccepted: false,
  detailCode: 'ended_by_user',
);

GuardQualificationSnapshot _terminalInterrupted(String detailCode) =>
    GuardQualificationSnapshot(
      platform: GuardPlatform.android,
      status: GuardQualificationStatus.interrupted,
      remainingMillis: 0,
      selectedTargets: const {},
      serviceConnected: false,
      disclosureAccepted: false,
      detailCode: detailCode,
    );

class _ScreenService implements GuardQualificationService {
  _ScreenService({GuardQualificationSnapshot? initial})
    : current = initial ?? _idle();

  GuardQualificationSnapshot current;
  Object? statusError;
  int startCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int endCalls = 0;
  int settingsCalls = 0;

  @override
  void cancelPending() {}

  @override
  Future<GuardQualificationSnapshot> getStatus() async {
    if (statusError != null) throw statusError!;
    return current;
  }

  @override
  Future<GuardQualificationSnapshot> start(
    GuardQualificationStartRequest request,
  ) async {
    startCalls++;
    current = GuardQualificationSnapshot(
      platform: GuardPlatform.android,
      status: GuardQualificationStatus.running,
      remainingMillis: 15 * 60 * 1000,
      selectedTargets: request.selectedTargets,
      serviceConnected: true,
      disclosureAccepted: true,
      detailCode: null,
    );
    return current;
  }

  @override
  Future<GuardQualificationSnapshot> pause() async {
    pauseCalls++;
    current = _paused();
    return current;
  }

  @override
  Future<GuardQualificationSnapshot> resume() async {
    resumeCalls++;
    current = _running();
    return current;
  }

  @override
  Future<GuardQualificationSnapshot> end() async {
    endCalls++;
    current = _ended();
    return current;
  }

  @override
  Future<void> openAccessibilitySettings() async {
    settingsCalls++;
  }
}

class _PendingStatusService implements GuardQualificationService {
  final status = Completer<GuardQualificationSnapshot>();
  int endCalls = 0;

  @override
  void cancelPending() {}

  @override
  Future<GuardQualificationSnapshot> getStatus() => status.future;

  @override
  Future<GuardQualificationSnapshot> start(
    GuardQualificationStartRequest request,
  ) => throw UnimplementedError();

  @override
  Future<GuardQualificationSnapshot> pause() => throw UnimplementedError();

  @override
  Future<GuardQualificationSnapshot> resume() => throw UnimplementedError();

  @override
  Future<GuardQualificationSnapshot> end() async {
    endCalls++;
    return _ended();
  }

  @override
  Future<void> openAccessibilitySettings() async {}
}

class _Availability implements GuardReadinessService {
  GuardReadinessReport report = GuardReadinessReport(
    platform: GuardPlatform.android,
    targets: GuardTarget.values.map(
      (target) => GuardTargetReadiness(
        target: target,
        state: GuardReadinessState.versionUnqualified,
      ),
    ),
  );
  Future<GuardReadinessReport> Function()? response;
  int calls = 0;
  @override
  Future<GuardReadinessReport> checkReadiness() async {
    calls++;
    return response == null ? report : await response!();
  }
}
