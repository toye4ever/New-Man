import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';

import 'generated_migrations/schema.dart';

void main() {
  test(
    'v9 upgrade failure rolls back columns and retries without data loss',
    () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(9);
      schema.rawDatabase.execute(
        "INSERT INTO tasks (id,title,is_completed,created_at_utc_micros,updated_at_utc_micros) VALUES ('kept','Kept',0,11,12)",
      );
      schema.rawDatabase.execute(
        "INSERT INTO local_migration_metadata (migration_id,state,source_fingerprint,started_at_utc_micros,completed_at_utc_micros,target_schema_version) VALUES ('word_shared_preferences_v1_to_local_v1','completed','retained',1,2,9)",
      );
      schema.rawDatabase.execute(
        "CREATE TRIGGER fail_upgrade BEFORE UPDATE ON local_migration_metadata BEGIN SELECT RAISE(ABORT, 'synthetic upgrade failure'); END",
      );
      final failed = AppDatabase(schema.newConnection());
      await expectLater(
        failed.customSelect('SELECT * FROM tasks').get(),
        throwsA(anything),
      );
      final columns = schema.rawDatabase
          .select('PRAGMA table_info(tasks)')
          .map((row) => row['name'])
          .toList();
      expect(columns, isNot(contains('planned_date')));
      expect(
        schema.rawDatabase.select('SELECT title FROM tasks').single['title'],
        'Kept',
      );
      expect(
        schema.rawDatabase
            .select(
              'SELECT target_schema_version FROM local_migration_metadata',
            )
            .single['target_schema_version'],
        9,
      );
      schema.rawDatabase.execute('DROP TRIGGER fail_upgrade');
      await failed.close();
      final retry = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(retry, 10);
      expect((await retry.select(retry.tasks).getSingle()).plannedDate, isNull);
      expect(
        (await retry.select(retry.localMigrationMetadata).getSingle())
            .targetSchemaVersion,
        10,
      );
      await retry.close();
    },
  );

  for (final version in [7, 8, 9]) {
    test('v$version retains task and priority with null block', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(version);
      schema.rawDatabase.execute(
        "INSERT INTO tasks (id,title,due_date,is_completed,created_at_utc_micros,updated_at_utc_micros) VALUES ('retained','Task','2026-03-01',0,11,12)",
      );
      schema.rawDatabase.execute(
        "INSERT INTO daily_priority_tasks (priority_date,task_id,position) VALUES ('2026-03-02','retained',0)",
      );
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 10);
      final task = await db.select(db.tasks).getSingle();
      expect(task.id, 'retained');
      expect(task.dueDate, '2026-03-01');
      expect(task.createdAtUtcMicros, 11);
      expect(task.updatedAtUtcMicros, 12);
      expect(task.plannedDate, isNull);
      expect(task.startMinutesLocal, isNull);
      expect(task.endMinutesLocal, isNull);
      expect(
        (await db.select(db.dailyPriorityTasks).getSingle()).taskId,
        'retained',
      );
      await db.close();
    });
  }
  test(
    'v7 preserves Tasks and audio while adding resume and expanded rates',
    () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(7);
      schema.rawDatabase.execute(
        "INSERT INTO tasks (id, title, is_completed, created_at_utc_micros, updated_at_utc_micros) VALUES ('123e4567-e89b-42d3-a456-426614174000', 'Preserved task', 0, 1, 1)",
      );
      schema.rawDatabase.execute(
        "INSERT INTO word_audio_preferences (id, voice_key, playback_rate) VALUES ('reader', 'retained', 0.5)",
      );
      final database = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(database, 10);
      expect(
        (await database.select(database.tasks).getSingle()).title,
        'Preserved task',
      );
      expect(
        (await database.select(database.wordAudioPreferences).getSingle())
            .playbackRate,
        .5,
      );
      await database.customStatement(
        "UPDATE word_audio_preferences SET playback_rate = 0.85",
      );
      expect(
        (await database.select(database.wordAudioPreferences).getSingle())
            .voiceKey,
        'retained',
      );
      await database.close();
    },
  );
  test('committed Drift schema v10 matches the current database', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final connection = await verifier.startAt(10);
    final database = AppDatabase(connection);
    await verifier.migrateAndValidate(database, 10);
    await database.close();
  });

  test(
    'v6 migrates to v10 with empty Task tables and preserved Word data',
    () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(6);
      schema.rawDatabase.execute('''
      INSERT INTO bible_plans (
        id, position, title, default_translation_id,
        created_at_utc_micros, start_date, end_date,
        reading_weekdays_mask, reminder_minutes_local
      ) VALUES (
        '123e4567-e89b-42d3-a456-426614174000', 0, 'Preserved Plan',
        'kjv', 1, '2026-09-03', '2026-09-03', 1, 420
      )
    ''');
      schema.rawDatabase.execute('''
      INSERT INTO word_translation_states (
        translation_id, access_mode, state, installed_version,
        managed_relative_path, updated_at_utc_micros
      ) VALUES ('kjv', 'offline', 'installed', 'synthetic-v1',
        'bibles/kjv.json', 2)
    ''');
      schema.rawDatabase.execute('''
      INSERT INTO word_reader_states (
        id, book, chapter, translation_id, updated_at_utc_micros
      ) VALUES ('latest', 'Romans', 8, 'kjv', 3)
    ''');
      schema.rawDatabase.execute('''
      INSERT INTO word_audio_preferences (id, voice_key, playback_rate)
      VALUES ('reader', 'synthetic-voice', 0.5)
    ''');
      schema.rawDatabase.execute('''
      INSERT INTO word_scripture_bookmarks (
        anchor_key, book, chapter, start_verse, end_verse,
        created_at_utc_micros
      ) VALUES ('Romans|8|1|2', 'Romans', 8, 1, 2, 4)
    ''');
      schema.rawDatabase.execute('''
      INSERT INTO word_scripture_highlights (
        anchor_key, book, chapter, start_verse, end_verse, style,
        updated_at_utc_micros
      ) VALUES ('Romans|8|3|4', 'Romans', 8, 3, 4, 'gold', 5)
    ''');
      schema.rawDatabase.execute('''
      INSERT INTO word_scripture_notes (
        id, anchor_key, book, chapter, start_verse, end_verse, body,
        created_at_utc_micros, updated_at_utc_micros
      ) VALUES ('note-v6', 'Romans|8|5|6', 'Romans', 8, 5, 6,
        'Preserved note.', 6, 7)
    ''');
      schema.rawDatabase.execute('''
      INSERT INTO word_scripture_note_anchors (
        note_id, ordinal, anchor_key, book, chapter, start_verse, end_verse
      ) VALUES ('note-v6', 0, 'Romans|8|5|6', 'Romans', 8, 5, 6)
    ''');
      schema.rawDatabase.execute('''
      INSERT INTO word_reading_history (
        anchor_key, book, chapter, start_verse, end_verse,
        opened_at_utc_micros
      ) VALUES ('Romans|8||', 'Romans', 8, NULL, NULL, 8)
    ''');
      schema.rawDatabase.execute('''
      INSERT INTO local_migration_metadata (
        migration_id, state, source_fingerprint, started_at_utc_micros,
        completed_at_utc_micros, target_schema_version
      ) VALUES ('word_shared_preferences_v1_to_local_v1', 'completed',
        'synthetic-fingerprint', 1, 2, 6)
    ''');
      final database = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(database, 10);
      expect(
        (await database.select(database.biblePlans).getSingle()).title,
        'Preserved Plan',
      );
      expect(
        (await database.select(database.wordTranslationStates).getSingle())
            .installedVersion,
        'synthetic-v1',
      );
      expect(
        (await database.select(database.wordReaderStates).getSingle()).chapter,
        8,
      );
      expect(
        (await database.select(database.wordAudioPreferences).getSingle())
            .voiceKey,
        'synthetic-voice',
      );
      expect(
        await database.select(database.wordScriptureBookmarks).get(),
        hasLength(1),
      );
      expect(
        await database.select(database.wordScriptureHighlights).get(),
        hasLength(1),
      );
      expect(
        (await database.select(database.wordScriptureNotes).getSingle()).body,
        'Preserved note.',
      );
      expect(
        await database.select(database.wordScriptureNoteAnchors).get(),
        hasLength(1),
      );
      expect(
        await database.select(database.wordReadingHistory).get(),
        hasLength(1),
      );
      expect(await database.select(database.tasks).get(), isEmpty);
      expect(await database.select(database.dailyPriorityTasks).get(), isEmpty);
      expect(
        (await database.select(database.localMigrationMetadata).getSingle())
            .targetSchemaVersion,
        10,
      );
      await database.close();
    },
  );

  test('v2 migrates to v10 without losing Word state', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase.execute('''
      INSERT INTO bible_plans (
        id, position, title, default_translation_id,
        created_at_utc_micros, start_date, end_date,
        reading_weekdays_mask, reminder_minutes_local
      ) VALUES (
        '123e4567-e89b-42d3-a456-426614174000', 0, 'Preserved Plan',
        'kjv', 1, '2026-08-16', '2026-08-16', 1, 420
      )
    ''');
    schema.rawDatabase.execute('''
      INSERT INTO word_translation_states (
        translation_id, access_mode, state, managed_relative_path
      ) VALUES ('kjv', 'offline', 'installed', 'bibles/kjv.json')
    ''');
    schema.rawDatabase.execute('''
      INSERT INTO word_reader_states (
        id, book, chapter, translation_id, updated_at_utc_micros
      ) VALUES ('latest', 'Romans', 8, 'kjv', 2)
    ''');
    schema.rawDatabase.execute('''
      INSERT INTO local_migration_metadata (
        migration_id, state, source_fingerprint, started_at_utc_micros,
        completed_at_utc_micros, target_schema_version
      ) VALUES (
        'word_shared_preferences_v1_to_local_v1', 'completed',
        'synthetic-fingerprint', 1, 2, 2
      )
    ''');

    final database = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(database, 10);
    expect(
      (await database.select(database.biblePlans).getSingle()).title,
      'Preserved Plan',
    );
    expect(
      (await database.select(database.wordTranslationStates).getSingle()).state,
      'installed',
    );
    expect(
      (await database.select(database.wordReaderStates).getSingle()).chapter,
      8,
    );
    expect(
      (await database.select(database.localMigrationMetadata).getSingle())
          .targetSchemaVersion,
      10,
    );
    await database.close();
  });

  test('v3 migrates to v10 and creates durable audio preferences', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(3);
    schema.rawDatabase.execute('''
      INSERT INTO local_migration_metadata (
        migration_id, state, source_fingerprint, started_at_utc_micros,
        completed_at_utc_micros, target_schema_version
      ) VALUES (
        'word_shared_preferences_v1_to_local_v1', 'completed',
        'synthetic-fingerprint', 1, 2, 3
      )
    ''');

    final database = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(database, 10);
    expect(await database.select(database.wordAudioPreferences).get(), isEmpty);
    expect(
      (await database.select(database.localMigrationMetadata).getSingle())
          .targetSchemaVersion,
      10,
    );
    await database.close();
  });

  test('v4 migrates to v10 without changing existing Word rows', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(4);
    schema.rawDatabase.execute('''
      INSERT INTO word_reader_states (
        id, book, chapter, translation_id, updated_at_utc_micros
      ) VALUES ('latest', 'Romans', 8, 'kjv', 2)
    ''');
    schema.rawDatabase.execute('''
      INSERT INTO local_migration_metadata (
        migration_id, state, source_fingerprint, started_at_utc_micros,
        completed_at_utc_micros, target_schema_version
      ) VALUES (
        'word_shared_preferences_v1_to_local_v1', 'completed',
        'synthetic-fingerprint', 1, 2, 4
      )
    ''');
    final database = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(database, 10);
    expect(
      (await database.select(database.wordReaderStates).getSingle()).chapter,
      8,
    );
    expect(
      await database.select(database.wordScriptureBookmarks).get(),
      isEmpty,
    );
    expect(
      (await database.select(database.localMigrationMetadata).getSingle())
          .targetSchemaVersion,
      10,
    );
    await database.close();
  });

  test('v5 migrates notes through v8 without data loss', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(5);
    schema.rawDatabase.execute('''
      INSERT INTO word_scripture_notes (
        id, anchor_key, book, chapter, start_verse, end_verse, body,
        created_at_utc_micros, updated_at_utc_micros
      ) VALUES ('note-v5', 'Exodus|6|2|', 'Exodus', 6, 2, NULL,
        'Preserved private note.', 11, 12)
    ''');
    schema.rawDatabase.execute('''
      INSERT INTO local_migration_metadata (
        migration_id, state, source_fingerprint, started_at_utc_micros,
        completed_at_utc_micros, target_schema_version
      ) VALUES ('word_shared_preferences_v1_to_local_v1', 'completed',
        'synthetic-fingerprint', 1, 2, 5)
    ''');
    final database = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(database, 10);
    final note = await database.select(database.wordScriptureNotes).getSingle();
    final anchor = await database
        .select(database.wordScriptureNoteAnchors)
        .getSingle();
    expect(note.id, 'note-v5');
    expect(note.body, 'Preserved private note.');
    expect(note.createdAtUtcMicros, 11);
    expect(note.updatedAtUtcMicros, 12);
    expect(anchor.noteId, 'note-v5');
    expect(anchor.ordinal, 0);
    expect(anchor.anchorKey, 'Exodus|6|2|');
    await expectLater(
      database.customStatement(
        "INSERT INTO word_scripture_note_anchors (note_id, ordinal, anchor_key, book, chapter) VALUES ('note-v5', 1, 'Exodus|6|2|', 'Exodus', 6)",
      ),
      throwsA(anything),
    );
    await (database.delete(
      database.wordScriptureNotes,
    )..where((t) => t.id.equals('note-v5'))).go();
    expect(
      await database.select(database.wordScriptureNoteAnchors).get(),
      isEmpty,
    );
    expect(
      (await database.select(database.localMigrationMetadata).getSingle())
          .targetSchemaVersion,
      10,
    );
    await database.close();
  });

  test('v1 migrates through v10 without losing Word data', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase.execute('''
      INSERT INTO bible_plans (
        id, position, title, default_translation_id,
        created_at_utc_micros, start_date, end_date,
        reading_weekdays_mask, reminder_minutes_local
      ) VALUES (
        '123e4567-e89b-42d3-a456-426614174000', 0, 'Preserved Plan',
        'kjv', 1, '2026-08-15', '2026-08-15', 1, 420
      )
    ''');
    schema.rawDatabase.execute('''
      INSERT INTO local_migration_metadata (
        migration_id, state, source_fingerprint, started_at_utc_micros,
        completed_at_utc_micros, target_schema_version
      ) VALUES (
        'word_shared_preferences_v1_to_local_v1', 'completed',
        'synthetic-fingerprint', 1, 2, 1
      )
    ''');

    final database = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(database, 10);
    expect(
      (await database.select(database.biblePlans).getSingle()).title,
      'Preserved Plan',
    );
    expect(await database.select(database.wordReaderStates).get(), isEmpty);
    expect(
      (await database.select(database.localMigrationMetadata).getSingle())
          .targetSchemaVersion,
      10,
    );
    await database.close();
  });
}
