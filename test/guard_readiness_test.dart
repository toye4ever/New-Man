import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/focus/application/guard_readiness_service.dart';
import 'package:scripture_planner/src/features/focus/domain/guard_readiness.dart';
import 'package:scripture_planner/src/features/focus/platform/method_channel_guard_readiness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuardReadinessEvaluator', () {
    test('production defaults never qualify installed targets', () {
      final report = const GuardReadinessEvaluator().evaluate(
        _androidSnapshot(),
      );

      expect(report.hasReadyTarget, isFalse);
      expect(
        report.targets.map((target) => target.state),
        everyElement(GuardReadinessState.versionUnqualified),
      );
      expect(
        () => report.targets.add(report.targets.first),
        throwsUnsupportedError,
      );
    });

    test(
      'qualification is exact to target, package, platform, and version',
      () {
        const qualification = GuardQualificationRecord(
          target: GuardTarget.youtubeShorts,
          platform: GuardPlatform.android,
          packageName: 'com.google.android.youtube',
          versionName: '20.40.1',
          versionCode: 204001,
          implementationId: 'android-youtube-shorts-v1',
        );
        const evaluator = GuardReadinessEvaluator(
          qualificationRecords: <GuardQualificationRecord>[qualification],
          availableImplementationIds: <String>{'android-youtube-shorts-v1'},
        );

        final report = evaluator.evaluate(_androidSnapshot());
        expect(
          _stateOf(report, GuardTarget.youtubeShorts),
          GuardReadinessState.ready,
        );
        expect(
          _stateOf(report, GuardTarget.youtubeApp),
          GuardReadinessState.versionUnqualified,
        );
        expect(
          _stateOf(
            evaluator.evaluate(_androidSnapshot(youtubeCode: 204002)),
            GuardTarget.youtubeShorts,
          ),
          GuardReadinessState.versionUnqualified,
        );
        expect(
          _stateOf(
            evaluator.evaluate(_androidSnapshot(youtubeName: '20.40.2')),
            GuardTarget.youtubeShorts,
          ),
          GuardReadinessState.versionUnqualified,
        );
      },
    );

    test('qualification without its implementation stays unavailable', () {
      const evaluator = GuardReadinessEvaluator(
        qualificationRecords: <GuardQualificationRecord>[
          GuardQualificationRecord(
            target: GuardTarget.instagramReels,
            platform: GuardPlatform.android,
            packageName: 'com.instagram.android',
            versionCode: 401,
            implementationId: 'missing-implementation',
          ),
        ],
      );

      expect(
        _stateOf(
          evaluator.evaluate(_androidSnapshot()),
          GuardTarget.instagramReels,
        ),
        GuardReadinessState.enforcementUnavailable,
      );
    });

    test('new whole-app qualifications reject cross-package mappings', () {
      const evaluator = GuardReadinessEvaluator(
        qualificationRecords: <GuardQualificationRecord>[
          GuardQualificationRecord(
            target: GuardTarget.facebookApp,
            platform: GuardPlatform.android,
            packageName: 'com.zhiliaoapp.musically',
            versionCode: 360,
            implementationId: 'cross-mapped',
          ),
          GuardQualificationRecord(
            target: GuardTarget.tiktokApp,
            platform: GuardPlatform.android,
            packageName: 'com.ss.android.ugc.trill',
            versionCode: 360,
            implementationId: 'regional-alias',
          ),
        ],
        availableImplementationIds: <String>{'cross-mapped', 'regional-alias'},
      );

      final report = evaluator.evaluate(_androidSnapshot());
      expect(
        _stateOf(report, GuardTarget.facebookApp),
        GuardReadinessState.versionUnqualified,
      );
      expect(
        _stateOf(report, GuardTarget.tiktokApp),
        GuardReadinessState.versionUnqualified,
      );
      expect(report.hasReadyTarget, isFalse);
    });

    test('reports unsupported, missing, disabled, and unknown versions', () {
      final unsupported = const GuardReadinessEvaluator().evaluate(
        GuardProbeSnapshot(platform: GuardPlatform.windows, apps: const []),
      );
      expect(
        unsupported.targets.map((target) => target.state),
        everyElement(GuardReadinessState.unsupportedPlatform),
      );

      final report = const GuardReadinessEvaluator().evaluate(
        GuardProbeSnapshot(
          platform: GuardPlatform.android,
          apps: const <GuardInstalledApp>[
            GuardInstalledApp(
              packageName: 'com.google.android.youtube',
              installed: false,
              enabled: false,
              versionName: null,
              versionCode: null,
            ),
            GuardInstalledApp(
              packageName: 'com.instagram.android',
              installed: true,
              enabled: false,
              versionName: null,
              versionCode: null,
            ),
            GuardInstalledApp(
              packageName: 'com.facebook.katana',
              installed: false,
              enabled: false,
              versionName: null,
              versionCode: null,
            ),
            GuardInstalledApp(
              packageName: 'com.zhiliaoapp.musically',
              installed: true,
              enabled: false,
              versionName: '36.0.0',
              versionCode: 360,
            ),
          ],
        ),
      );
      expect(
        _stateOf(report, GuardTarget.youtubeApp),
        GuardReadinessState.notInstalled,
      );
      expect(
        _stateOf(report, GuardTarget.instagramApp),
        GuardReadinessState.disabled,
      );
      expect(
        _stateOf(report, GuardTarget.facebookApp),
        GuardReadinessState.notInstalled,
      );
      expect(
        _stateOf(report, GuardTarget.tiktokApp),
        GuardReadinessState.disabled,
      );

      final unknown = const GuardReadinessEvaluator().evaluate(
        _androidSnapshot(youtubeName: null),
      );
      expect(
        _stateOf(unknown, GuardTarget.youtubeShorts),
        GuardReadinessState.versionUnknown,
      );
    });

    test(
      'rejects duplicate, unknown, missing, or inconsistent app entries',
      () {
        final evaluator = const GuardReadinessEvaluator();
        final invalidSnapshots = <GuardProbeSnapshot>[
          GuardProbeSnapshot(
            platform: GuardPlatform.android,
            apps: <GuardInstalledApp>[
              ..._androidSnapshot().apps,
              _androidSnapshot().apps.first,
            ],
          ),
          GuardProbeSnapshot(
            platform: GuardPlatform.android,
            apps: const <GuardInstalledApp>[
              GuardInstalledApp(
                packageName: 'unknown.package',
                installed: false,
                enabled: false,
                versionName: null,
                versionCode: null,
              ),
            ],
          ),
          GuardProbeSnapshot(
            platform: GuardPlatform.android,
            apps: <GuardInstalledApp>[_androidSnapshot().apps.first],
          ),
          GuardProbeSnapshot(
            platform: GuardPlatform.android,
            apps: const <GuardInstalledApp>[
              GuardInstalledApp(
                packageName: 'com.google.android.youtube',
                installed: false,
                enabled: true,
                versionName: null,
                versionCode: null,
              ),
            ],
          ),
        ];

        for (final snapshot in invalidSnapshots) {
          expect(evaluator.evaluate(snapshot).hasProbeFailure, isTrue);
        }
      },
    );
  });

  group('MethodChannelGuardReadinessProbe', () {
    const channel = MethodChannel(MethodChannelGuardReadinessProbe.channelName);

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('decodes only the four fixed Android package reports', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'getReadiness');
            return _validPayload();
          });

      final snapshot = await MethodChannelGuardReadinessProbe(
        channel: channel,
      ).probe();
      expect(snapshot.platform, GuardPlatform.android);
      expect(
        snapshot.apps.map((app) => app.packageName),
        containsAll(<String>[
          'com.google.android.youtube',
          'com.instagram.android',
          'com.facebook.katana',
          'com.zhiliaoapp.musically',
        ]),
      );
      expect(snapshot.apps.first.versionCode, 204001);
    });

    test(
      'rejects malformed, duplicate, unknown, and missing payloads',
      () async {
        final malformedPayloads = <Object?>[
          null,
          <String, Object?>{
            'schemaVersion': 2,
            'platform': 'android',
            'apps': [],
          },
          <String, Object?>{
            'schemaVersion': 1,
            'platform': 'android',
            'apps': <Object?>[
              ...(_validPayload()['apps']! as List<Object?>),
              (_validPayload()['apps']! as List<Object?>).first,
            ],
          },
          <String, Object?>{
            'schemaVersion': 1,
            'platform': 'android',
            'apps': <Object?>[
              <String, Object?>{
                'packageName': 'unknown.package',
                'installed': false,
                'enabled': false,
                'versionName': null,
                'versionCode': null,
              },
              ...(_validPayload()['apps']! as List<Object?>).skip(1),
            ],
          },
          <String, Object?>{
            'schemaVersion': 1,
            'platform': 'android',
            'apps': <Object?>[
              <String, Object?>{
                'packageName': 'com.google.android.youtube',
                'installed': true,
                'enabled': true,
                'versionName': '20.40.1',
              },
              ...(_validPayload()['apps']! as List<Object?>).skip(1),
            ],
          },
          <String, Object?>{..._validPayload(), 'unexpected': true},
          <String, Object?>{
            ..._validPayload(),
            'apps': <Object?>[
              <String, Object?>{
                ...((_validPayload()['apps']! as List<Object?>).first
                    as Map<String, Object?>),
                'unexpected': true,
              },
              ...(_validPayload()['apps']! as List<Object?>).skip(1),
            ],
          },
        ];

        for (final payload in malformedPayloads) {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (_) async => payload);
          await expectLater(
            MethodChannelGuardReadinessProbe(channel: channel).probe(),
            throwsFormatException,
          );
        }
      },
    );

    test(
      'production factory returns unsupported without a native call',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        var calls = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (_) async {
              calls++;
              return _validPayload();
            });

        final report = await createGuardReadinessService().checkReadiness();

        expect(report.platform, GuardPlatform.windows);
        expect(
          report.targets.map((target) => target.state),
          everyElement(GuardReadinessState.unsupportedPlatform),
        );
        expect(calls, 0);
      },
    );
  });

  test(
    'application service converts platform failures to unavailable',
    () async {
      final report = await DefaultGuardReadinessService(
        probe: _ThrowingProbe(),
      ).checkReadiness();
      expect(report.hasProbeFailure, isTrue);
      expect(report.hasReadyTarget, isFalse);
    },
  );
}

GuardProbeSnapshot _androidSnapshot({
  String? youtubeName = '20.40.1',
  int youtubeCode = 204001,
}) => GuardProbeSnapshot(
  platform: GuardPlatform.android,
  apps: <GuardInstalledApp>[
    GuardInstalledApp(
      packageName: 'com.google.android.youtube',
      installed: true,
      enabled: true,
      versionName: youtubeName,
      versionCode: youtubeCode,
    ),
    const GuardInstalledApp(
      packageName: 'com.instagram.android',
      installed: true,
      enabled: true,
      versionName: '401.0.0',
      versionCode: 401,
    ),
    const GuardInstalledApp(
      packageName: 'com.facebook.katana',
      installed: true,
      enabled: true,
      versionName: '500.0.0',
      versionCode: 500,
    ),
    const GuardInstalledApp(
      packageName: 'com.zhiliaoapp.musically',
      installed: true,
      enabled: true,
      versionName: '36.0.0',
      versionCode: 360,
    ),
  ],
);

GuardReadinessState _stateOf(GuardReadinessReport report, GuardTarget target) =>
    report.targets.singleWhere((item) => item.target == target).state;

Map<String, Object?> _validPayload() => <String, Object?>{
  'schemaVersion': 1,
  'platform': 'android',
  'apps': <Object?>[
    <String, Object?>{
      'packageName': 'com.google.android.youtube',
      'installed': true,
      'enabled': true,
      'versionName': '20.40.1',
      'versionCode': 204001,
    },
    <String, Object?>{
      'packageName': 'com.instagram.android',
      'installed': false,
      'enabled': false,
      'versionName': null,
      'versionCode': null,
    },
    <String, Object?>{
      'packageName': 'com.facebook.katana',
      'installed': true,
      'enabled': true,
      'versionName': '500.0.0',
      'versionCode': 500,
    },
    <String, Object?>{
      'packageName': 'com.zhiliaoapp.musically',
      'installed': true,
      'enabled': true,
      'versionName': '36.0.0',
      'versionCode': 360,
    },
  ],
};

class _ThrowingProbe implements GuardReadinessProbe {
  @override
  Future<GuardProbeSnapshot> probe() => throw StateError('unavailable');
}
