import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/focus/application/guard_qualification_controller.dart';
import 'package:scripture_planner/src/features/focus/application/guard_qualification_service.dart';
import 'package:scripture_planner/src/features/focus/application/guard_readiness_service.dart';
import 'package:scripture_planner/src/features/focus/domain/guard_qualification.dart';
import 'package:scripture_planner/src/features/focus/domain/guard_readiness.dart';
import 'package:scripture_planner/src/features/focus/platform/method_channel_guard_qualification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('installed qualification choices', () {
    GuardReadinessReport report(Map<GuardTarget, GuardReadinessState> states) =>
        GuardReadinessReport(
          platform: GuardPlatform.android,
          targets: GuardTarget.values.map(
            (target) => GuardTargetReadiness(
              target: target,
              state: states[target] ?? GuardReadinessState.versionUnqualified,
            ),
          ),
        );

    GuardQualificationController setup(
      _Availability availability, {
      GuardQualificationSnapshot? initial,
      Duration timeout = const Duration(seconds: 5),
      Duration lifetime = const Duration(seconds: 30),
      DateTime Function()? clock,
    }) {
      final service = _FakeService(
        statuses: List.generate(
          10,
          (_) =>
              () async => initial ?? _snapshot(serviceConnected: true),
        ),
      );
      final controller = GuardQualificationController(
        service: service,
        readinessService: availability,
        pollingInterval: null,
        readinessTimeout: timeout,
        availabilityLifetime: lifetime,
        availabilityClock: clock,
      );
      addTearDown(controller.dispose);
      return controller;
    }

    test(
      'mixed absent, disabled and unknown never authorize selection',
      () async {
        final availability = _Availability()
          ..report = report({
            GuardTarget.instagramApp: GuardReadinessState.notInstalled,
            GuardTarget.facebookApp: GuardReadinessState.disabled,
            GuardTarget.tiktokApp: GuardReadinessState.versionUnknown,
          });
        final controller = setup(availability);
        await controller.initialize();
        for (final target in GuardQualificationTarget.values) {
          controller.setSelected(target, true);
        }
        expect(controller.selectableTargets, {
          GuardQualificationTarget.youtubeApp,
        });
        expect(controller.selection, {GuardQualificationTarget.youtubeApp});
        expect(
          controller.availabilityMessage,
          contains('does not mean qualified'),
        );
      },
    );

    test('all absent and failure have distinct empty states', () async {
      final availability = _Availability()
        ..report = report({
          for (final target in GuardTarget.values)
            target: GuardReadinessState.notInstalled,
        });
      final controller = setup(availability);
      await controller.initialize();
      expect(controller.selectableTargets, isEmpty);
      expect(controller.availabilityMessage, contains('None of the four'));
      availability.response = () async => throw StateError('probe failed');
      await controller.refreshAvailability();
      expect(controller.selectableTargets, isEmpty);
      expect(controller.availabilityMessage, contains('retry'));
      expect(controller.canOpenAccessibilitySettings, isTrue);
    });

    test(
      'return removes absent selection, new install stays unchecked; polling preserves draft',
      () async {
        final availability = _Availability()
          ..report = report({
            GuardTarget.instagramApp: GuardReadinessState.notInstalled,
          });
        final controller = setup(availability);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        await controller.refreshStatus();
        expect(availability.calls, 1);
        expect(controller.selection, {GuardQualificationTarget.youtubeApp});
        expect(controller.disclosureAccepted, isTrue);
        availability.report = report({
          GuardTarget.youtubeApp: GuardReadinessState.notInstalled,
        });
        await controller.refreshOnReturn();
        expect(availability.calls, 2);
        expect(controller.selection, isEmpty);
        expect(
          controller.selectableTargets,
          contains(GuardQualificationTarget.instagramApp),
        );
        expect(controller.disclosureAccepted, isTrue);
      },
    );

    test(
      'availability reconciliation invalidates confirmation only when selection changes',
      () async {
        final availability = _Availability();
        final service = _FakeService(
          statuses: List.generate(
            6,
            (_) => () async => _snapshot(serviceConnected: true),
          ),
        )..startResult = Future.value(
            _snapshot(
              status: GuardQualificationStatus.running,
              serviceConnected: true,
              disclosureAccepted: true,
              selectedTargets: {GuardQualificationTarget.instagramApp},
            ),
          );
        final controller = GuardQualificationController(
          service: service,
          readinessService: availability,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        controller.setSelected(GuardQualificationTarget.instagramApp, true);

        final unchangedRevision = controller.draftRevision;
        await controller.refreshOnReturn();
        expect(controller.selection, {
          GuardQualificationTarget.youtubeApp,
          GuardQualificationTarget.instagramApp,
        });
        expect(controller.draftRevision, unchangedRevision);

        availability.report = report({
          GuardTarget.youtubeApp: GuardReadinessState.disabled,
        });
        await controller.refreshOnReturn();
        expect(controller.selection, {GuardQualificationTarget.instagramApp});
        expect(controller.disclosureAccepted, isTrue);
        expect(controller.draftRevision, unchangedRevision + 1);
        expect(
          await controller.start(confirmedDraftRevision: unchangedRevision),
          isFalse,
        );
        expect(service.startCalls, 0);

        expect(
          await controller.start(
            confirmedDraftRevision: controller.draftRevision,
          ),
          isTrue,
        );
        expect(service.startCalls, 1);
      },
    );

    test('reconciliation removing every choice blocks Start', () async {
      final availability = _Availability();
      final service = _FakeService(
        statuses: List.generate(
          4,
          (_) => () async => _snapshot(serviceConnected: true),
        ),
      );
      final controller = GuardQualificationController(
        service: service,
        readinessService: availability,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      controller.acceptDisclosure();
      controller.setSelected(GuardQualificationTarget.youtubeApp, true);
      final oldRevision = controller.draftRevision;

      availability.report = report({
        for (final target in GuardTarget.values)
          target: GuardReadinessState.versionUnknown,
      });
      await controller.refreshOnReturn();

      expect(controller.selection, isEmpty);
      expect(controller.draftRevision, oldRevision + 1);
      expect(controller.canStart, isFalse);
      expect(
        await controller.start(confirmedDraftRevision: oldRevision),
        isFalse,
      );
      expect(service.startCalls, 0);
    });

    test('latest refresh wins and disposed responses are ignored', () async {
      final availability = _Availability();
      final controller = setup(availability);
      await controller.initialize();
      final late = Completer<GuardReadinessReport>();
      availability.response = () => late.future;
      final old = controller.refreshAvailability();
      availability.response = () async =>
          report({GuardTarget.youtubeApp: GuardReadinessState.notInstalled});
      await controller.refreshAvailability();
      await old; // Supersession releases the waiter before the backend replies.
      late.complete(report({}));
      await old;
      expect(
        controller.selectableTargets,
        isNot(contains(GuardQualificationTarget.youtubeApp)),
      );
      final disposed = Completer<GuardReadinessReport>();
      availability.response = () => disposed.future;
      final pending = controller.refreshAvailability();
      controller.dispose();
      await pending; // Disposal also releases waiting work immediately.
      disposed.complete(report({}));
      await pending;
      expect(controller.canStart, isFalse);
    });

    testWidgets('dispose cancels a truly pending initialization deadline', (
      tester,
    ) async {
      final backend = Completer<GuardReadinessReport>();
      final availability = _Availability()..response = () => backend.future;
      final controller = setup(availability);
      final initializing = controller.initialize();
      await tester.pump();
      expect(availability.calls, 1);
      expect(controller.availabilityLoading, isTrue);
      controller.dispose();
      await initializing;
      expect(controller.availabilityLoading, isFalse);
      // Backend deliberately remains pending. The widget harness must find no
      // deadline timer without advancing fake time by five seconds.
    });

    testWidgets('dispose from loading notification leaves no deadline timer', (
      tester,
    ) async {
      final availability = _Availability();
      final controller = setup(availability);
      controller.addListener(() {
        if (controller.availabilityLoading) controller.dispose();
      });
      await controller.initialize();
      expect(controller.availabilityLoading, isFalse);
      expect(availability.calls, 0);
      expect(controller.canStart, isFalse);
    });

    for (final status in [
      GuardQualificationStatus.running,
      GuardQualificationStatus.paused,
      GuardQualificationStatus.unavailable,
    ]) {
      test('$status entry and return do not probe availability', () async {
        final availability = _Availability();
        final controller = setup(
          availability,
          initial: _snapshot(status: status, serviceConnected: true),
        );
        await controller.initialize();
        await controller.refreshOnReturn();
        await controller.refreshAvailability();
        expect(availability.calls, 0);
        expect(controller.canStart, isFalse);
        expect(controller.canOpenAccessibilitySettings, isTrue);
      });
    }

    for (final status in GuardQualificationStatus.values) {
      test('$status disconnected cannot probe or start', () async {
        final availability = _Availability();
        final controller = setup(
          availability,
          initial: _snapshot(status: status),
        );
        await controller.initialize();
        await controller.refreshOnReturn();
        await controller.refreshAvailability();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        expect(availability.calls, 0);
        expect(controller.canStart, isFalse);
        expect(await controller.start(), isFalse);
      });
    }

    for (final status in [
      GuardQualificationStatus.interrupted,
      GuardQualificationStatus.error,
    ]) {
      test('$status reconnect requires a fresh deliberate test', () async {
        final disconnected = _snapshot(
          status: status,
          detailCode: 'service_disconnected',
          selectedTargets: {GuardQualificationTarget.instagramApp},
        );
        final reconnected = _snapshot(
          status: status,
          serviceConnected: true,
          detailCode: 'service_reconnected',
        );
        final service =
            _FakeService(
                statuses: [
                  () async => disconnected,
                  () async => reconnected,
                  () async => reconnected,
                  () async => reconnected,
                ],
              )
              ..startResult = Future.value(
                _snapshot(
                  status: GuardQualificationStatus.running,
                  serviceConnected: true,
                  disclosureAccepted: true,
                  selectedTargets: {GuardQualificationTarget.youtubeApp},
                ),
              );
        final availability = _Availability();
        final controller = GuardQualificationController(
          service: service,
          readinessService: availability,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.acceptDisclosure();
        expect(availability.calls, 0);
        expect(controller.canStart, isFalse);

        await controller.refreshOnReturn();
        expect(controller.snapshot!.status, status);
        expect(availability.calls, 1);
        expect(
          controller.selectableTargets,
          GuardQualificationTarget.values.toSet(),
        );
        expect(controller.disclosureAccepted, isFalse);
        expect(controller.selection, isEmpty);
        expect(controller.canOpenAccessibilitySettings, isTrue);
        expect(controller.mayBeActive, isFalse);
        expect(await controller.start(), isFalse);
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        expect(await controller.start(), isFalse);
        controller.acceptDisclosure();

        await controller.refreshStatus();
        await controller.refreshStatus();
        expect(availability.calls, 1); // Terminal polls do not probe packages.
        expect(controller.snapshot!.status, status);
        expect(controller.disclosureAccepted, isTrue);
        expect(controller.selection, {GuardQualificationTarget.youtubeApp});
        expect(service.startCalls, 0);
        expect(await controller.start(), isTrue);
        expect(availability.calls, 2); // Explicit Start rechecks availability.
        expect(service.startCalls, 1);
        expect(await controller.start(), isFalse);
        expect(service.startCalls, 1);
      });

      test(
        '$status connected entry permits choices without consent reuse',
        () async {
          final availability = _Availability();
          final controller = setup(
            availability,
            initial: _snapshot(
              status: status,
              serviceConnected: true,
              disclosureAccepted: true,
              selectedTargets: {GuardQualificationTarget.instagramApp},
            ),
          );
          await controller.initialize();
          expect(availability.calls, 1);
          expect(controller.snapshot!.status, status);
          expect(controller.selectableTargets, isNotEmpty);
          expect(controller.disclosureAccepted, isFalse);
          expect(controller.selection, isEmpty);
          expect(await controller.start(), isFalse);
          await controller.refreshAvailability();
          expect(availability.calls, 2);
        },
      );
    }

    test('unknown status cannot probe or authorize Start', () async {
      final availability = _Availability();
      final service = _FakeService(
        statuses: [
          () async => _snapshot(serviceConnected: true),
          () async => throw StateError('status unavailable'),
        ],
      );
      final controller = GuardQualificationController(
        service: service,
        readinessService: availability,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      controller.acceptDisclosure();
      controller.setSelected(GuardQualificationTarget.youtubeApp, true);
      await controller.refreshStatus();
      await controller.refreshAvailability();
      expect(controller.snapshot, isNull);
      expect(availability.calls, 1);
      expect(await controller.start(), isFalse);
      expect(service.startCalls, 0);
      expect(controller.canOpenAccessibilitySettings, isTrue);
    });

    testWidgets(
      'timeout and expiry revoke availability without polling or losing recovery',
      (tester) async {
        final availability = _Availability();
        var now = DateTime.utc(2026);
        final controller = setup(
          availability,
          timeout: const Duration(seconds: 2),
          lifetime: const Duration(seconds: 4),
          clock: () => now,
        );
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        expect(controller.canStart, isTrue);
        now = now.add(const Duration(seconds: 4));
        // T20: expiry disables editing/authorization, but a deliberate Start
        // may revalidate the retained draft before any native command.
        expect(controller.canStart, isTrue);
        expect(controller.selectableTargets, isEmpty);
        expect(
          controller.displayedTargets,
          contains(GuardQualificationTarget.youtubeApp),
        );
        expect(controller.availabilityMessage, contains('stale'));
        expect(availability.calls, 1);
        final late = Completer<GuardReadinessReport>();
        availability.response = () => late.future;
        final refresh = controller.refreshAvailability();
        expect(controller.canOpenAccessibilitySettings, isTrue);
        await tester.pump(const Duration(seconds: 2));
        await refresh;
        expect(controller.availabilityLoading, isFalse);
        expect(controller.selectableTargets, isEmpty);
        late.complete(report({}));
        await tester.pump();
        expect(controller.selectableTargets, isEmpty);
        expect(controller.selection, {GuardQualificationTarget.youtubeApp});
      },
    );

    test(
      'late absent response cannot alter active native selections',
      () async {
        final availability = _Availability();
        final active = _snapshot(
          status: GuardQualificationStatus.running,
          remainingMillis: 800000,
          selectedTargets: {GuardQualificationTarget.youtubeApp},
          serviceConnected: true,
          disclosureAccepted: true,
        );
        final controller = setup(availability, initial: active);
        await controller.initialize();
        availability.report = report({
          GuardTarget.youtubeApp: GuardReadinessState.notInstalled,
        });
        await controller.refreshAvailability();
        expect(controller.selection, {GuardQualificationTarget.youtubeApp});
        availability.response = () async => throw StateError('failure');
        await controller.refreshAvailability();
        expect(controller.mayBeActive, isTrue);
        expect(controller.canOpenAccessibilitySettings, isTrue);
        expect(availability.calls, 0);
      },
    );

    test(
      'Start rechecks and never dispatches newly absent selection',
      () async {
        final availability = _Availability();
        final service = _FakeService(
          statuses: [() async => _snapshot(serviceConnected: true)],
        );
        final controller = GuardQualificationController(
          service: service,
          readinessService: availability,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        availability.report = report({
          GuardTarget.youtubeApp: GuardReadinessState.notInstalled,
        });
        expect(await controller.start(), isFalse);
        expect(service.startCalls, 0);
        expect(controller.selection, isEmpty);
      },
    );

    test(
      'End during Start readiness prevents dispatch and late draft changes',
      () async {
        final availability = _Availability();
        final service =
            _FakeService(
                statuses: [() async => _snapshot(serviceConnected: true)],
              )
              ..endResult = Future.value(
                _snapshot(
                  status: GuardQualificationStatus.ended,
                  serviceConnected: true,
                ),
              );
        final controller = GuardQualificationController(
          service: service,
          readinessService: availability,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        final late = Completer<GuardReadinessReport>();
        availability.response = () => late.future;
        final start = controller.start();
        expect(await controller.end(), isTrue);
        late.complete(report({}));
        expect(await start, isFalse);
        expect(service.startCalls, 0);
        expect(controller.selection, isEmpty);
        expect(controller.disclosureAccepted, isFalse);
      },
    );

    test(
      'probe begun inactive cannot erase a newly recovered native lease',
      () async {
        final availability = _Availability();
        final service = _FakeService(
          statuses: [
            () async => _snapshot(serviceConnected: true),
            () async => _snapshot(
              status: GuardQualificationStatus.running,
              remainingMillis: 800000,
              serviceConnected: true,
              disclosureAccepted: true,
              selectedTargets: {GuardQualificationTarget.instagramApp},
            ),
          ],
        );
        final controller = GuardQualificationController(
          service: service,
          readinessService: availability,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        final pending = Completer<GuardReadinessReport>();
        availability.response = () => pending.future;
        final refresh = controller.refreshAvailability();
        await controller.refreshStatus();
        pending.complete(
          report({GuardTarget.instagramApp: GuardReadinessState.notInstalled}),
        );
        await refresh;
        expect(controller.selection, {GuardQualificationTarget.instagramApp});
        expect(controller.disclosureAccepted, isTrue);
        expect(controller.mayBeActive, isTrue);
      },
    );

    testWidgets(
      'Start timeout never dispatches or retries and keeps recovery usable',
      (tester) async {
        final availability = _Availability();
        final service = _FakeService(
          statuses: [() async => _snapshot(serviceConnected: true)],
        );
        final controller = GuardQualificationController(
          service: service,
          readinessService: availability,
          pollingInterval: null,
          readinessTimeout: const Duration(seconds: 2),
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        final pending = Completer<GuardReadinessReport>();
        availability.response = () => pending.future;
        final start = controller.start();
        expect(controller.canOpenAccessibilitySettings, isTrue);
        await tester.pump(const Duration(seconds: 2));
        expect(await start, isFalse);
        pending.complete(report({}));
        await tester.pump();
        expect(service.startCalls, 0);
        expect(availability.calls, 2);
        expect(controller.canStart, isFalse);
        expect(controller.canOpenAccessibilitySettings, isTrue);
      },
    );

    test(
      'stale draft Start probes once and rejects a duplicate Start',
      () async {
        var now = DateTime.utc(2026);
        final availability = _Availability();
        final service =
            _FakeService(
                statuses: [() async => _snapshot(serviceConnected: true)],
              )
              ..startResult = Future.value(
                _snapshot(
                  status: GuardQualificationStatus.running,
                  serviceConnected: true,
                  disclosureAccepted: true,
                  selectedTargets: {GuardQualificationTarget.youtubeApp},
                ),
              );
        final controller = GuardQualificationController(
          service: service,
          readinessService: availability,
          availabilityClock: () => now,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        now = now.add(const Duration(seconds: 31));
        final pending = Completer<GuardReadinessReport>();
        availability.response = () => pending.future;
        final start = controller.start();
        expect(await controller.start(), isFalse);
        expect(
          controller.displayedTargets,
          contains(GuardQualificationTarget.youtubeApp),
        );
        expect(controller.selection, {GuardQualificationTarget.youtubeApp});
        expect(service.startCalls, 0);
        expect(availability.calls, 2);
        pending.complete(report({}));
        expect(await start, isTrue);
        expect(service.startCalls, 1);
      },
    );

    for (final change in ['consent', 'selection', 'connection', 'dispose']) {
      test(
        '$change during Start probe cannot authorize a late reply',
        () async {
          final availability = _Availability();
          final service = _FakeService(
            statuses: [
              () async => _snapshot(serviceConnected: true),
              () async => _snapshot(serviceConnected: false),
            ],
          );
          final controller = GuardQualificationController(
            service: service,
            readinessService: availability,
            pollingInterval: null,
          );
          addTearDown(controller.dispose);
          await controller.initialize();
          controller.acceptDisclosure();
          controller.setSelected(GuardQualificationTarget.youtubeApp, true);
          final pending = Completer<GuardReadinessReport>();
          availability.response = () => pending.future;
          final start = controller.start();
          switch (change) {
            case 'consent':
              controller.acceptDisclosure();
            case 'selection':
              controller.setSelected(
                GuardQualificationTarget.youtubeApp,
                false,
              );
            case 'connection':
              await controller.refreshStatus();
            case 'dispose':
              controller.dispose();
          }
          pending.complete(report({}));
          expect(await start, isFalse);
          expect(service.startCalls, 0);
        },
      );
    }

    test(
      'failed probe retains rows and draft without authorizing Start',
      () async {
        final availability = _Availability();
        final controller = setup(availability);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        final rows = controller.displayedTargets;
        availability.response = () async => throw StateError('unavailable');
        expect(await controller.start(), isFalse);
        expect(controller.displayedTargets, rows);
        expect(controller.selection, {GuardQualificationTarget.youtubeApp});
        expect(controller.selectableTargets, isEmpty);
        expect(controller.canStart, isFalse);
        expect(controller.availabilityMessage, contains('not authorized'));
        availability.response = null;
        expect(await controller.refreshAvailability(), isTrue);
        expect(controller.canStart, isTrue);
      },
    );

    test(
      'fresh disable and unknown remove selection; new install is unchecked',
      () async {
        final availability = _Availability()
          ..report = report({
            GuardTarget.tiktokApp: GuardReadinessState.notInstalled,
          });
        final controller = setup(availability);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        controller.setSelected(GuardQualificationTarget.instagramApp, true);
        availability.report = report({
          GuardTarget.youtubeApp: GuardReadinessState.disabled,
          GuardTarget.instagramApp: GuardReadinessState.versionUnknown,
        });
        await controller.refreshAvailability();
        expect(controller.selection, isEmpty);
        expect(controller.displayedTargets, {
          GuardQualificationTarget.facebookApp,
          GuardQualificationTarget.tiktokApp,
        });
        expect(controller.canStart, isFalse);
      },
    );

    test(
      'Settings setup and connection require fresh agreement and selection',
      () async {
        final availability = _Availability();
        final service = _FakeService(
          statuses: [
            () async => _snapshot(serviceConnected: false),
            () async => _snapshot(serviceConnected: true),
            () async => _snapshot(serviceConnected: true),
          ],
        );
        final controller = GuardQualificationController(
          service: service,
          readinessService: availability,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.acceptDisclosure();
        await controller.openAccessibilitySettings();
        await controller.refreshOnReturn();
        expect(controller.message, contains('connection changed'));
        expect(controller.disclosureAccepted, isFalse);
        expect(controller.selection, isEmpty);
        expect(service.startCalls, 0);
        await controller.refreshStatus();
        expect(controller.message, contains('connection changed'));
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        expect(controller.canStart, isTrue);
        expect(controller.disclosureAccepted, isTrue);
      },
    );

    for (final unknown in [false, true]) {
      test(
        'Start rejects ${unknown ? 'unknown version' : 'failed report'} after a confirmed draft',
        () async {
          final availability = _Availability();
          final service = _FakeService(
            statuses: [() async => _snapshot(serviceConnected: true)],
          );
          final controller = GuardQualificationController(
            service: service,
            readinessService: availability,
            pollingInterval: null,
          );
          addTearDown(controller.dispose);
          await controller.initialize();
          controller.acceptDisclosure();
          controller.setSelected(GuardQualificationTarget.youtubeApp, true);
          availability.report = unknown
              ? report({
                  GuardTarget.youtubeApp: GuardReadinessState.versionUnknown,
                })
              : GuardReadinessReport.probeFailed(
                  platform: GuardPlatform.android,
                );
          expect(await controller.start(), isFalse);
          expect(service.startCalls, 0);
          expect(controller.canStart, isFalse);
          if (!unknown) {
            expect(
              controller.displayedTargets,
              contains(GuardQualificationTarget.youtubeApp),
            );
            expect(controller.selection, {GuardQualificationTarget.youtubeApp});
            expect(controller.availabilityMessage, contains('not authorized'));
          }
        },
      );
    }

    test('known non-Android skips readiness completely', () async {
      final availability = _Availability();
      final controller = setup(
        availability,
        initial: GuardQualificationSnapshot.unavailable(GuardPlatform.windows),
      );
      await controller.initialize();
      await controller.refreshOnReturn();
      await controller.refreshAvailability();
      expect(availability.calls, 0);
      expect(controller.selectableTargets, isEmpty);
      expect(await controller.start(), isFalse);
    });
  });

  group('Guard qualification protocol', () {
    test('decodes a strict authoritative active snapshot', () {
      final snapshot = decodeGuardQualificationSnapshot(
        _payload(
          status: 'running',
          remainingMillis: 899000,
          targets: <Object?>[
            'youtube_app',
            'instagram_app',
            'facebook_app',
            'tiktok_app',
          ],
          serviceConnected: true,
          disclosureAccepted: true,
        ),
      );

      expect(snapshot.status, GuardQualificationStatus.running);
      expect(snapshot.remainingMillis, 899000);
      expect(snapshot.selectedTargets, <GuardQualificationTarget>{
        GuardQualificationTarget.youtubeApp,
        GuardQualificationTarget.instagramApp,
        GuardQualificationTarget.facebookApp,
        GuardQualificationTarget.tiktokApp,
      });
      expect(
        () =>
            snapshot.selectedTargets.add(GuardQualificationTarget.instagramApp),
        throwsUnsupportedError,
      );
    });

    test(
      'rejects missing, extra, malformed, duplicate, and inconsistent data',
      () {
        final valid = _payload();
        final missing = Map<String, Object?>.of(valid)..remove('detailCode');
        final extra = Map<String, Object?>.of(valid)..['unexpected'] = true;
        final cases = <Object?>[
          null,
          missing,
          extra,
          _payload(status: 'unknown'),
          _payload(remainingMillis: -1),
          _payload(targets: <Object?>['youtube_app', 'youtube_app']),
          _payload(targets: <Object?>['youtube_shorts']),
          _payload(targets: <Object?>['com.ss.android.ugc.trill']),
          _payload(
            status: 'running',
            remainingMillis: 1000,
            targets: <Object?>['youtube_app'],
            serviceConnected: false,
            disclosureAccepted: true,
          ),
          _payload(
            status: 'paused',
            remainingMillis: 1000,
            targets: <Object?>[],
            serviceConnected: true,
            disclosureAccepted: true,
          ),
          _payload(
            status: 'idle',
            remainingMillis: 1,
            targets: <Object?>[],
            serviceConnected: true,
            disclosureAccepted: false,
          ),
          _payload(detailCode: 'arbitrary_native_text'),
        ];

        for (final value in cases) {
          expect(
            () => decodeGuardQualificationSnapshot(value),
            throwsFormatException,
            reason: '$value',
          );
        }
      },
    );

    test('sends only explicit whole-app start arguments', () async {
      const channel = MethodChannel(
        MethodChannelGuardQualificationGateway.channelName,
      );
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            received = call;
            return _payload(
              status: 'running',
              remainingMillis: 15 * 60 * 1000,
              targets: <Object?>['facebook_app', 'tiktok_app'],
              serviceConnected: true,
              disclosureAccepted: true,
            );
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final gateway = MethodChannelGuardQualificationGateway(channel: channel);
      await gateway.start(
        GuardQualificationStartRequest(
          selectedTargets: const <GuardQualificationTarget>{
            GuardQualificationTarget.facebookApp,
            GuardQualificationTarget.tiktokApp,
          },
          durationMinutes: 15,
          disclosureAccepted: true,
        ),
      );

      expect(received?.method, 'start');
      expect(received?.arguments, <String, Object>{
        'schemaVersion': 1,
        'selectedTargetIds': <String>['facebook_app', 'tiktok_app'],
        'durationMinutes': 15,
        'disclosureAccepted': true,
      });
    });

    test('bounds status, command, and settings channel replies', () async {
      const channel = MethodChannel(
        MethodChannelGuardQualificationGateway.channelName,
      );
      final pendingStatus = Completer<Object?>();
      final pendingStart = Completer<Object?>();
      final pendingSettings = Completer<Object?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) {
            return switch (call.method) {
              'getStatus' => pendingStatus.future,
              'start' => pendingStart.future,
              'openAccessibilitySettings' => pendingSettings.future,
              _ => Future<Object?>.value(null),
            };
          });
      addTearDown(() {
        if (!pendingStatus.isCompleted) pendingStatus.complete(_payload());
        if (!pendingStart.isCompleted) pendingStart.complete(_payload());
        if (!pendingSettings.isCompleted) pendingSettings.complete(true);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      final gateway = MethodChannelGuardQualificationGateway(
        channel: channel,
        statusTimeout: const Duration(milliseconds: 10),
        commandTimeout: const Duration(milliseconds: 10),
        settingsTimeout: const Duration(milliseconds: 10),
      );

      await expectLater(
        gateway.getStatus(),
        throwsA(isA<GuardQualificationUnavailable>()),
      );
      await expectLater(
        gateway.start(
          GuardQualificationStartRequest(
            selectedTargets: const {GuardQualificationTarget.youtubeApp},
            durationMinutes: 15,
            disclosureAccepted: true,
          ),
        ),
        throwsA(isA<GuardQualificationUnavailable>()),
      );
      await expectLater(
        gateway.openAccessibilitySettings(),
        throwsA(isA<GuardQualificationUnavailable>()),
      );
    });

    test('production factory avoids native channel off Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel(
        MethodChannelGuardQualificationGateway.channelName,
      );
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            calls++;
            return _payload();
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final gateway = createGuardQualificationGateway(channel: channel);
      final snapshot = await gateway.getStatus();

      expect(snapshot.platform, GuardPlatform.windows);
      expect(snapshot.status, GuardQualificationStatus.unavailable);
      expect(calls, 0);
    });
  });

  group('GuardQualificationController', () {
    test(
      'assumes possible native activity until status is conclusive',
      () async {
        final pending = Completer<GuardQualificationSnapshot>();
        final service = _FakeService(
          statuses: <Future<GuardQualificationSnapshot> Function()>[
            () => pending.future,
          ],
        );
        final controller = GuardQualificationController(
          readinessService: _Availability(),
          service: service,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);

        final initialization = controller.initialize();
        expect(controller.mayBeActive, isTrue);
        expect(controller.canStart, isFalse);
        pending.complete(_snapshot(serviceConnected: true));
        await initialization;
        expect(controller.mayBeActive, isFalse);
      },
    );

    test(
      'requires disclosure, explicit selection, and connected service',
      () async {
        final service = _FakeService(
          statuses: <Future<GuardQualificationSnapshot> Function()>[
            () => Future.value(_snapshot(serviceConnected: true)),
          ],
        );
        final controller = GuardQualificationController(
          readinessService: _Availability(),
          service: service,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();

        expect(controller.selection, isEmpty);
        expect(await controller.start(), isFalse);
        controller.acceptDisclosure();
        expect(await controller.start(), isFalse);
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        expect(controller.canStart, isTrue);
        expect(service.startCalls, 0);

        service.startResult = Future.value(
          _snapshot(
            status: GuardQualificationStatus.running,
            remainingMillis: 900000,
            selectedTargets: const {GuardQualificationTarget.youtubeApp},
            serviceConnected: true,
            disclosureAccepted: true,
          ),
        );
        expect(await controller.start(), isTrue);
        expect(service.startCalls, 1);
        expect(controller.snapshot?.status, GuardQualificationStatus.running);
      },
    );

    for (final terminal in <(String, String)>[
      ('service interruption', 'service_interrupted'),
      ('service disconnection', 'service_disconnected'),
    ]) {
      test(
        'initial ${terminal.$1} keeps explicit revocation recovery',
        () async {
          final service = _FakeService(
            statuses: <Future<GuardQualificationSnapshot> Function()>[
              () => Future.value(
                _snapshot(
                  status: GuardQualificationStatus.interrupted,
                  detailCode: terminal.$2,
                ),
              ),
            ],
          );
          final controller = GuardQualificationController(
            readinessService: _Availability(),
            service: service,
            pollingInterval: null,
          );
          addTearDown(controller.dispose);

          await controller.initialize();

          expect(controller.mayBeActive, isFalse);
          expect(controller.snapshot?.serviceConnected, isFalse);
          expect(controller.disclosureAccepted, isFalse);
          expect(controller.hasAccessibilityRecoveryRoute, isTrue);
          expect(controller.canOpenAccessibilitySettings, isTrue);
          expect(await controller.openAccessibilitySettings(), isTrue);
          expect(service.settingsCalls, 1);
        },
      );
    }

    test('normal idle no-access state still requires disclosure', () async {
      final service = _FakeService(
        statuses: <Future<GuardQualificationSnapshot> Function()>[
          () => Future.value(_snapshot()),
        ],
      );
      final controller = GuardQualificationController(
        readinessService: _Availability(),
        service: service,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);

      await controller.initialize();

      expect(controller.hasAccessibilityRecoveryRoute, isFalse);
      expect(controller.canOpenAccessibilitySettings, isFalse);
      controller.acceptDisclosure();
      expect(controller.canOpenAccessibilitySettings, isTrue);
    });

    test(
      'idle status polling preserves pre-start consent and selection',
      () async {
        final service = _FakeService(
          statuses: <Future<GuardQualificationSnapshot> Function()>[
            () => Future.value(_snapshot(serviceConnected: true)),
            () => Future.value(_snapshot(serviceConnected: true)),
          ],
        );
        final controller = GuardQualificationController(
          readinessService: _Availability(),
          service: service,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);

        await controller.refreshStatus();

        expect(controller.disclosureAccepted, isTrue);
        expect(controller.selection, {GuardQualificationTarget.youtubeApp});
        expect(controller.canStart, isTrue);
      },
    );

    for (final terminal in <(String, GuardQualificationStatus, String?, bool)>[
      ('ended', GuardQualificationStatus.ended, 'ended_by_user', true),
      ('completed', GuardQualificationStatus.completed, null, true),
      (
        'interrupted',
        GuardQualificationStatus.interrupted,
        'service_interrupted',
        false,
      ),
      ('error', GuardQualificationStatus.error, 'error', false),
    ]) {
      test(
        'unchanged ${terminal.$1} polling preserves a fresh draft',
        () async {
          final snapshot = _snapshot(
            status: terminal.$2,
            serviceConnected: terminal.$4,
            detailCode: terminal.$3,
          );
          final service = _FakeService(
            statuses: <Future<GuardQualificationSnapshot> Function()>[
              () => Future.value(_snapshot(serviceConnected: true)),
              () => Future.value(snapshot),
              () => Future.value(snapshot),
            ],
          );
          final availability = _Availability();
          final controller = GuardQualificationController(
            readinessService: availability,
            service: service,
            pollingInterval: null,
          );
          addTearDown(controller.dispose);
          await controller.initialize();
          // Obtain choices while inactive, then confirm the terminal state.
          // Recovery-only entry itself must not query installed packages.
          await controller.refreshStatus();
          controller.acceptDisclosure();
          controller.setSelected(GuardQualificationTarget.instagramApp, true);

          await controller.refreshStatus();

          expect(controller.disclosureAccepted, isTrue);
          // T20 retains the rows on disconnect, but their freshness is revoked.
          // A disconnected recovery draft cannot add a selection from old data.
          expect(
            controller.selection,
            terminal.$4 ? {GuardQualificationTarget.instagramApp} : isEmpty,
          );
          expect(
            controller.displayedTargets,
            contains(GuardQualificationTarget.instagramApp),
          );
          expect(availability.calls, 1);
        },
      );
    }

    test('unchanged ended polling permits an explicit second start', () async {
      final ended = _snapshot(
        status: GuardQualificationStatus.ended,
        serviceConnected: true,
        detailCode: 'ended_by_user',
      );
      final running = _snapshot(
        status: GuardQualificationStatus.running,
        remainingMillis: 900000,
        selectedTargets: const {GuardQualificationTarget.tiktokApp},
        serviceConnected: true,
        disclosureAccepted: true,
      );
      final service = _FakeService(
        statuses: <Future<GuardQualificationSnapshot> Function()>[
          () => Future.value(ended),
          () => Future.value(ended),
        ],
      )..startResult = Future.value(running);
      final controller = GuardQualificationController(
        readinessService: _Availability(),
        service: service,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      controller.acceptDisclosure();
      controller.setSelected(GuardQualificationTarget.tiktokApp, true);

      await controller.refreshStatus();

      expect(controller.canStart, isTrue);
      expect(await controller.start(), isTrue);
      expect(service.startCalls, 1);
      expect(controller.snapshot?.status, GuardQualificationStatus.running);
      expect(controller.selection, {GuardQualificationTarget.tiktokApp});
    });

    test(
      'active to terminal polling clears native consent and selection',
      () async {
        final running = _snapshot(
          status: GuardQualificationStatus.running,
          remainingMillis: 900000,
          selectedTargets: const {GuardQualificationTarget.youtubeApp},
          serviceConnected: true,
          disclosureAccepted: true,
        );
        final service = _FakeService(
          statuses: <Future<GuardQualificationSnapshot> Function()>[
            () => Future.value(running),
            () => Future.value(
              _snapshot(
                status: GuardQualificationStatus.completed,
                serviceConnected: true,
              ),
            ),
          ],
        );
        final controller = GuardQualificationController(
          readinessService: _Availability(),
          service: service,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();

        await controller.refreshStatus();

        expect(controller.disclosureAccepted, isFalse);
        expect(controller.selection, isEmpty);
        expect(controller.canStart, isFalse);
      },
    );

    for (final change in <(String, GuardQualificationSnapshot)>[
      (
        'service disconnection',
        _snapshot(
          status: GuardQualificationStatus.ended,
          serviceConnected: false,
          detailCode: 'service_disconnected',
        ),
      ),
      (
        'prerequisite change',
        _snapshot(
          status: GuardQualificationStatus.ended,
          serviceConnected: true,
          detailCode: 'prerequisite_lost',
        ),
      ),
      (
        'unsupported platform change',
        GuardQualificationSnapshot.unavailable(GuardPlatform.windows),
      ),
    ]) {
      test('${change.$1} invalidates a terminal-state draft', () async {
        final service = _FakeService(
          statuses: <Future<GuardQualificationSnapshot> Function()>[
            () => Future.value(
              _snapshot(
                status: GuardQualificationStatus.ended,
                serviceConnected: true,
                detailCode: 'ended_by_user',
              ),
            ),
            () => Future.value(change.$2),
          ],
        );
        final controller = GuardQualificationController(
          readinessService: _Availability(),
          service: service,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);

        await controller.refreshStatus();

        expect(controller.disclosureAccepted, isFalse);
        expect(controller.selection, isEmpty);
        expect(controller.canStart, isFalse);
      });
    }

    test(
      'service reconnection invalidates an interrupted-state draft',
      () async {
        final service = _FakeService(
          statuses: <Future<GuardQualificationSnapshot> Function()>[
            () => Future.value(
              _snapshot(
                status: GuardQualificationStatus.interrupted,
                detailCode: 'service_disconnected',
              ),
            ),
            () => Future.value(
              _snapshot(
                status: GuardQualificationStatus.interrupted,
                serviceConnected: true,
                detailCode: 'service_reconnected',
              ),
            ),
          ],
        );
        final controller = GuardQualificationController(
          readinessService: _Availability(),
          service: service,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);

        await controller.refreshStatus();

        expect(controller.disclosureAccepted, isFalse);
        expect(controller.selection, isEmpty);
      },
    );

    test(
      'an in-flight unchanged terminal poll cannot erase a newer draft',
      () async {
        final ended = _snapshot(
          status: GuardQualificationStatus.ended,
          serviceConnected: true,
          detailCode: 'ended_by_user',
        );
        final pending = Completer<GuardQualificationSnapshot>();
        final service = _FakeService(
          statuses: <Future<GuardQualificationSnapshot> Function()>[
            () => Future.value(ended),
            () => pending.future,
          ],
        );
        final controller = GuardQualificationController(
          readinessService: _Availability(),
          service: service,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();

        final refresh = controller.refreshStatus();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);
        pending.complete(ended);
        await refresh;

        expect(controller.disclosureAccepted, isTrue);
        expect(controller.selection, {GuardQualificationTarget.youtubeApp});
        expect(controller.canStart, isTrue);
      },
    );

    test('does not retry uncertain start and preserves end access', () async {
      final service = _FakeService(
        statuses: <Future<GuardQualificationSnapshot> Function()>[
          () => Future.value(_snapshot(serviceConnected: true)),
          () => Future<GuardQualificationSnapshot>.error(
            StateError('status lost'),
          ),
        ],
      )..startError = StateError('reply lost');
      final controller = GuardQualificationController(
        readinessService: _Availability(),
        service: service,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      controller.acceptDisclosure();
      controller.setSelected(GuardQualificationTarget.youtubeApp, true);

      expect(await controller.start(), isFalse);
      expect(service.startCalls, 1);
      expect(controller.mayBeActive, isTrue);
      expect(controller.message, contains('not retried'));

      service.endResult = Future.value(
        _snapshot(status: GuardQualificationStatus.ended),
      );
      expect(await controller.end(), isTrue);
      expect(service.endCalls, 1);
      expect(controller.mayBeActive, isFalse);
    });

    test('late timed-out replies do not erase uncertainty', () async {
      const channel = MethodChannel(
        MethodChannelGuardQualificationGateway.channelName,
      );
      final lateStart = Completer<Object?>();
      final lateRecovery = Completer<Object?>();
      var statusCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) {
            if (call.method == 'start') return lateStart.future;
            if (call.method == 'getStatus') {
              statusCalls++;
              if (statusCalls == 1) {
                return Future<Object?>.value(_payload(serviceConnected: true));
              }
              if (statusCalls == 2) return lateRecovery.future;
              return Future<Object?>.value(_payload(serviceConnected: true));
            }
            return Future<Object?>.value(null);
          });
      addTearDown(() {
        if (!lateStart.isCompleted) lateStart.complete(_payload());
        if (!lateRecovery.isCompleted) lateRecovery.complete(_payload());
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      final gateway = MethodChannelGuardQualificationGateway(
        channel: channel,
        statusTimeout: const Duration(milliseconds: 10),
        commandTimeout: const Duration(milliseconds: 10),
      );
      final controller = GuardQualificationController(
        readinessService: _Availability(),
        service: DefaultGuardQualificationService(gateway: gateway),
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      controller.acceptDisclosure();
      controller.setSelected(GuardQualificationTarget.youtubeApp, true);

      expect(await controller.start(), isFalse);
      expect(controller.mayBeActive, isTrue);
      expect(controller.commandInProgress, isFalse);
      expect(controller.selection, {GuardQualificationTarget.youtubeApp});

      lateStart.complete(
        _payload(
          status: 'running',
          remainingMillis: 900000,
          targets: <Object?>['youtube_app'],
          serviceConnected: true,
          disclosureAccepted: true,
        ),
      );
      lateRecovery.complete(_payload(serviceConnected: true));
      await Future<void>.delayed(Duration.zero);
      expect(controller.mayBeActive, isTrue);
      expect(controller.snapshot, isNull);

      await controller.refreshStatus();
      expect(controller.mayBeActive, isFalse);
      expect(controller.snapshot?.status, GuardQualificationStatus.idle);
    });

    test('a stale refresh cannot overwrite a newer command result', () async {
      final staleRefresh = Completer<GuardQualificationSnapshot>();
      final running = _snapshot(
        status: GuardQualificationStatus.running,
        remainingMillis: 900000,
        selectedTargets: const {GuardQualificationTarget.youtubeApp},
        serviceConnected: true,
        disclosureAccepted: true,
      );
      final service = _FakeService(
        statuses: <Future<GuardQualificationSnapshot> Function()>[
          () => Future.value(_snapshot(serviceConnected: true)),
          () => staleRefresh.future,
        ],
      )..startResult = Future.value(running);
      final controller = GuardQualificationController(
        readinessService: _Availability(),
        service: service,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      controller.acceptDisclosure();
      controller.setSelected(GuardQualificationTarget.youtubeApp, true);

      final refresh = controller.refreshStatus();
      expect(await controller.start(), isTrue);
      staleRefresh.complete(_snapshot(serviceConnected: true));
      await refresh;

      expect(controller.snapshot?.status, GuardQualificationStatus.running);
      expect(controller.mayBeActive, isTrue);
    });

    test(
      'rejected duplicate start recovers the existing native lease',
      () async {
        final existing = _snapshot(
          status: GuardQualificationStatus.running,
          remainingMillis: 700000,
          selectedTargets: const {GuardQualificationTarget.instagramApp},
          serviceConnected: true,
          disclosureAccepted: true,
        );
        final service = _FakeService(
          statuses: <Future<GuardQualificationSnapshot> Function()>[
            () => Future.value(_snapshot(serviceConnected: true)),
            () => Future.value(existing),
          ],
        )..startError = StateError('already active');
        final controller = GuardQualificationController(
          readinessService: _Availability(),
          service: service,
          pollingInterval: null,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.acceptDisclosure();
        controller.setSelected(GuardQualificationTarget.youtubeApp, true);

        expect(await controller.start(), isFalse);
        expect(controller.snapshot?.status, GuardQualificationStatus.running);
        expect(controller.selection, {GuardQualificationTarget.instagramApp});
        expect(controller.disclosureAccepted, isTrue);
        expect(service.startCalls, 1);
      },
    );

    test('serializes commands and ignores a result after disposal', () async {
      final pending = Completer<GuardQualificationSnapshot>();
      final service = _FakeService(
        statuses: <Future<GuardQualificationSnapshot> Function()>[
          () => Future.value(_snapshot(serviceConnected: true)),
        ],
      )..startResult = pending.future;
      final controller = GuardQualificationController(
        readinessService: _Availability(),
        service: service,
        pollingInterval: null,
      );
      await controller.initialize();
      controller.acceptDisclosure();
      controller.setSelected(GuardQualificationTarget.youtubeApp, true);

      final start = controller.start();
      expect(await controller.pause(), isFalse);
      expect(service.pauseCalls, 0);
      controller.dispose();
      pending.complete(
        _snapshot(
          status: GuardQualificationStatus.running,
          remainingMillis: 900000,
          selectedTargets: const {GuardQualificationTarget.youtubeApp},
          serviceConnected: true,
          disclosureAccepted: true,
        ),
      );
      expect(await start, isFalse);
    });

    test('pause, resume, and refresh retain native authority', () async {
      final running = _snapshot(
        status: GuardQualificationStatus.running,
        remainingMillis: 800000,
        selectedTargets: const {GuardQualificationTarget.youtubeApp},
        serviceConnected: true,
        disclosureAccepted: true,
      );
      final paused = _snapshot(
        status: GuardQualificationStatus.paused,
        remainingMillis: 700000,
        selectedTargets: const {GuardQualificationTarget.youtubeApp},
        serviceConnected: true,
        disclosureAccepted: true,
      );
      final service =
          _FakeService(
              statuses: <Future<GuardQualificationSnapshot> Function()>[
                () => Future.value(running),
                () => Future.value(running),
                () => Future.value(paused),
              ],
            )
            ..pauseResult = Future.value(paused)
            ..resumeResult = Future.value(running);
      final controller = GuardQualificationController(
        readinessService: _Availability(),
        service: service,
        pollingInterval: null,
      );
      addTearDown(controller.dispose);
      await controller.initialize();

      expect(await controller.pause(), isTrue);
      expect(controller.snapshot?.remainingMillis, 700000);
      expect(await controller.resume(), isTrue);
      expect(controller.snapshot?.remainingMillis, 800000);
      await controller.refreshStatus();
      expect(controller.snapshot?.status, GuardQualificationStatus.paused);
    });
  });
}

Map<String, Object?> _payload({
  String status = 'idle',
  int remainingMillis = 0,
  List<Object?> targets = const <Object?>[],
  bool serviceConnected = false,
  bool disclosureAccepted = false,
  String? detailCode,
}) => <String, Object?>{
  'schemaVersion': 1,
  'platform': 'android',
  'status': status,
  'remainingMillis': remainingMillis,
  'selectedTargetIds': targets,
  'serviceConnected': serviceConnected,
  'disclosureAccepted': disclosureAccepted,
  'detailCode': detailCode,
};

GuardQualificationSnapshot _snapshot({
  GuardQualificationStatus status = GuardQualificationStatus.idle,
  int remainingMillis = 0,
  Set<GuardQualificationTarget> selectedTargets = const {},
  bool serviceConnected = false,
  bool disclosureAccepted = false,
  String? detailCode,
}) => GuardQualificationSnapshot(
  platform: GuardPlatform.android,
  status: status,
  remainingMillis: remainingMillis,
  selectedTargets: selectedTargets,
  serviceConnected: serviceConnected,
  disclosureAccepted: disclosureAccepted,
  detailCode: detailCode,
);

class _FakeService implements GuardQualificationService {
  _FakeService({required this.statuses});

  final List<Future<GuardQualificationSnapshot> Function()> statuses;
  Future<GuardQualificationSnapshot>? startResult;
  Object? startError;
  Future<GuardQualificationSnapshot>? pauseResult;
  Future<GuardQualificationSnapshot>? resumeResult;
  Future<GuardQualificationSnapshot>? endResult;
  int statusCalls = 0;
  int startCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int endCalls = 0;
  int settingsCalls = 0;

  @override
  void cancelPending() {}

  @override
  Future<GuardQualificationSnapshot> getStatus() => statuses[statusCalls++]();

  @override
  Future<GuardQualificationSnapshot> start(
    GuardQualificationStartRequest request,
  ) {
    startCalls++;
    if (startError != null) {
      return Future<GuardQualificationSnapshot>.error(startError!);
    }
    return startResult!;
  }

  @override
  Future<GuardQualificationSnapshot> pause() {
    pauseCalls++;
    return pauseResult!;
  }

  @override
  Future<GuardQualificationSnapshot> resume() {
    resumeCalls++;
    return resumeResult!;
  }

  @override
  Future<GuardQualificationSnapshot> end() {
    endCalls++;
    return endResult!;
  }

  @override
  Future<void> openAccessibilitySettings() async {
    settingsCalls++;
  }
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
