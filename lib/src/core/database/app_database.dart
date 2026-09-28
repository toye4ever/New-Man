import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

part 'app_database.g.dart';

@DataClassName('BiblePlanRecord')
class BiblePlans extends Table {
  TextColumn get id => text()();
  TextColumn get legacyId => text().nullable().unique()();
  IntColumn get position => integer().unique()();
  TextColumn get title => text()();
  TextColumn get defaultTranslationId => text()();
  IntColumn get createdAtUtcMicros => integer()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  IntColumn get readingWeekdaysMask => integer()();
  IntColumn get reminderMinutesLocal => integer()();
  TextColumn get templateId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (position >= 0)',
    "CHECK (length(trim(title)) > 0)",
    "CHECK (default_translation_id IN ('kjv', 'nlt'))",
    "CHECK (start_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    "CHECK (end_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    'CHECK (end_date >= start_date)',
    'CHECK (reading_weekdays_mask BETWEEN 1 AND 127)',
    'CHECK (reminder_minutes_local BETWEEN 0 AND 1439)',
  ];
}

@DataClassName('BiblePlanSourceItemRecord')
class BiblePlanSourceItems extends Table {
  TextColumn get id => text()();
  TextColumn get planId =>
      text().references(BiblePlans, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get book => text()();
  IntColumn get startChapter => integer()();
  IntColumn get startVerse => integer().nullable()();
  IntColumn get endChapter => integer().nullable()();
  IntColumn get endVerse => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {planId, position},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (position >= 0)',
    "CHECK (length(trim(book)) > 0)",
    'CHECK (start_chapter > 0)',
    'CHECK (start_verse IS NULL OR start_verse > 0)',
    'CHECK (end_chapter IS NULL OR end_chapter > 0)',
    'CHECK (end_verse IS NULL OR end_verse > 0)',
  ];
}

@DataClassName('BiblePlanScheduleEntryRecord')
@TableIndex(
  name: 'idx_bible_plan_schedule_entries_plan_date',
  columns: {#planId, #scheduledDate},
)
class BiblePlanScheduleEntries extends Table {
  TextColumn get id => text()();
  TextColumn get planId =>
      text().references(BiblePlans, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get scheduledDate => text()();
  BoolColumn get isCompleted => boolean()();
  IntColumn get completedAtUtcMicros => integer().nullable()();
  TextColumn get translationOverrideId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {planId, position},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (position >= 0)',
    "CHECK (scheduled_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    "CHECK (translation_override_id IS NULL OR translation_override_id IN ('kjv', 'nlt'))",
  ];
}

@DataClassName('BiblePlanScheduleItemRecord')
class BiblePlanScheduleItems extends Table {
  TextColumn get id => text()();
  TextColumn get scheduleEntryId => text().references(
    BiblePlanScheduleEntries,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get position => integer()();
  TextColumn get book => text()();
  IntColumn get startChapter => integer()();
  IntColumn get startVerse => integer().nullable()();
  IntColumn get endChapter => integer().nullable()();
  IntColumn get endVerse => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {scheduleEntryId, position},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (position >= 0)',
    "CHECK (length(trim(book)) > 0)",
    'CHECK (start_chapter > 0)',
    'CHECK (start_verse IS NULL OR start_verse > 0)',
    'CHECK (end_chapter IS NULL OR end_chapter > 0)',
    'CHECK (end_verse IS NULL OR end_verse > 0)',
  ];
}

@DataClassName('WordTranslationStateRecord')
class WordTranslationStates extends Table {
  TextColumn get translationId => text()();
  TextColumn get accessMode => text()();
  TextColumn get state => text()();
  TextColumn get installedVersion => text().nullable()();
  TextColumn get managedRelativePath => text().nullable()();
  IntColumn get updatedAtUtcMicros => integer().nullable()();
  TextColumn get failureCode => text().nullable()();
  IntColumn get downloadProgressPermille => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {translationId};

  @override
  List<String> get customConstraints => [
    "CHECK (translation_id IN ('kjv', 'nlt'))",
    "CHECK ((translation_id = 'kjv' AND access_mode = 'offline' AND state IN ('downloading', 'processing', 'installed', 'failed')) OR (translation_id = 'nlt' AND access_mode = 'online' AND state = 'enabled'))",
    "CHECK (download_progress_permille IS NULL OR (state = 'downloading' AND download_progress_permille BETWEEN 0 AND 1000))",
    "CHECK (failure_code IS NULL OR state = 'failed')",
  ];
}

@DataClassName('LocalMigrationMetadataRecord')
class LocalMigrationMetadata extends Table {
  TextColumn get migrationId => text()();
  TextColumn get state => text()();
  TextColumn get sourceFingerprint => text()();
  IntColumn get startedAtUtcMicros => integer()();
  IntColumn get completedAtUtcMicros => integer().nullable()();
  TextColumn get failureCode => text().nullable()();
  IntColumn get targetSchemaVersion => integer()();

  @override
  Set<Column<Object>> get primaryKey => {migrationId};

  @override
  List<String> get customConstraints => [
    "CHECK (state IN ('in_progress', 'completed', 'failed'))",
    'CHECK (length(source_fingerprint) > 0)',
    'CHECK (target_schema_version > 0)',
  ];
}

@DataClassName('WordReaderStateRecord')
class WordReaderStates extends Table {
  TextColumn get id => text()();
  TextColumn get book => text()();
  IntColumn get chapter => integer()();
  TextColumn get translationId => text()();
  IntColumn get updatedAtUtcMicros => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (id = 'latest')",
    'CHECK (length(trim(book)) > 0)',
    'CHECK (chapter > 0)',
    "CHECK (translation_id IN ('kjv', 'nlt'))",
  ];
}

@DataClassName('WordAudioPreferenceRecord')
class WordAudioPreferences extends Table {
  TextColumn get id => text()();
  TextColumn get voiceKey => text().nullable()();
  RealColumn get playbackRate => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (id = 'reader')",
    'CHECK (playback_rate BETWEEN 0.35 AND 0.65)',
  ];
}

@DataClassName('WordScriptureBookmarkRecord')
class WordScriptureBookmarks extends Table {
  TextColumn get anchorKey => text()();
  TextColumn get book => text()();
  IntColumn get chapter => integer()();
  IntColumn get startVerse => integer().nullable()();
  IntColumn get endVerse => integer().nullable()();
  IntColumn get createdAtUtcMicros => integer()();
  @override
  Set<Column<Object>> get primaryKey => {anchorKey};
  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(book)) > 0)',
    'CHECK (chapter > 0)',
    'CHECK (start_verse IS NULL OR start_verse > 0)',
    'CHECK (end_verse IS NULL OR end_verse > 0)',
    'CHECK (start_verse IS NULL OR end_verse IS NULL OR end_verse >= start_verse)',
  ];
}

@DataClassName('WordScriptureHighlightRecord')
class WordScriptureHighlights extends Table {
  TextColumn get anchorKey => text()();
  TextColumn get book => text()();
  IntColumn get chapter => integer()();
  IntColumn get startVerse => integer().nullable()();
  IntColumn get endVerse => integer().nullable()();
  TextColumn get style => text()();
  IntColumn get updatedAtUtcMicros => integer()();
  @override
  Set<Column<Object>> get primaryKey => {anchorKey};
  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(book)) > 0)',
    'CHECK (chapter > 0)',
    'CHECK (start_verse IS NULL OR start_verse > 0)',
    'CHECK (end_verse IS NULL OR end_verse > 0)',
    'CHECK (start_verse IS NULL OR end_verse IS NULL OR end_verse >= start_verse)',
    "CHECK (style IN ('gold', 'green', 'blue', 'rose'))",
  ];
}

@DataClassName('WordScriptureNoteRecord')
class WordScriptureNotes extends Table {
  TextColumn get id => text()();
  TextColumn get anchorKey => text()();
  TextColumn get book => text()();
  IntColumn get chapter => integer()();
  IntColumn get startVerse => integer().nullable()();
  IntColumn get endVerse => integer().nullable()();
  TextColumn get body => text()();
  IntColumn get createdAtUtcMicros => integer()();
  IntColumn get updatedAtUtcMicros => integer()();
  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(book)) > 0)',
    'CHECK (chapter > 0)',
    'CHECK (start_verse IS NULL OR start_verse > 0)',
    'CHECK (end_verse IS NULL OR end_verse > 0)',
    'CHECK (start_verse IS NULL OR end_verse IS NULL OR end_verse >= start_verse)',
    'CHECK (length(trim(body)) > 0)',
  ];
}

@DataClassName('WordScriptureNoteAnchorRecord')
class WordScriptureNoteAnchors extends Table {
  TextColumn get noteId => text().references(WordScriptureNotes, #id, onDelete: KeyAction.cascade)();
  IntColumn get ordinal => integer()();
  TextColumn get anchorKey => text()();
  TextColumn get book => text()();
  IntColumn get chapter => integer()();
  IntColumn get startVerse => integer().nullable()();
  IntColumn get endVerse => integer().nullable()();
  @override Set<Column<Object>> get primaryKey => {noteId, ordinal};
  @override List<Set<Column<Object>>> get uniqueKeys => [{noteId, anchorKey}];
  @override List<String> get customConstraints => ['CHECK (length(trim(book)) > 0)', 'CHECK (chapter > 0)', 'CHECK (start_verse IS NULL OR start_verse > 0)', 'CHECK (end_verse IS NULL OR end_verse > 0)', 'CHECK (start_verse IS NULL OR end_verse IS NULL OR end_verse >= start_verse)'];
}

@DataClassName('WordReadingHistoryRecord')
class WordReadingHistory extends Table {
  TextColumn get anchorKey => text()();
  TextColumn get book => text()();
  IntColumn get chapter => integer()();
  IntColumn get startVerse => integer().nullable()();
  IntColumn get endVerse => integer().nullable()();
  IntColumn get openedAtUtcMicros => integer()();
  @override
  Set<Column<Object>> get primaryKey => {anchorKey};
  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(book)) > 0)',
    'CHECK (chapter > 0)',
    'CHECK (start_verse IS NULL OR start_verse > 0)',
    'CHECK (end_verse IS NULL OR end_verse > 0)',
    'CHECK (start_verse IS NULL OR end_verse IS NULL OR end_verse >= start_verse)',
  ];
}

@DataClassName('StoredTaskRecord')
@TableIndex(name: 'idx_tasks_open_due_date', columns: {#isCompleted, #dueDate})
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get dueDate => text().nullable()();
  BoolColumn get isCompleted => boolean()();
  IntColumn get completedAtUtcMicros => integer().nullable()();
  IntColumn get createdAtUtcMicros => integer()();
  IntColumn get updatedAtUtcMicros => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (length(trim(title)) > 0)",
    "CHECK (due_date IS NULL OR due_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    'CHECK ((is_completed = 0 AND completed_at_utc_micros IS NULL) OR (is_completed = 1 AND completed_at_utc_micros IS NOT NULL))',
  ];
}

@DataClassName('DailyPriorityTaskRecord')
@TableIndex(
  name: 'idx_daily_priority_tasks_date_position',
  columns: {#priorityDate, #position},
)
class DailyPriorityTasks extends Table {
  TextColumn get priorityDate => text()();
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {priorityDate, taskId};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {priorityDate, position},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (priority_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    'CHECK (position >= 0)',
  ];
}

@DriftDatabase(
  tables: [
    BiblePlans,
    BiblePlanSourceItems,
    BiblePlanScheduleEntries,
    BiblePlanScheduleItems,
    WordTranslationStates,
    LocalMigrationMetadata,
    WordReaderStates,
    WordAudioPreferences,
    WordScriptureBookmarks,
    WordScriptureHighlights,
    WordScriptureNotes,
    WordScriptureNoteAnchors,
    WordReadingHistory,
    Tasks,
    DailyPriorityTasks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.open() => AppDatabase(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(wordReaderStates);
        await customStatement(
          'UPDATE local_migration_metadata '
          'SET target_schema_version = 2 '
          "WHERE migration_id = 'word_shared_preferences_v1_to_local_v1' "
          "AND state = 'completed'",
        );
      }
      if (from < 3) {
        await migrator.alterTable(
          TableMigration(
            wordTranslationStates,
            columnTransformer: {
              wordTranslationStates.failureCode: const Constant(null),
              wordTranslationStates.downloadProgressPermille: const Constant(
                null,
              ),
            },
          ),
        );
        await customStatement(
          'UPDATE local_migration_metadata '
          'SET target_schema_version = 3 '
          "WHERE migration_id = 'word_shared_preferences_v1_to_local_v1' "
          "AND state = 'completed'",
        );
      }
      if (from < 4) {
        await migrator.createTable(wordAudioPreferences);
        await customStatement(
          'UPDATE local_migration_metadata '
          'SET target_schema_version = 4 '
          "WHERE migration_id = 'word_shared_preferences_v1_to_local_v1' "
          "AND state = 'completed'",
        );
      }
      if (from < 5) {
        await migrator.createTable(wordScriptureBookmarks);
        await migrator.createTable(wordScriptureHighlights);
        await migrator.createTable(wordScriptureNotes);
        await migrator.createTable(wordReadingHistory);
        await customStatement(
          'UPDATE local_migration_metadata '
          'SET target_schema_version = 5 '
          "WHERE migration_id = 'word_shared_preferences_v1_to_local_v1' "
          "AND state = 'completed'",
        );
      }
      if (from < 6) {
        await migrator.createTable(wordScriptureNoteAnchors);
        await customStatement('INSERT INTO word_scripture_note_anchors (note_id, ordinal, anchor_key, book, chapter, start_verse, end_verse) SELECT id, 0, anchor_key, book, chapter, start_verse, end_verse FROM word_scripture_notes');
        await customStatement('UPDATE local_migration_metadata SET target_schema_version = 6 WHERE migration_id = \'word_shared_preferences_v1_to_local_v1\' AND state = \'completed\'');
      }
      if (from < 7) {
        await migrator.createTable(tasks);
        await migrator.createIndex(idxTasksOpenDueDate);
        await migrator.createTable(dailyPriorityTasks);
        await migrator.createIndex(idxDailyPriorityTasksDatePosition);
        await customStatement(
          'UPDATE local_migration_metadata '
          'SET target_schema_version = 7 '
          "WHERE migration_id = 'word_shared_preferences_v1_to_local_v1' "
          "AND state = 'completed'",
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final support = await getApplicationSupportDirectory();
  final databaseDirectory = Directory(
    '${support.path}${Platform.pathSeparator}database',
  );
  await databaseDirectory.create(recursive: true);
  final file = File(
    '${databaseDirectory.path}${Platform.pathSeparator}new_man.sqlite',
  );
  return NativeDatabase.createInBackground(file, setup: _setupDatabase);
});

void _setupDatabase(sqlite.Database database) {
  database.execute('PRAGMA foreign_keys = ON');
}
