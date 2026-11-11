import 'package:flutter/foundation.dart';
import '../../features/settings/data/shared_preferences_appearance_repository.dart';

import '../../controllers/app_controller.dart';
import '../../core/database/app_database.dart';
import '../../core/database/migration/legacy_word_importer.dart';
import '../../features/word/plans/data/drift_plan_repository.dart';
import '../../features/word/plans/data/local/word_plan_dao.dart';
import '../../features/word/plans/data/plan_repository.dart';
import '../../features/word/translations/data/drift_bible_version_repository.dart';
import '../../features/word/translations/data/local/word_translation_state_dao.dart';
import '../../services/bible_version_repository.dart';
import '../../services/scripture_service.dart';
import '../../features/word/bible/application/reader_state_repository.dart';
import '../../features/word/bible/data/drift_reader_state_repository.dart';
import '../../features/word/bible/data/local/word_reader_state_dao.dart';
import '../../features/word/audio/data/drift_audio_preferences_repository.dart';
import '../../features/word/audio/application/audio_preferences_repository.dart';
import '../../features/word/saved_scripture/application/saved_scripture_repository.dart';
import '../../features/word/saved_scripture/data/drift_saved_scripture_repository.dart';
import '../../features/tasks/application/task_service.dart';
import '../../features/tasks/data/drift_task_repository.dart';
import '../../features/tasks/data/local/task_dao.dart';

class LocalDataBootstrapResult {
  const LocalDataBootstrapResult({
    required this.controller,
    required this.database,
    required this.driftIsAuthoritative,
    required this.taskService,
  });

  final AppController controller;
  final AppDatabase database;
  final bool driftIsAuthoritative;
  final TaskService taskService;
}

Future<LocalDataBootstrapResult> bootstrapLocalData() async {
  final database = AppDatabase.open();
  LegacyWordMigrationResult migration;
  try {
    migration = await LegacyWordImporter(database: database).migrate();
  } catch (_) {
    migration = const LegacyWordMigrationResult(
      LegacyWordMigrationStatus.failed,
      failureCode: 'bootstrap_failure',
    );
  }

  final driftIsAuthoritative = migration.driftIsAuthoritative;
  if (!driftIsAuthoritative) {
    debugPrint(
      'Word local migration did not complete; using retained legacy storage '
      '(code: ${migration.failureCode ?? 'unknown'}).',
    );
  }

  final planRepository = driftIsAuthoritative
      ? DriftPlanRepository(WordPlanDao(database))
      : SharedPreferencesPlanRepository();
  final BibleVersionRepository versionRepository = driftIsAuthoritative
      ? DriftBibleVersionRepository(WordTranslationStateDao(database))
      : BibleVersionRepository();
  final controller = AppController(
    appearanceRepository: SharedPreferencesAppearanceRepository(),
    repository: planRepository,
    versionRepository: versionRepository,
    readerStateRepository: driftIsAuthoritative
        ? DriftReaderStateRepository(WordReaderStateDao(database))
        : VolatileReaderStateRepository(),
    audioPreferencesRepository: driftIsAuthoritative
        ? DriftAudioPreferencesRepository(database)
        : VolatileAudioPreferencesRepository(),
    savedScriptureRepository: driftIsAuthoritative
        ? DriftSavedScriptureRepository(database)
        : VolatileSavedScriptureRepository(),
    nltOnlineConfigured: NltScriptureService.isConfigured,
  );
  await controller.load();
  return LocalDataBootstrapResult(
    controller: controller,
    database: database,
    driftIsAuthoritative: driftIsAuthoritative,
    taskService: TaskService(DriftTaskRepository(TaskDao(database))),
  );
}
