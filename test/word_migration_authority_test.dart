import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:scripture_planner/src/app/bootstrap/local_data_bootstrap.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/core/database/migration/legacy_word_importer.dart';
import 'package:scripture_planner/src/features/word/plans/data/drift_plan_repository.dart';
import 'package:scripture_planner/src/features/word/plans/data/local/word_plan_dao.dart';
import 'package:scripture_planner/src/features/word/plans/data/plan_repository.dart';
import 'package:scripture_planner/src/features/word/translations/data/local/word_translation_state_dao.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'bootstrap_persistence_test.dart'
    show DenyNetwork, OwnedPaths, closeBootstrap;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in [
    'completed marker mismatch',
    'previously poisoned marker mismatch',
    'previously poisoned but verifiable marker',
    'missing marker with existing Drift data',
  ]) {
    final poisonedMarker = scenario.startsWith('previously poisoned');
    final readCanBeVerified = scenario.contains('verifiable');
    final markerMissing = scenario.startsWith('missing');
    test(
      '$scenario does not replay or show stale legacy across independent reopens',
      () async {
        final parent = Directory('.dart_tool/beta-bootstrap-diagnostic');
        await parent.create(recursive: true);
        final profile = await parent.createTemp('word-authority-');
        for (final name in ['support', 'documents', 'cache', 'temp']) {
          await Directory('${profile.path}/$name').create();
        }
        final oldPaths = PathProviderPlatform.instance;
        final oldAsync = SharedPreferencesAsyncPlatform.instance;
        final oldPrefs = SharedPreferencesStorePlatform.instance;
        final offline = DenyNetwork();
        PathProviderPlatform.instance = OwnedPaths(profile.absolute.path);
        SharedPreferences.setMockInitialValues({});
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        try {
          await HttpOverrides.runWithHttpOverrides(() async {
            final rawPlans = await File(
              'test/fixtures/legacy/word/plans_v1_current.json',
            ).readAsString();
            final preferences = SharedPreferencesAsync();
            await preferences.setString(
              SharedPreferencesPlanRepository.storageKey,
              rawPlans,
            );
            await preferences.setStringList(
              BibleVersionRepository.storageKey,
              [],
            );
            final initial = await bootstrapLocalData();
            late final String beforePlans;
            late final List<WordTranslationStateRecord> beforeTranslations;
            late final LocalMigrationMetadataRecord? beforeMarker;
            try {
              expect(initial.driftIsAuthoritative, isTrue);
              final database = initial.database;
              final plan = initial.controller.plans.single;
              final newerPlan = plan.copyWith(
                title: 'Newer synthetic progress',
                assignments: [
                  for (final assignment in plan.assignments)
                    assignment.copyWith(completed: true),
                ],
              );
              expect(newerPlan.progress, greaterThan(plan.progress));
              final repo = DriftPlanRepository(WordPlanDao(database));
              await repo.savePlans([newerPlan]);
              await WordTranslationStateDao(database).insertState(
                translationId: 'nlt',
                accessMode: 'online',
                state: 'enabled',
                managedRelativePath: null,
              );
              // Synthetic metadata only. The SQLite file and graph are valid.
              if (markerMissing) {
                await database.delete(database.localMigrationMetadata).go();
              } else {
                await database.customStatement(
                  'UPDATE local_migration_metadata '
                  'SET target_schema_version = ?, state = ?, failure_code = ?, '
                  'completed_at_utc_micros = '
                  'CASE WHEN ? THEN NULL ELSE completed_at_utc_micros END '
                  'WHERE migration_id = ?',
                  [
                    database.schemaVersion - (readCanBeVerified ? 0 : 1),
                    poisonedMarker ? 'failed' : 'completed',
                    poisonedMarker ? 'target_verification' : null,
                    poisonedMarker ? 1 : 0,
                    LegacyWordImporter.migrationId,
                  ],
                );
              }
              beforePlans = jsonEncode(
                (await repo.loadPlans()).map((plan) => plan.toJson()).toList(),
              );
              beforeTranslations = await database
                  .select(database.wordTranslationStates)
                  .get();
              beforeMarker = await database
                  .select(database.localMigrationMetadata)
                  .getSingleOrNull();
            } finally {
              await closeBootstrap(initial);
            }

            final launches = <String>[];
            for (var i = 0; i < 2; i++) {
              try {
                final reopened = await bootstrapLocalData();
                try {
                  launches.add(
                    '${reopened.driftIsAuthoritative ? 'drift' : 'legacy'}:${reopened.controller.plans.map((p) => p.title).join(',')}',
                  );
                } finally {
                  await closeBootstrap(reopened);
                }
              } on LocalDataRecoveryRequired catch (error) {
                expect(error.message, 'Local Word data could not be verified.');
                launches.add('blocked');
              }
            }
            final readback = AppDatabase.open();
            try {
              final repo = DriftPlanRepository(WordPlanDao(readback));
              final afterPlans = jsonEncode(
                (await repo.loadPlans()).map((plan) => plan.toJson()).toList(),
              );
              final afterTranslations = await readback
                  .select(readback.wordTranslationStates)
                  .get();
              final afterMarker = await readback
                  .select(readback.localMigrationMetadata)
                  .getSingleOrNull();
              expect(
                {
                  'launches': launches,
                  'plansUnchanged': afterPlans == beforePlans,
                  'translationsUnchanged': _sameTranslations(
                    afterTranslations,
                    beforeTranslations,
                  ),
                  'authorityMarkerUnchanged': afterMarker == beforeMarker,
                },
                {
                  'launches': readCanBeVerified
                      ? List.filled(2, 'drift:Newer synthetic progress')
                      : ['blocked', 'blocked'],
                  'plansUnchanged': true,
                  'translationsUnchanged': true,
                  'authorityMarkerUnchanged': true,
                },
              );
            } finally {
              await readback.close();
            }
            expect(
              await preferences.getString(
                SharedPreferencesPlanRepository.storageKey,
              ),
              rawPlans,
            );
            expect(
              await preferences.getStringList(
                BibleVersionRepository.storageKey,
              ),
              isEmpty,
            );
            expect(offline.attempts, 0);
          }, offline);
        } finally {
          PathProviderPlatform.instance = oldPaths;
          SharedPreferencesAsyncPlatform.instance = oldAsync;
          SharedPreferencesStorePlatform.instance = oldPrefs;
          await profile.delete(recursive: true);
        }
      },
    );
  }
}

bool _sameTranslations(
  List<WordTranslationStateRecord> a,
  List<WordTranslationStateRecord> b,
) =>
    a.length == b.length && a.indexed.every((entry) => entry.$2 == b[entry.$1]);
