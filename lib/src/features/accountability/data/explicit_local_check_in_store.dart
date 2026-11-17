import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../domain/local_check_in.dart';

class LocalCheckInStorageException implements Exception {
  const LocalCheckInStorageException();
  @override
  String toString() => 'Local check-in storage is unavailable';
}

/// Dormant, separate store. No default path, automatic open, migration or UI use.
/// The caller must supply an owned, disposable/explicitly approved private file.
class ExplicitLocalCheckInStore implements LocalCheckInRepository {
  ExplicitLocalCheckInStore._(this._database);
  static const _applicationId = 0x4e4d4143;
  final Database _database;
  bool _closed = false;

  static ExplicitLocalCheckInStore openExplicitly(
    File file, {
    required bool persistenceOptIn,
  }) {
    // Consent is checked before opening or creating any file.
    if (!persistenceOptIn) {
      throw StateError('Local persistence requires opt-in');
    }
    if (!file.isAbsolute) {
      throw ArgumentError('An explicit absolute file is required');
    }
    Database? database;
    try {
      database = sqlite3.open(file.path);
      final id = database.select('PRAGMA application_id').single.values.single;
      final version = database
          .select('PRAGMA user_version')
          .single
          .values
          .single;
      final objects = database.select(
        "SELECT name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'",
      );
      if (id == 0 && version == 0 && objects.isEmpty) {
        database.execute('BEGIN IMMEDIATE');
        database.execute('''CREATE TABLE local_check_in_days (
          day TEXT PRIMARY KEY NOT NULL,
          morning_json TEXT,
          evening_status TEXT CHECK (evening_status IS NULL OR evening_status IN ('met', 'partly_met', 'not_met')),
          evening_notes TEXT,
          CHECK (day GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
          CHECK (evening_notes IS NULL OR evening_status IS NOT NULL)
        )''');
        database.execute('PRAGMA application_id = $_applicationId');
        database.execute('PRAGMA user_version = 2');
        database.execute('COMMIT');
      } else if (id != _applicationId ||
          version != 2 ||
          objects.length != 1 ||
          objects.single['name'] != 'local_check_in_days') {
        throw const LocalCheckInStorageException();
      }
      final columns = database
          .select('PRAGMA table_info(local_check_in_days)')
          .map((row) => row['name'])
          .toList();
      if (columns.join(',') !=
          'day,morning_json,evening_status,evening_notes') {
        throw const LocalCheckInStorageException();
      }
      return ExplicitLocalCheckInStore._(database);
    } catch (_) {
      if (database != null) {
        try {
          database.execute('ROLLBACK');
        } catch (_) {
          /* No transaction. */
        }
        database.close();
      }
      throw const LocalCheckInStorageException();
    }
  }

  T _access<T>(T Function() operation) {
    if (_closed) throw const LocalCheckInStorageException();
    try {
      return operation();
    } catch (_) {
      // Never expose SQL, paths, notes or engine diagnostics through this API.
      throw const LocalCheckInStorageException();
    }
  }

  LocalCheckIn _decode(Row row) {
    final raw = row['morning_json'] as String?;
    final morning = raw == null
        ? null
        : (jsonDecode(raw) as List).cast<String>();
    return LocalCheckIn(
      day: CheckInDay.parse(row['day'] as String),
      morningCommitments: morning,
      eveningOutcome: row['evening_status'] == null
          ? null
          : EveningOutcome.fromStorageKey(row['evening_status'] as String),
      eveningNotes: row['evening_notes'] as String?,
    );
  }

  @override
  LocalCheckIn? read(CheckInDay day) => _access(() {
    final rows = _database.select(
      'SELECT * FROM local_check_in_days WHERE day = ?',
      [day.key],
    );
    return rows.isEmpty ? null : _decode(rows.single);
  });

  @override
  List<LocalCheckIn> history({int limit = 30, int offset = 0}) {
    if (limit < 1 || limit > 100 || offset < 0) {
      throw ArgumentError('Invalid history page');
    }
    return _access(
      () => _database
          .select(
            'SELECT * FROM local_check_in_days ORDER BY day DESC LIMIT ? OFFSET ?',
            [limit, offset],
          )
          .map(_decode)
          .toList(growable: false),
    );
  }

  @override
  void writeMorning(CheckInDay day, List<String> commitments) {
    final draft = LocalCheckIn(day: day, morningCommitments: commitments);
    _access(
      () => _database.execute(
        '''
      INSERT INTO local_check_in_days(day, morning_json) VALUES (?, ?)
      ON CONFLICT(day) DO UPDATE SET morning_json = excluded.morning_json
    ''',
        [day.key, jsonEncode(draft.morningCommitments)],
      ),
    );
  }

  @override
  void writeEvening(
    CheckInDay day, {
    required EveningOutcome outcome,
    String? notes,
  }) {
    final draft = LocalCheckIn(
      day: day,
      eveningOutcome: outcome,
      eveningNotes: notes,
    );
    _access(
      () => _database.execute(
        '''
      INSERT INTO local_check_in_days(day, evening_status, evening_notes) VALUES (?, ?, ?)
      ON CONFLICT(day) DO UPDATE SET evening_status = excluded.evening_status,
        evening_notes = excluded.evening_notes
    ''',
        [day.key, draft.eveningOutcome!.storageKey, draft.eveningNotes],
      ),
    );
  }

  @override
  void close() {
    if (!_closed) {
      _database.close();
      _closed = true;
    }
  }
}
