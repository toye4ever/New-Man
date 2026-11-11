import 'guard_readiness.dart';

enum GuardQualificationTarget {
  youtubeApp(
    id: 'youtube_app',
    label: 'YouTube',
    packageName: 'com.google.android.youtube',
  ),
  instagramApp(
    id: 'instagram_app',
    label: 'Instagram',
    packageName: 'com.instagram.android',
  ),
  facebookApp(
    id: 'facebook_app',
    label: 'Facebook',
    packageName: 'com.facebook.katana',
  ),
  tiktokApp(
    id: 'tiktok_app',
    label: 'TikTok',
    packageName: 'com.zhiliaoapp.musically',
  );

  const GuardQualificationTarget({
    required this.id,
    required this.label,
    required this.packageName,
  });

  final String id;
  final String label;
  final String packageName;
}

enum GuardQualificationStatus {
  idle,
  running,
  paused,
  completed,
  ended,
  interrupted,
  error,
  unavailable,
}

class GuardQualificationSnapshot {
  GuardQualificationSnapshot({
    required this.platform,
    required this.status,
    required this.remainingMillis,
    required Iterable<GuardQualificationTarget> selectedTargets,
    required this.serviceConnected,
    required this.disclosureAccepted,
    required this.detailCode,
  }) : selectedTargets = Set.unmodifiable(selectedTargets);

  factory GuardQualificationSnapshot.unavailable(GuardPlatform platform) =>
      GuardQualificationSnapshot(
        platform: platform,
        status: GuardQualificationStatus.unavailable,
        remainingMillis: 0,
        selectedTargets: const <GuardQualificationTarget>{},
        serviceConnected: false,
        disclosureAccepted: false,
        detailCode: 'platform_unsupported',
      );

  final GuardPlatform platform;
  final GuardQualificationStatus status;
  final int remainingMillis;
  final Set<GuardQualificationTarget> selectedTargets;
  final bool serviceConnected;
  final bool disclosureAccepted;
  final String? detailCode;

  bool get isActive =>
      status == GuardQualificationStatus.running ||
      status == GuardQualificationStatus.paused;

  bool get isSupported => platform == GuardPlatform.android;
}

class GuardQualificationStartRequest {
  GuardQualificationStartRequest({
    required Iterable<GuardQualificationTarget> selectedTargets,
    required this.durationMinutes,
    required this.disclosureAccepted,
  }) : selectedTargets = Set.unmodifiable(selectedTargets);

  final Set<GuardQualificationTarget> selectedTargets;
  final int durationMinutes;
  final bool disclosureAccepted;
}

abstract interface class GuardQualificationGateway {
  Future<GuardQualificationSnapshot> getStatus();

  Future<GuardQualificationSnapshot> start(
    GuardQualificationStartRequest request,
  );

  Future<GuardQualificationSnapshot> pause();

  Future<GuardQualificationSnapshot> resume();

  Future<GuardQualificationSnapshot> end();

  Future<void> openAccessibilitySettings();
}

class GuardQualificationUnavailable implements Exception {
  const GuardQualificationUnavailable(this.message);

  final String message;

  @override
  String toString() => 'GuardQualificationUnavailable: $message';
}
