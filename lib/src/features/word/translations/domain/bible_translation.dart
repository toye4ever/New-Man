enum BibleTranslation { kjv, nlt }

enum TranslationCapability {
  offlineDownloadable,
  onlineAvailable,
  textToSpeech,
}

class BibleTranslationDefinition {
  const BibleTranslationDefinition({
    required this.translation,
    required this.displayName,
    required this.abbreviation,
    required this.languageCode,
    required this.providerId,
    required this.capabilities,
    this.attribution,
  });

  final BibleTranslation translation;
  final String displayName;
  final String abbreviation;
  final String languageCode;
  final String providerId;
  final Set<TranslationCapability> capabilities;
  final String? attribution;

  bool get supportsOfflineDownload =>
      capabilities.contains(TranslationCapability.offlineDownloadable);
  bool get supportsOnline =>
      capabilities.contains(TranslationCapability.onlineAvailable);
  bool get supportsTextToSpeech =>
      capabilities.contains(TranslationCapability.textToSpeech);
}

const translationCatalog = <BibleTranslationDefinition>[
  BibleTranslationDefinition(
    translation: BibleTranslation.kjv,
    displayName: 'King James Version',
    abbreviation: 'KJV',
    languageCode: 'en',
    providerId: 'ebible-kjv-vpl',
    capabilities: {
      TranslationCapability.offlineDownloadable,
      TranslationCapability.textToSpeech,
    },
    attribution: 'Public-domain KJV package provided by eBible.org.',
  ),
  BibleTranslationDefinition(
    translation: BibleTranslation.nlt,
    displayName: 'New Living Translation',
    abbreviation: 'NLT',
    languageCode: 'en',
    providerId: 'tyndale-nlt-api',
    capabilities: {
      TranslationCapability.onlineAvailable,
      TranslationCapability.textToSpeech,
    },
    attribution:
        'Online text is provided under Tyndale\'s applicable API and licensing terms.',
  ),
];

extension BibleTranslationLabel on BibleTranslation {
  BibleTranslationDefinition get definition =>
      translationCatalog.singleWhere((entry) => entry.translation == this);

  String get label => definition.displayName;

  String get shortLabel => definition.abbreviation;

  bool get supportsFullOfflineInstall => definition.supportsOfflineDownload;
}
