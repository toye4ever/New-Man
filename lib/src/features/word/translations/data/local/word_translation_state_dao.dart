import 'package:drift/drift.dart';

import '../../../../../core/database/app_database.dart';
import '../../domain/bible_translation.dart';
import '../../domain/translation_state.dart';

class WordTranslationStateDao {
  const WordTranslationStateDao(this.database);

  final AppDatabase database;

  Future<Set<BibleTranslation>> loadEnabled() async {
    final rows = await database.select(database.wordTranslationStates).get();
    return rows
        .where((row) => row.state == 'installed' || row.state == 'enabled')
        .map((row) => BibleTranslation.values.byName(row.translationId))
        .toSet();
  }

  Future<Map<BibleTranslation, TranslationInstallationState>>
  loadInstallationStates() async {
    final rows = await (database.select(
      database.wordTranslationStates,
    )..where((row) => row.translationId.equals('kjv'))).get();
    return <BibleTranslation, TranslationInstallationState>{
      for (final row in rows)
        BibleTranslation.kjv: TranslationInstallationState(
          status: _installationStatus(row.state),
          progress: row.downloadProgressPermille == null
              ? null
              : row.downloadProgressPermille! / 1000,
          failureCode: row.failureCode,
          updatedAt: row.updatedAtUtcMicros == null
              ? null
              : DateTime.fromMicrosecondsSinceEpoch(
                  row.updatedAtUtcMicros!,
                  isUtc: true,
                ),
        ),
    };
  }

  Future<Set<BibleTranslation>> loadOnlineEnabled() async {
    final rows = await (database.select(
      database.wordTranslationStates,
    )..where((row) => row.state.equals('enabled'))).get();
    return rows
        .map((row) => BibleTranslation.values.byName(row.translationId))
        .toSet();
  }

  Future<void> replaceEnabled(
    Set<BibleTranslation> translations, {
    required bool verifiedCompleteKjvFile,
  }) async {
    await database.transaction(() async {
      await database.delete(database.wordTranslationStates).go();
      if (verifiedCompleteKjvFile &&
          translations.contains(BibleTranslation.kjv)) {
        await insertState(
          translationId: 'kjv',
          accessMode: 'offline',
          state: 'installed',
          managedRelativePath: 'bibles/kjv.json',
        );
      }
      if (translations.contains(BibleTranslation.nlt)) {
        await insertState(
          translationId: 'nlt',
          accessMode: 'online',
          state: 'enabled',
        );
      }
    });
  }

  Future<void> insertState({
    required String translationId,
    required String accessMode,
    required String state,
    String? installedVersion,
    String? managedRelativePath,
    int? updatedAtUtcMicros,
    String? failureCode,
    int? downloadProgressPermille,
  }) => database
      .into(database.wordTranslationStates)
      .insert(
        WordTranslationStatesCompanion.insert(
          translationId: translationId,
          accessMode: accessMode,
          state: state,
          installedVersion: Value(installedVersion),
          managedRelativePath: Value(managedRelativePath),
          updatedAtUtcMicros: Value(updatedAtUtcMicros),
          failureCode: Value(failureCode),
          downloadProgressPermille: Value(downloadProgressPermille),
        ),
        mode: InsertMode.insertOrReplace,
      );

  Future<void> saveInstallationState(
    BibleTranslation translation,
    TranslationInstallationState state,
  ) async {
    if (translation != BibleTranslation.kjv) {
      throw ArgumentError('Only downloadable translations have install state.');
    }
    if (state.status == TranslationInstallationStatus.notInstalled) {
      await (database.delete(
        database.wordTranslationStates,
      )..where((row) => row.translationId.equals(translation.name))).go();
      return;
    }
    await insertState(
      translationId: translation.name,
      accessMode: 'offline',
      state: _persistedState(state.status),
      managedRelativePath:
          state.status == TranslationInstallationStatus.installed
          ? 'bibles/kjv.json'
          : null,
      updatedAtUtcMicros:
          (state.updatedAt ?? DateTime.now().toUtc()).microsecondsSinceEpoch,
      failureCode: state.status == TranslationInstallationStatus.failed
          ? state.failureCode ?? 'installation_failed'
          : null,
      downloadProgressPermille:
          state.status == TranslationInstallationStatus.downloading &&
              state.progress != null
          ? (state.progress! * 1000).round()
          : null,
    );
  }
}

TranslationInstallationStatus _installationStatus(String value) =>
    switch (value) {
      'downloading' => TranslationInstallationStatus.downloading,
      'processing' => TranslationInstallationStatus.processing,
      'installed' => TranslationInstallationStatus.installed,
      'failed' => TranslationInstallationStatus.failed,
      _ => throw StateError('Invalid persisted KJV installation state.'),
    };

String _persistedState(TranslationInstallationStatus status) =>
    switch (status) {
      TranslationInstallationStatus.downloading => 'downloading',
      TranslationInstallationStatus.processing => 'processing',
      TranslationInstallationStatus.installed => 'installed',
      TranslationInstallationStatus.failed => 'failed',
      TranslationInstallationStatus.notInstalled => throw ArgumentError(
        'Not-installed state is represented by no row.',
      ),
    };
