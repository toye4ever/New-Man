import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/guard_readiness.dart';

GuardReadinessProbe createGuardReadinessProbe({MethodChannel? channel}) {
  final platform = _guardPlatform();
  if (platform != GuardPlatform.android) {
    return UnsupportedGuardReadinessProbe(platform);
  }
  return MethodChannelGuardReadinessProbe(channel: channel);
}

class UnsupportedGuardReadinessProbe implements GuardReadinessProbe {
  const UnsupportedGuardReadinessProbe(this.platform);

  final GuardPlatform platform;

  @override
  Future<GuardProbeSnapshot> probe() async =>
      GuardProbeSnapshot(platform: platform, apps: const []);
}

class MethodChannelGuardReadinessProbe implements GuardReadinessProbe {
  MethodChannelGuardReadinessProbe({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.newman.newmanapp/guard_readiness';

  final MethodChannel _channel;

  @override
  Future<GuardProbeSnapshot> probe() async {
    final currentPlatform = _guardPlatform();
    if (currentPlatform != GuardPlatform.android) {
      return GuardProbeSnapshot(platform: currentPlatform, apps: const []);
    }
    final payload = await _channel.invokeMethod<Object?>('getReadiness');
    if (payload is! Map<Object?, Object?> ||
        payload.keys.toSet().difference(_envelopeKeys).isNotEmpty ||
        _envelopeKeys.difference(payload.keys.toSet()).isNotEmpty ||
        payload['schemaVersion'] != 1 ||
        payload['platform'] != 'android') {
      throw const FormatException('Invalid Guard readiness envelope.');
    }
    final rawApps = payload['apps'];
    if (rawApps is! List<Object?>) {
      throw const FormatException('Invalid Guard readiness apps.');
    }

    final apps = rawApps.map(_decodeApp).toList(growable: false);
    final packages = apps.map((app) => app.packageName).toSet();
    if (apps.length != _expectedPackages.length ||
        packages.length != apps.length ||
        !packages.containsAll(_expectedPackages)) {
      throw const FormatException('Unexpected Guard readiness packages.');
    }
    return GuardProbeSnapshot(platform: GuardPlatform.android, apps: apps);
  }

  GuardInstalledApp _decodeApp(Object? value) {
    if (value is! Map<Object?, Object?> ||
        value.keys.toSet().difference(_appKeys).isNotEmpty ||
        _appKeys.difference(value.keys.toSet()).isNotEmpty) {
      throw const FormatException('Invalid Guard readiness app.');
    }
    final packageName = value['packageName'];
    final installed = value['installed'];
    final enabled = value['enabled'];
    final versionName = value['versionName'];
    final versionCode = value['versionCode'];
    if (packageName is! String ||
        !_expectedPackages.contains(packageName) ||
        installed is! bool ||
        enabled is! bool ||
        (versionName != null && versionName is! String) ||
        (versionCode != null && versionCode is! int)) {
      throw const FormatException('Invalid Guard readiness app fields.');
    }
    final app = GuardInstalledApp(
      packageName: packageName,
      installed: installed,
      enabled: enabled,
      versionName: versionName as String?,
      versionCode: versionCode as int?,
    );
    if ((!installed &&
            (enabled || versionName != null || versionCode != null)) ||
        (versionCode != null && versionCode < 0)) {
      throw const FormatException('Inconsistent Guard readiness app.');
    }
    return app;
  }

  static const _expectedPackages = <String>{
    'com.google.android.youtube',
    'com.instagram.android',
    'com.facebook.katana',
    'com.zhiliaoapp.musically',
  };
  static const _envelopeKeys = <Object?>{'schemaVersion', 'platform', 'apps'};
  static const _appKeys = <Object?>{
    'packageName',
    'installed',
    'enabled',
    'versionName',
    'versionCode',
  };
}

GuardPlatform _guardPlatform() {
  if (kIsWeb) return GuardPlatform.unknown;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => GuardPlatform.android,
    TargetPlatform.iOS => GuardPlatform.ios,
    TargetPlatform.windows => GuardPlatform.windows,
    _ => GuardPlatform.unknown,
  };
}
