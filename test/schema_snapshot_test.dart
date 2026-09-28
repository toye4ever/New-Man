import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';

import 'generated_migrations/schema.dart';

void main() {
  test('committed Drift schema v7 matches the current database', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final connection = await verifier.startAt(7);
    final database = AppDatabase(connection);
    await verifier.migrateAndValidate(database, 7);
    await database.close();
  });

  test(
    'v6 migrates to v7 with empty Task tables and preserved Word data',
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
      await verifier.migrateAndValidate(database, 7);
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
        7,
      );
      await database.close();
    },
  );

  test('v2 migrates to v7 without losing Word state', () async {
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
    await verifier.migrateAndValidate(database, 7);
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
      7,
    );
    await database.close();
  });

  test('v3 migrates to v7 and creates durable audio preferences', () async {
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
    await verifier.migrateAndValidate(database, 7);
    expect(await database.select(database.wordAudioPreferences).get(), isEmpty);
    expect(
      (await database.select(database.localMigrationMetadata).getSingle())
          .targetSchemaVersion,
      7,
    );
    await database.close();
  });

  test('v4 migrates to v7 without changing existing Word rows', () async {
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
    await verifier.migrateAndValidate(database, 7);
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
      7,
    );
    await database.close();
  });

  test('v5 migrates notes through v7 without data loss', () async {
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
    await verifier.migrateAndValidate(database, 7);
    final note = await database.select(database.wordScriptureNotes).getSingle();
    final anchor = await database.select(database.wordScriptureNoteAnchors).getSingle();
    expect(note.id, 'note-v5');
    expect(note.body, 'Preserved private note.');
    expect(note.createdAtUtcMicros, 11);
    expect(note.updatedAtUtcMicros, 12);
    expect(anchor.noteId, 'note-v5');
    expect(anchor.ordinal, 0);
    expect(anchor.anchorKey, 'Exodus|6|2|');
    await expectLater(database.customStatement("INSERT INTO word_scripture_note_anchors (note_id, ordinal, anchor_key, book, chapter) VALUES ('note-v5', 1, 'Exodus|6|2|', 'Exodus', 6)"), throwsA(anything));
    await (database.delete(database.wordScriptureNotes)..where((t) => t.id.equals('note-v5'))).go();
    expect(await database.select(database.wordScriptureNoteAnchors).get(), isEmpty);
    expect((await database.select(database.localMigrationMetadata).getSingle()).targetSchemaVersion, 7);
    await database.close();
  });

  test('v1 migrates through v7 without losing Word data', () async {
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
    await verifier.migrateAndValidate(database, 7);
    expect(
      (await database.select(database.biblePlans).getSingle()).title,
      'Preserved Plan',
    );
    expect(await database.select(database.wordReaderStates).get(), isEmpty);
    expect(
      (await database.select(database.localMigrationMetadata).getSingle())
          .targetSchemaVersion,
      7,
    );
    await database.close();
  });
}
