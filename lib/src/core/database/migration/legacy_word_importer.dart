import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/word/plans/data/local/word_plan_dao.dart';
import '../../../features/word/plans/data/migration/legacy_word_migration_projection.dart';
import '../../../features/word/plans/domain/reading_plan.dart';
import '../../../features/word/translations/data/local/word_translation_state_dao.dart';
import '../../../services/bible_version_repository.dart';
import '../../../features/word/plans/data/plan_repository.dart';
import '../app_database.dart';
import 'word_recovery_backup.dart';

enum LegacyWordMigrationStatus { migrated, alreadyCompleted, failed }

class LegacyWordMigrationResult {
  const LegacyWordMigrationResult(this.status, {this.failureCode});

  final LegacyWordMigrationStatus status;
  final String? failureCode;

  bool get driftIsAuthoritative =>
      status == LegacyWordMigrationStatus.migrated ||
      status == LegacyWordMigrationStatus.alreadyCompleted;
}

class LegacyWordImporter {
  LegacyWordImporter({
    required this.database,
    SharedPreferencesAsync? preferences,
    WordRecoveryBackup? recoveryBackup,
    Future<bool> Function()? isCompleteKjvInstalled,
    DateTime Function()? clock,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _recoveryBackup = recoveryBackup ?? const FileWordRecoveryBackup(),
       _isCompleteKjvInstalled =
           isCompleteKjvInstalled ?? BibleVersionRepository().isKjvInstalled,
       _clock = clock ?? DateTime.now;

  static const migrationId = 'word_shared_preferences_v1_to_local_v1';

  final AppDatabase database;
  final SharedPreferencesAsync _preferences;
  final WordRecoveryBackup _recoveryBackup;
  final Future<bool> Function() _isCompleteKjvInstalled;
  final DateTime Function() _clock;

  Future<LegacyWordMigrationResult> migrate() async {
    final existing = await (database.select(
      database.localMigrationMetadata,
    )..where((row) => row.migrationId.equals(migrationId))).getSingleOrNull();
    if (existing != null && existing.state == 'completed') {
      try {
        await _verifyCompletedTarget(existing);
        return const LegacyWordMigrationResult(
          LegacyWordMigrationStatus.alreadyCompleted,
        );
      } catch (_) {
        await database
            .into(database.localMigrationMetadata)
            .insert(
              LocalMigrationMetadataCompanion.insert(
                migrationId: migrationId,
                state: 'failed',
                sourceFingerprint: existing.sourceFingerprint,
                startedAtUtcMicros: existing.startedAtUtcMicros,
                failureCode: const Value('target_verification'),
                targetSchemaVersion: database.schemaVersion,
              ),
              mode: InsertMode.insertOrReplace,
            );
        await _recoveryBackup.writeFailure(
          existing.sourceFingerprint,
          'target_verification',
        );
        return const LegacyWordMigrationResult(
          LegacyWordMigrationStatus.failed,
          failureCode: 'target_verification',
        );
      }
    }

    final rawPlans = await _preferences.getString(
      SharedPreferencesPlanRepository.storageKey,
    );
    final rawTranslations = await _preferences.getStringList(
      BibleVersionRepository.storageKey,
    );
    final completeKjv = await _isCompleteKjvInstalled();
    final exactSnapshot = jsonEncode({
      'planStorageKey': SharedPreferencesPlanRepository.storageKey,
      'planPayload': rawPlans,
      'translationStorageKey': BibleVersionRepository.storageKey,
      'translationPayload': rawTranslations,
      'verifiedCompleteKjvFile': completeKjv,
    });
    final fingerprint = sha256.convert(utf8.encode(exactSnapshot)).toString();
    await _recoveryBackup.writeSnapshot(fingerprint, exactSnapshot);

    try {
      final plans = _decodePlans(rawPlans);
      final projector = LegacyWordMigrationProjection();
      final projectedPlans = projector.projectPlans(plans);
      final projectedTranslations = projector.projectTranslationStates(
        rawTranslations ?? const <String>[],
        verifiedCompleteKjvFile: completeKjv,
      );
      _validate(projectedPlans);
      final started = _clock().toUtc().microsecondsSinceEpoch;

      await database.transaction(() async {
        final planDao = WordPlanDao(database);
        final translationDao = WordTranslationStateDao(database);
        await planDao.clearPlans();
        await database.delete(database.wordTranslationStates).go();
        await planDao.insertProjected(projectedPlans);
        for (final state in projectedTranslations) {
          await translationDao.insertState(
            translationId: state.translationId,
            accessMode: state.accessMode,
            state: state.state,
            managedRelativePath: state.translationId == 'kjv'
                ? 'bibles/kjv.json'
                : null,
          );
        }
        await _verify(projectedPlans, projectedTranslations.length);
        await database
            .into(database.localMigrationMetadata)
            .insert(
              LocalMigrationMetadataCompanion.insert(
                migrationId: migrationId,
                state: 'completed',
                sourceFingerprint: fingerprint,
                startedAtUtcMicros: started,
                completedAtUtcMicros: Value(
                  _clock().toUtc().microsecondsSinceEpoch,
                ),
                targetSchemaVersion: database.schemaVersion,
              ),
              mode: InsertMode.insertOrReplace,
            );
      });
      return const LegacyWordMigrationResult(
        LegacyWordMigrationStatus.migrated,
      );
    } catch (error) {
      final failureCode = _failureCode(error);
      await database
          .into(database.localMigrationMetadata)
          .insert(
            LocalMigrationMetadataCompanion.insert(
              migrationId: migrationId,
              state: 'failed',
              sourceFingerprint: fingerprint,
              startedAtUtcMicros: _clock().toUtc().microsecondsSinceEpoch,
              failureCode: Value(failureCode),
              targetSchemaVersion: database.schemaVersion,
            ),
            mode: InsertMode.insertOrReplace,
          );
      await _recoveryBackup.writeFailure(fingerprint, failureCode);
      return LegacyWordMigrationResult(
        LegacyWordMigrationStatus.failed,
        failureCode: failureCode,
      );
    }
  }

  List<ReadingPlan> _decodePlans(String? raw) {
    if (raw == null || raw.isEmpty) return <ReadingPlan>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Legacy Plan payload is not a list.');
    }
    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Legacy Plan entry is not an object.');
      }
      return ReadingPlan.fromJson(item);
    }).toList();
  }

  void _validate(ProjectedWordData data) {
    for (final plan in data.plans) {
      if (plan.title.trim().isEmpty ||
          plan.endDate.compareTo(plan.startDate) < 0) {
        throw const FormatException('Legacy Plan violates schema constraints.');
      }
    }
    for (final item in [...data.sourceItems, ...data.scheduleItems]) {
      if (item.book.trim().isEmpty ||
          item.startChapter <= 0 ||
          (item.startVerse != null && item.startVerse! <= 0) ||
          (item.endChapter != null && item.endChapter! <= 0) ||
          (item.endVerse != null && item.endVerse! <= 0)) {
        throw const FormatException('Legacy reference is invalid.');
      }
    }
  }

  Future<void> _verify(ProjectedWordData data, int translationCount) async {
    final counts = <int>[
      await _count(database.biblePlans),
      await _count(database.biblePlanSourceItems),
      await _count(database.biblePlanScheduleEntries),
      await _count(database.biblePlanScheduleItems),
      await _count(database.wordTranslationStates),
    ];
    final expected = <int>[
      data.plans.length,
      data.sourceItems.length,
      data.scheduleEntries.length,
      data.scheduleItems.length,
      translationCount,
    ];
    if (!_sameCounts(counts, expected)) {
      throw StateError('Migration row-count verification failed.');
    }
    final foreignKeyFailures = await database
        .customSelect('PRAGMA foreign_key_check')
        .get();
    if (foreignKeyFailures.isNotEmpty) {
      throw StateError('Migration foreign-key verification failed.');
    }
  }

  Future<void> _verifyCompletedTarget(
    LocalMigrationMetadataRecord marker,
  ) async {
    if (marker.targetSchemaVersion != database.schemaVersion ||
        marker.sourceFingerprint.isEmpty) {
      throw StateError('Migration marker is incompatible.');
    }
    await WordPlanDao(database).loadPlans();
    final translations = await database
        .select(database.wordTranslationStates)
        .get();
    for (final row in translations) {
      if (row.translationId != 'kjv' && row.translationId != 'nlt') {
        throw StateError('Unknown target translation state.');
      }
    }
    final foreignKeyFailures = await database
        .customSelect('PRAGMA foreign_key_check')
        .get();
    if (foreignKeyFailures.isNotEmpty) {
      throw StateError('Target foreign-key verification failed.');
    }
  }

  Future<int> _count(TableInfo<Table, Object?> table) async {
    final expression = countAll();
    final query = database.selectOnly(table)..addColumns([expression]);
    return (await query.getSingle()).read(expression) ?? 0;
  }

  bool _sameCounts(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  String _failureCode(Object error) =>
      error is FormatException || error is ArgumentError || error is TypeError
      ? 'legacy_format'
      : 'migration_failure';
}
