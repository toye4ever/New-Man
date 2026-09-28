import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/core/database/migration/legacy_word_importer.dart';
import 'package:scripture_planner/src/core/database/migration/word_recovery_backup.dart';
import 'package:scripture_planner/src/features/tasks/application/task_service.dart';
import 'package:scripture_planner/src/features/tasks/data/drift_task_repository.dart';
import 'package:scripture_planner/src/features/tasks/data/local/task_dao.dart';
import 'package:scripture_planner/src/features/word/bible/domain/scripture_reference.dart';
import 'package:scripture_planner/src/features/word/plans/data/drift_plan_repository.dart';
import 'package:scripture_planner/src/features/word/plans/data/local/word_plan_dao.dart';
import 'package:scripture_planner/src/features/word/plans/data/plan_repository.dart';
import 'package:scripture_planner/src/features/word/plans/domain/reading_plan.dart';
import 'package:scripture_planner/src/features/word/translations/data/drift_bible_version_repository.dart';
import 'package:scripture_planner/src/features/word/translations/data/local/word_translation_state_dao.dart';
import 'package:scripture_planner/src/features/word/translations/domain/bible_translation.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late MemoryWordRecoveryBackup backup;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    database = AppDatabase(
      NativeDatabase.memory(
        setup: (sqlite) => sqlite.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    backup = MemoryWordRecoveryBackup();
  });

  tearDown(() => database.close());

  Future<LegacyWordMigrationResult> runImport({bool completeKjv = false}) =>
      LegacyWordImporter(
        database: database,
        recoveryBackup: backup,
        isCompleteKjvInstalled: () async => completeKjv,
        clock: () => DateTime.utc(2026, 8, 15, 12),
      ).migrate();

  Future<LocalMigrationMetadataRecord> marker() =>
      database.select(database.localMigrationMetadata).getSingle();

  Future<List<int>> wordCounts() async => [
    (await database.select(database.biblePlans).get()).length,
    (await database.select(database.biblePlanSourceItems).get()).length,
    (await database.select(database.biblePlanScheduleEntries).get()).length,
    (await database.select(database.biblePlanScheduleItems).get()).length,
    (await database.select(database.wordTranslationStates).get()).length,
  ];

  test('schema v7 creates approved tables, index, and foreign keys', () async {
    expect(database.schemaVersion, 7);
    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();
    expect(tables.map((row) => row.read<String>('name')), {
      'bible_plan_schedule_entries',
      'bible_plan_schedule_items',
      'bible_plan_source_items',
      'bible_plans',
      'local_migration_metadata',
      'word_translation_states',
      'word_reader_states',
      'word_audio_preferences',
      'word_scripture_bookmarks',
      'word_scripture_highlights',
      'word_scripture_notes',
      'word_scripture_note_anchors',
      'word_reading_history',
      'tasks',
      'daily_priority_tasks',
    });
    final indexes = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    expect(
      indexes.map((row) => row.read<String>('name')),
      contains('idx_bible_plan_schedule_entries_plan_date'),
    );
    expect(
      indexes.map((row) => row.read<String>('name')),
      contains('idx_tasks_open_due_date'),
    );
    expect(
      indexes.map((row) => row.read<String>('name')),
      contains('idx_daily_priority_tasks_date_position'),
    );
    final foreignKeys = await database
        .customSelect('PRAGMA foreign_key_list(bible_plan_schedule_items)')
        .get();
    expect(foreignKeys.single.read<String>('on_delete'), 'CASCADE');
    final noteAnchorForeignKeys = await database
        .customSelect('PRAGMA foreign_key_list(word_scripture_note_anchors)')
        .get();
    expect(noteAnchorForeignKeys.single.read<String>('on_delete'), 'CASCADE');
    final priorityForeignKeys = await database
        .customSelect('PRAGMA foreign_key_list(daily_priority_tasks)')
        .get();
    expect(priorityForeignKeys.single.read<String>('on_delete'), 'CASCADE');
  });

  test('fresh v7 enforces Task and Daily Priority constraints', () async {
    Future<void> insertTask({
      required String id,
      required String title,
      String? dueDate,
      int isCompleted = 0,
      int? completedAt,
    }) => database.customStatement(
      'INSERT INTO tasks '
      '(id, title, due_date, is_completed, completed_at_utc_micros, '
      'created_at_utc_micros, updated_at_utc_micros) '
      'VALUES (?, ?, ?, ?, ?, 1, 1)',
      [id, title, dueDate, isCompleted, completedAt],
    );

    await insertTask(id: 'task-a', title: 'Task A', dueDate: '2026-09-03');
    await insertTask(id: 'task-b', title: 'Task B', dueDate: '2026-09-04');
    await insertTask(
      id: 'task-complete',
      title: 'Complete',
      isCompleted: 1,
      completedAt: 2,
    );

    await expectLater(
      insertTask(id: 'blank-title', title: '   '),
      throwsA(anything),
    );
    await expectLater(
      insertTask(id: 'bad-date', title: 'Bad date', dueDate: '09/03/2026'),
      throwsA(anything),
    );
    await expectLater(
      insertTask(id: 'bad-completion', title: 'Bad completion', isCompleted: 1),
      throwsA(anything),
    );

    await database.customStatement(
      "INSERT INTO daily_priority_tasks "
      "(priority_date, task_id, position) VALUES ('2026-09-03', 'task-a', 0)",
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO daily_priority_tasks "
        "(priority_date, task_id, position) VALUES ('2026-09-03', 'task-a', 1)",
      ),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO daily_priority_tasks "
        "(priority_date, task_id, position) VALUES ('2026-09-03', 'task-b', 0)",
      ),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO daily_priority_tasks "
        "(priority_date, task_id, position) VALUES ('2026-09-04', 'task-b', -1)",
      ),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO daily_priority_tasks "
        "(priority_date, task_id, position) VALUES ('bad-date', 'task-b', 0)",
      ),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO daily_priority_tasks "
        "(priority_date, task_id, position) VALUES ('2026-09-04', 'missing', 0)",
      ),
      throwsA(anything),
    );
  });

  test(
    'fresh v7 Task repository round trips Tasks and ordered priorities',
    () async {
      final service = TaskService(
        DriftTaskRepository(TaskDao(database)),
        clock: () => DateTime.utc(2026, 9, 3, 12),
      );
      final undated = await service.createTask(title: 'Undated');
      final due = await service.createTask(
        title: 'Due today',
        dueDate: DateTime(2026, 9, 3, 23),
      );
      await service.selectDailyPriority(DateTime(2026, 9, 3), undated.id);
      await service.selectDailyPriority(DateTime(2026, 9, 3), due.id);
      await service.reorderDailyPriorities(DateTime(2026, 9, 3), [
        due.id,
        undated.id,
      ]);

      final restarted = TaskService(DriftTaskRepository(TaskDao(database)));
      final tasks = await restarted.loadTasks();
      expect(tasks.map((task) => task.id).toSet(), {undated.id, due.id});
      expect(
        tasks.singleWhere((task) => task.id == undated.id).dueDate,
        isNull,
      );
      expect(
        tasks.singleWhere((task) => task.id == due.id).dueDate,
        DateTime(2026, 9, 3),
      );
      expect(
        (await restarted.loadDailyPriorities(
          DateTime(2026, 9, 3),
        )).map((item) => item.taskId),
        [due.id, undated.id],
      );
    },
  );

  test(
    'Drift Plan repository round trips order and all behavior fields',
    () async {
      final repository = DriftPlanRepository(WordPlanDao(database));
      final first = _domainPlan(
        id: '123e4567-e89b-42d3-a456-426614174000',
        title: 'First',
      );
      final second = _domainPlan(
        id: '123e4567-e89b-42d3-a456-426614174001',
        title: 'Second',
      );
      await repository.savePlans([second, first]);

      final loaded = await DriftPlanRepository(
        WordPlanDao(database),
      ).loadPlans();
      expect(loaded.map((plan) => plan.title), ['Second', 'First']);
      final plan = loaded.first;
      expect(plan.defaultTranslation, BibleTranslation.nlt);
      expect(plan.createdAt, DateTime.utc(2025, 4, 1, 12, 30));
      expect(plan.startDate, DateTime(2025, 4, 7));
      expect(plan.endDate, DateTime(2025, 4, 9));
      expect(plan.readingWeekdays, {1, 3});
      expect(plan.reminderTime, '06:05');
      expect(plan.sourceReferences.single.display, 'Romans 8:1-4');
      expect(plan.assignments.map((item) => item.completed), [true, false]);
      expect(plan.assignments.first.translationOverride, BibleTranslation.kjv);
      expect(plan.progress, 0.5);
    },
  );

  test(
    'fresh install creates an empty authoritative database marker',
    () async {
      final result = await runImport();
      expect(result.status, LegacyWordMigrationStatus.migrated);
      expect(await database.select(database.biblePlans).get(), isEmpty);
      expect((await marker()).state, 'completed');
      expect(backup.snapshots, hasLength(1));
    },
  );

  test(
    'Drift translation repository preserves real availability semantics',
    () async {
      final repository = _TestDriftBibleVersionRepository(
        WordTranslationStateDao(database),
        completeKjv: false,
      );
      await repository.saveInstalled({
        BibleTranslation.kjv,
        BibleTranslation.nlt,
      });
      expect(await repository.loadInstalled(), {BibleTranslation.nlt});
      final onlineRows = await database
          .select(database.wordTranslationStates)
          .get();
      expect(onlineRows.single.accessMode, 'online');

      repository.completeKjv = true;
      await repository.saveInstalled({
        BibleTranslation.kjv,
        BibleTranslation.nlt,
      });
      expect(await repository.loadInstalled(), {
        BibleTranslation.kjv,
        BibleTranslation.nlt,
      });
      final rows = await database.select(database.wordTranslationStates).get();
      expect(
        rows.where((row) => row.translationId == 'kjv').single.state,
        'installed',
      );
      expect(
        rows.where((row) => row.translationId == 'nlt').single.state,
        'enabled',
      );
    },
  );

  test(
    'imports current and optional fixtures once and preserves legacy',
    () async {
      final current = await _fixtureList('plans_v1_current.json');
      final optional = await _fixtureList('plans_v1_optional_legacy.json');
      final rawPlans = jsonEncode([...current, ...optional]);
      final preferences = SharedPreferencesAsync();
      await preferences.setString(
        SharedPreferencesPlanRepository.storageKey,
        rawPlans,
      );
      await preferences.setStringList(BibleVersionRepository.storageKey, [
        'kjv',
        'nlt',
      ]);

      final first = await runImport(completeKjv: true);
      expect(first.status, LegacyWordMigrationStatus.migrated);
      final plans = await DriftPlanRepository(
        WordPlanDao(database),
      ).loadPlans();
      expect(plans, hasLength(2));
      expect(plans.map((plan) => plan.title), [
        'Synthetic Gospel Study',
        'Synthetic Legacy Plan',
      ]);
      expect(plans.first.progress, 0.5);
      expect(
        plans.first.assignments.first.translationOverride,
        BibleTranslation.kjv,
      );
      expect(plans.last.endDate, DateTime(2024, 2, 6));
      expect(plans.last.assignments.every((entry) => !entry.completed), isTrue);
      expect(
        await database.select(database.wordTranslationStates).get(),
        hasLength(2),
      );

      final beforeCounts = await wordCounts();
      final restart = await runImport(completeKjv: true);
      expect(restart.status, LegacyWordMigrationStatus.alreadyCompleted);
      expect(await wordCounts(), beforeCounts);
      expect(
        await preferences.getString(SharedPreferencesPlanRepository.storageKey),
        rawPlans,
      );
      expect(
        await preferences.getStringList(BibleVersionRepository.storageKey),
        ['kjv', 'nlt'],
      );
      expect(backup.snapshots, hasLength(1));
    },
  );

  test(
    'malformed legacy data fails safely, remains intact, and retries',
    () async {
      final preferences = SharedPreferencesAsync();
      const malformed = '[not valid JSON';
      await preferences.setString(
        SharedPreferencesPlanRepository.storageKey,
        malformed,
      );
      await preferences.setStringList(BibleVersionRepository.storageKey, [
        'nlt',
      ]);

      final failed = await runImport();
      expect(failed.status, LegacyWordMigrationStatus.failed);
      expect(failed.failureCode, 'legacy_format');
      expect((await marker()).state, 'failed');
      expect(await database.select(database.biblePlans).get(), isEmpty);
      expect(
        await preferences.getString(SharedPreferencesPlanRepository.storageKey),
        malformed,
      );
      expect(
        await preferences.getStringList(BibleVersionRepository.storageKey),
        ['nlt'],
      );
      expect(backup.failures.single, 'legacy_format');

      final valid = jsonEncode(await _fixtureList('plans_v1_current.json'));
      await preferences.setString(
        SharedPreferencesPlanRepository.storageKey,
        valid,
      );
      final retried = await runImport();
      expect(retried.status, LegacyWordMigrationStatus.migrated);
      expect((await marker()).state, 'completed');
      expect(await database.select(database.biblePlans).get(), hasLength(1));
    },
  );

  test(
    'database write failure rolls back all target rows and can retry',
    () async {
      final raw = jsonEncode(await _fixtureList('plans_v1_current.json'));
      final preferences = SharedPreferencesAsync();
      await preferences.setString(
        SharedPreferencesPlanRepository.storageKey,
        raw,
      );
      await database.customStatement('''
        CREATE TRIGGER reject_source_items
        BEFORE INSERT ON bible_plan_source_items
        BEGIN
          SELECT RAISE(ABORT, 'synthetic write failure');
        END
      ''');

      final failed = await runImport();
      expect(failed.status, LegacyWordMigrationStatus.failed);
      expect(failed.failureCode, 'migration_failure');
      expect(await database.select(database.biblePlans).get(), isEmpty);
      expect(
        await database.select(database.biblePlanSourceItems).get(),
        isEmpty,
      );
      expect((await marker()).state, 'failed');
      expect(
        await preferences.getString(SharedPreferencesPlanRepository.storageKey),
        raw,
      );

      await database.customStatement('DROP TRIGGER reject_source_items');
      final retry = await runImport();
      expect(retry.status, LegacyWordMigrationStatus.migrated);
      expect(await database.select(database.biblePlans).get(), hasLength(1));
      expect((await marker()).state, 'completed');
    },
  );

  test('unknown translation state fails without faking availability', () async {
    await SharedPreferencesAsync().setStringList(
      BibleVersionRepository.storageKey,
      ['future-version'],
    );
    final result = await runImport();
    expect(result.status, LegacyWordMigrationStatus.failed);
    expect(
      await database.select(database.wordTranslationStates).get(),
      isEmpty,
    );
    expect((await marker()).state, 'failed');
  });
}

class MemoryWordRecoveryBackup implements WordRecoveryBackup {
  final Map<String, String> snapshots = {};
  final List<String> failures = [];

  @override
  Future<void> writeSnapshot(String fingerprint, String exactPayload) async {
    snapshots.putIfAbsent(fingerprint, () => exactPayload);
  }

  @override
  Future<void> writeFailure(String fingerprint, String failureCode) async {
    failures.add(failureCode);
  }
}

class _TestDriftBibleVersionRepository extends DriftBibleVersionRepository {
  _TestDriftBibleVersionRepository(super.dao, {required this.completeKjv});

  bool completeKjv;

  @override
  Future<bool> isKjvInstalled() async => completeKjv;
}

Future<List<dynamic>> _fixtureList(String name) async =>
    jsonDecode(await File('test/fixtures/legacy/word/$name').readAsString())
        as List<dynamic>;

ReadingPlan _domainPlan({required String id, required String title}) =>
    ReadingPlan(
      id: id,
      title: title,
      defaultTranslation: BibleTranslation.nlt,
      createdAt: DateTime.utc(2025, 4, 1, 12, 30),
      startDate: DateTime(2025, 4, 7),
      endDate: DateTime(2025, 4, 9),
      readingWeekdays: {1, 3},
      reminderTime: '06:05',
      sourceReferences: const [
        ScriptureReference(
          book: 'Romans',
          startChapter: 8,
          startVerse: 1,
          endChapter: 8,
          endVerse: 4,
        ),
      ],
      assignments: [
        ScheduledReading(
          date: DateTime(2025, 4, 7),
          references: const [
            ScriptureReference(book: 'Romans', startChapter: 8, startVerse: 1),
          ],
          completed: true,
          translationOverride: BibleTranslation.kjv,
        ),
        ScheduledReading(
          date: DateTime(2025, 4, 9),
          references: const [
            ScriptureReference(book: 'Romans', startChapter: 8, startVerse: 4),
          ],
        ),
      ],
      templateId: 'synthetic-template',
    );
