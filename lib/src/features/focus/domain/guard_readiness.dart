enum GuardPlatform { android, ios, windows, unknown }

enum GuardTargetKind { wholeApp, feature }

enum GuardTarget {
  youtubeApp(
    id: 'youtube_app',
    label: 'YouTube',
    packageName: 'com.google.android.youtube',
    kind: GuardTargetKind.wholeApp,
  ),
  youtubeShorts(
    id: 'youtube_shorts',
    label: 'YouTube Shorts',
    packageName: 'com.google.android.youtube',
    kind: GuardTargetKind.feature,
  ),
  instagramApp(
    id: 'instagram_app',
    label: 'Instagram',
    packageName: 'com.instagram.android',
    kind: GuardTargetKind.wholeApp,
  ),
  instagramReels(
    id: 'instagram_reels',
    label: 'Instagram Reels',
    packageName: 'com.instagram.android',
    kind: GuardTargetKind.feature,
  ),
  facebookApp(
    id: 'facebook_app',
    label: 'Facebook',
    packageName: 'com.facebook.katana',
    kind: GuardTargetKind.wholeApp,
  ),
  tiktokApp(
    id: 'tiktok_app',
    label: 'TikTok',
    packageName: 'com.zhiliaoapp.musically',
    kind: GuardTargetKind.wholeApp,
  );

  const GuardTarget({
    required this.id,
    required this.label,
    required this.packageName,
    required this.kind,
  });

  final String id;
  final String label;
  final String packageName;
  final GuardTargetKind kind;

  bool supports(GuardPlatform platform) => platform == GuardPlatform.android;
}

class GuardInstalledApp {
  const GuardInstalledApp({
    required this.packageName,
    required this.installed,
    required this.enabled,
    required this.versionName,
    required this.versionCode,
  });

  final String packageName;
  final bool installed;
  final bool enabled;
  final String? versionName;
  final int? versionCode;
}

class GuardProbeSnapshot {
  GuardProbeSnapshot({
    required this.platform,
    required Iterable<GuardInstalledApp> apps,
  }) : apps = List.unmodifiable(apps);

  final GuardPlatform platform;
  final List<GuardInstalledApp> apps;
}

abstract interface class GuardReadinessProbe {
  Future<GuardProbeSnapshot> probe();
}

class GuardQualificationRecord {
  const GuardQualificationRecord({
    required this.target,
    required this.platform,
    required this.packageName,
    required this.versionCode,
    required this.implementationId,
    this.versionName,
  });

  final GuardTarget target;
  final GuardPlatform platform;
  final String packageName;
  final int versionCode;
  final String? versionName;
  final String implementationId;
}

enum GuardReadinessState {
  probeFailed,
  unsupportedPlatform,
  notInstalled,
  disabled,
  versionUnknown,
  versionUnqualified,
  enforcementUnavailable,
  ready,
}

class GuardTargetReadiness {
  const GuardTargetReadiness({
    required this.target,
    required this.state,
    this.versionName,
    this.versionCode,
  });

  final GuardTarget target;
  final GuardReadinessState state;
  final String? versionName;
  final int? versionCode;
}

class GuardReadinessReport {
  GuardReadinessReport({
    required this.platform,
    required Iterable<GuardTargetReadiness> targets,
  }) : targets = List.unmodifiable(targets);

  factory GuardReadinessReport.probeFailed({
    GuardPlatform platform = GuardPlatform.unknown,
  }) => GuardReadinessReport(
    platform: platform,
    targets: GuardTarget.values.map(
      (target) => GuardTargetReadiness(
        target: target,
        state: GuardReadinessState.probeFailed,
      ),
    ),
  );

  final GuardPlatform platform;
  final List<GuardTargetReadiness> targets;

  bool get hasProbeFailure =>
      targets.any((target) => target.state == GuardReadinessState.probeFailed);

  bool get hasReadyTarget =>
      targets.any((target) => target.state == GuardReadinessState.ready);
}

class GuardReadinessEvaluator {
  const GuardReadinessEvaluator({
    this.qualificationRecords = const <GuardQualificationRecord>[],
    this.availableImplementationIds = const <String>{},
  });

  final List<GuardQualificationRecord> qualificationRecords;
  final Set<String> availableImplementationIds;

  GuardReadinessReport evaluate(GuardProbeSnapshot snapshot) {
    final apps = <String, GuardInstalledApp>{};
    for (final app in snapshot.apps) {
      if (!_knownPackages.contains(app.packageName) ||
          apps.containsKey(app.packageName) ||
          !_isConsistent(app)) {
        return GuardReadinessReport.probeFailed(platform: snapshot.platform);
      }
      apps[app.packageName] = app;
    }

    if (snapshot.platform == GuardPlatform.android &&
        !apps.keys.toSet().containsAll(_knownPackages)) {
      return GuardReadinessReport.probeFailed(platform: snapshot.platform);
    }

    return GuardReadinessReport(
      platform: snapshot.platform,
      targets: GuardTarget.values.map(
        (target) => _evaluateTarget(snapshot.platform, target, apps),
      ),
    );
  }

  GuardTargetReadiness _evaluateTarget(
    GuardPlatform platform,
    GuardTarget target,
    Map<String, GuardInstalledApp> apps,
  ) {
    if (!target.supports(platform)) {
      return GuardTargetReadiness(
        target: target,
        state: GuardReadinessState.unsupportedPlatform,
      );
    }

    final app = apps[target.packageName];
    if (app == null) {
      return GuardTargetReadiness(
        target: target,
        state: GuardReadinessState.probeFailed,
      );
    }
    if (!app.installed) {
      return GuardTargetReadiness(
        target: target,
        state: GuardReadinessState.notInstalled,
      );
    }
    if (!app.enabled) {
      return GuardTargetReadiness(
        target: target,
        state: GuardReadinessState.disabled,
        versionName: app.versionName,
        versionCode: app.versionCode,
      );
    }
    if (app.versionCode == null ||
        app.versionName == null ||
        app.versionName!.trim().isEmpty) {
      return GuardTargetReadiness(
        target: target,
        state: GuardReadinessState.versionUnknown,
        versionName: app.versionName,
        versionCode: app.versionCode,
      );
    }

    final matches = qualificationRecords.where(
      (record) =>
          record.target == target &&
          record.platform == platform &&
          record.packageName == app.packageName &&
          record.versionCode == app.versionCode &&
          (record.versionName == null || record.versionName == app.versionName),
    );
    if (matches.length != 1) {
      return GuardTargetReadiness(
        target: target,
        state: GuardReadinessState.versionUnqualified,
        versionName: app.versionName,
        versionCode: app.versionCode,
      );
    }

    final qualification = matches.single;
    if (qualification.implementationId.trim().isEmpty ||
        !availableImplementationIds.contains(qualification.implementationId)) {
      return GuardTargetReadiness(
        target: target,
        state: GuardReadinessState.enforcementUnavailable,
        versionName: app.versionName,
        versionCode: app.versionCode,
      );
    }

    return GuardTargetReadiness(
      target: target,
      state: GuardReadinessState.ready,
      versionName: app.versionName,
      versionCode: app.versionCode,
    );
  }

  static bool _isConsistent(GuardInstalledApp app) {
    if (!app.installed) {
      return !app.enabled && app.versionName == null && app.versionCode == null;
    }
    return app.versionCode == null || app.versionCode! >= 0;
  }

  static const _knownPackages = <String>{
    'com.google.android.youtube',
    'com.instagram.android',
    'com.facebook.katana',
    'com.zhiliaoapp.musically',
  };
}
