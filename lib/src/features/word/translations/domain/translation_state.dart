import 'bible_translation.dart';

enum TranslationInstallationStatus {
  notInstalled,
  downloading,
  processing,
  installed,
  failed,
}

class TranslationInstallationState {
  const TranslationInstallationState({
    required this.status,
    this.progress,
    this.failureCode,
    this.updatedAt,
  }) : assert(progress == null || (progress >= 0 && progress <= 1));

  const TranslationInstallationState.notInstalled()
    : this(status: TranslationInstallationStatus.notInstalled);

  final TranslationInstallationStatus status;
  final double? progress;
  final String? failureCode;
  final DateTime? updatedAt;

  bool get isInstalled => status == TranslationInstallationStatus.installed;
}

class TranslationRepositoryState {
  const TranslationRepositoryState({
    required this.installations,
    required this.onlineEnabled,
  });

  final Map<BibleTranslation, TranslationInstallationState> installations;
  final Set<BibleTranslation> onlineEnabled;
}

enum TranslationAvailabilityKind {
  installedOffline,
  downloadAvailable,
  downloading,
  processing,
  failed,
  online,
  setupRequired,
}

class TranslationAvailability {
  const TranslationAvailability({
    required this.definition,
    required this.kind,
    this.progress,
    this.failureCode,
  });

  final BibleTranslationDefinition definition;
  final TranslationAvailabilityKind kind;
  final double? progress;
  final String? failureCode;

  bool get isUsable =>
      kind == TranslationAvailabilityKind.installedOffline ||
      kind == TranslationAvailabilityKind.online;

  bool get canInstall =>
      definition.supportsOfflineDownload &&
      (kind == TranslationAvailabilityKind.downloadAvailable ||
          kind == TranslationAvailabilityKind.failed);

  bool get isBusy =>
      kind == TranslationAvailabilityKind.downloading ||
      kind == TranslationAvailabilityKind.processing;

  String get shortStatus => switch (kind) {
    TranslationAvailabilityKind.installedOffline => 'Installed',
    TranslationAvailabilityKind.downloadAvailable => 'Download available',
    TranslationAvailabilityKind.downloading => 'Downloading',
    TranslationAvailabilityKind.processing => 'Processing',
    TranslationAvailabilityKind.failed => 'Install failed',
    TranslationAvailabilityKind.online => 'Online',
    TranslationAvailabilityKind.setupRequired => 'Setup required',
  };
}
