import '../../../../services/bible_version_repository.dart';
import '../domain/bible_translation.dart';
import '../domain/translation_state.dart';
import 'local/word_translation_state_dao.dart';

class DriftBibleVersionRepository extends BibleVersionRepository {
  DriftBibleVersionRepository(
    this.dao, {
    super.httpClient,
    super.kjvFileProvider,
    super.archiveConverter,
  });

  final WordTranslationStateDao dao;

  @override
  Future<Set<BibleTranslation>> loadInstalled() async {
    final state = await loadTranslationState();
    return <BibleTranslation>{
      if (state.installations[BibleTranslation.kjv]?.isInstalled ?? false)
        BibleTranslation.kjv,
      ...state.onlineEnabled,
    };
  }

  @override
  Future<TranslationRepositoryState> loadTranslationState() async {
    final installations = await dao.loadInstallationStates();
    final onlineEnabled = await dao.loadOnlineEnabled();
    final persisted = installations[BibleTranslation.kjv];
    final completeKjv = await isKjvInstalled();

    TranslationInstallationState? reconciled = persisted;
    if (completeKjv) {
      reconciled = TranslationInstallationState(
        status: TranslationInstallationStatus.installed,
        updatedAt: DateTime.now().toUtc(),
      );
    } else if (persisted?.status == TranslationInstallationStatus.installed) {
      reconciled = TranslationInstallationState(
        status: TranslationInstallationStatus.failed,
        failureCode: 'content_missing',
        updatedAt: DateTime.now().toUtc(),
      );
    } else if (persisted?.status == TranslationInstallationStatus.downloading ||
        persisted?.status == TranslationInstallationStatus.processing) {
      reconciled = TranslationInstallationState(
        status: TranslationInstallationStatus.failed,
        failureCode: 'installation_interrupted',
        updatedAt: DateTime.now().toUtc(),
      );
    }

    final needsReconciliation =
        reconciled != null &&
        (persisted == null ||
            persisted.status != reconciled.status ||
            persisted.failureCode != reconciled.failureCode);
    if (needsReconciliation) {
      await dao.saveInstallationState(BibleTranslation.kjv, reconciled);
    }
    return TranslationRepositoryState(
      installations: reconciled == null
          ? <BibleTranslation, TranslationInstallationState>{}
          : <BibleTranslation, TranslationInstallationState>{
              BibleTranslation.kjv: reconciled,
            },
      onlineEnabled: onlineEnabled,
    );
  }

  @override
  Future<void> saveInstalled(Set<BibleTranslation> translations) async {
    await dao.replaceEnabled(
      translations,
      verifiedCompleteKjvFile: await isKjvInstalled(),
    );
  }

  @override
  Future<void> saveInstallationState(
    BibleTranslation translation,
    TranslationInstallationState state,
  ) => dao.saveInstallationState(translation, state);
}
