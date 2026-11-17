import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:scripture_planner/src/features/accountability/data/explicit_local_check_in_store.dart';
import 'package:scripture_planner/src/features/accountability/domain/local_check_in.dart';

void main() {
  late Directory directory;
  late File file;
  ExplicitLocalCheckInStore? store;
  final first = CheckInDay(2026, 11, 16);
  final next = CheckInDay(2026, 11, 17);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('synthetic-check-in-');
    file = File('${directory.path}/explicit.sqlite');
  });
  tearDown(() async {
    store?.close();
    store = null;
    await directory.delete(recursive: true);
  });
  ExplicitLocalCheckInStore open() =>
      ExplicitLocalCheckInStore.openExplicitly(file, persistenceOptIn: true);

  test('no opt-in creates no file and never uses a default directory', () {
    expect(
      () => ExplicitLocalCheckInStore.openExplicitly(
        file,
        persistenceOptIn: false,
      ),
      throwsStateError,
    );
    expect(file.existsSync(), isFalse);
    expect(
      () => ExplicitLocalCheckInStore.openExplicitly(
        File('relative.sqlite'),
        persistenceOptIn: true,
      ),
      throwsArgumentError,
    );
  });

  test(
    'explicit writes are idempotent and isolated across fresh connections',
    () {
      store = open();
      final commitments = ['Synthetic first', 'Synthetic second'];
      store!.writeMorning(first, commitments);
      store!.writeMorning(first, commitments);
      commitments[0] = 'Caller changed its own list';
      store!.writeEvening(
        first,
        outcome: EveningOutcome.met,
        notes: 'Synthetic note',
      );
      store!.writeEvening(
        first,
        outcome: EveningOutcome.met,
        notes: 'Synthetic note',
      );
      store!.writeMorning(next, ['Next day only']);
      expect(store!.history(), hasLength(2));
      store!.close();
      store = open();
      final retained = store!.read(first)!;
      expect(retained.morningCommitments, [
        'Synthetic first',
        'Synthetic second',
      ]);
      expect(retained.eveningOutcome, EveningOutcome.met);
      expect(retained.eveningNotes, 'Synthetic note');
      expect(store!.read(next)!.eveningOutcome, isNull);
      expect(store!.read(CheckInDay(2026, 11, 18)), isNull);
      expect(store!.history(limit: 1).single.day, next);
      expect(store!.history(limit: 1, offset: 1).single.day, first);
      expect(
        () => retained.morningCommitments!.add('Unexpected'),
        throwsUnsupportedError,
      );
      // Editing one explicit section preserves the other and the adjacent day.
      store!.writeMorning(first, ['Revised synthetic commitment']);
      store!.close();
      store = open();
      expect(store!.read(first)!.morningCommitments, [
        'Revised synthetic commitment',
      ]);
      expect(store!.read(first)!.eveningNotes, 'Synthetic note');
      expect(store!.read(next)!.morningCommitments, ['Next day only']);
      store!.writeEvening(next, outcome: EveningOutcome.partlyMet);
      expect(store!.read(first)!.eveningOutcome, EveningOutcome.met);
    },
  );

  test(
    'failed statement rolls back all writes and returns sanitized failure',
    () {
      store = open();
      store!.writeMorning(first, ['Retained synthetic commitment']);
      store!.writeEvening(
        next,
        outcome: EveningOutcome.notMet,
        notes: 'Retained note',
      );
      final injector = sqlite3.open(file.path);
      injector.execute(
        '''CREATE TRIGGER synthetic_failure BEFORE UPDATE ON local_check_in_days
      WHEN NEW.day = '2026-11-16' BEGIN
      UPDATE local_check_in_days SET evening_notes = 'Unwanted change' WHERE day = '2026-11-17';
      SELECT RAISE(ABORT, 'Synthetic private engine diagnostic'); END''',
      );
      try {
        expect(
          () => store!.writeEvening(first, outcome: EveningOutcome.met),
          throwsA(
            isA<LocalCheckInStorageException>().having(
              (error) => error.toString(),
              'sanitized message',
              'Local check-in storage is unavailable',
            ),
          ),
        );
        expect(store!.read(first)!.eveningOutcome, isNull);
        expect(store!.read(first)!.morningCommitments, [
          'Retained synthetic commitment',
        ]);
        expect(store!.read(next)!.eveningNotes, 'Retained note');
      } finally {
        injector.execute('DROP TRIGGER synthetic_failure');
        injector.close();
      }
      store!.close();
      store = open();
      expect(store!.read(first)!.eveningOutcome, isNull);
      expect(store!.read(next)!.eveningNotes, 'Retained note');
      expect(store!.history(), hasLength(2));
    },
  );

  test('all approved outcomes use stable keys and survive reopen', () {
    store = open();
    for (final outcome in EveningOutcome.values) {
      final day = CheckInDay(2026, 11, 20 + outcome.index);
      store!.writeEvening(
        day,
        outcome: outcome,
        notes: 'Synthetic optional note',
      );
    }
    store!.close();
    store = open();
    final expectedKeys = ['met', 'partly_met', 'not_met'];
    final inspection = sqlite3.open(file.path);
    try {
      expect(
        inspection
            .select(
              'SELECT evening_status FROM local_check_in_days ORDER BY day',
            )
            .map((row) => row['evening_status'])
            .toList(),
        expectedKeys,
      );
    } finally {
      inspection.close();
    }
    for (final outcome in EveningOutcome.values) {
      final entry = store!.read(CheckInDay(2026, 11, 20 + outcome.index))!;
      expect(entry.eveningOutcome, outcome);
      expect(entry.eveningNotes, 'Synthetic optional note');
      expect(entry.morningCommitments, isNull);
    }
    expect(store!.read(first), isNull); // Missing is not inferred as not met.
    store!.writeMorning(first, ['Synthetic morning only']);
    expect(store!.read(first)!.eveningOutcome, isNull);
    expect(store!.read(first)!.eveningNotes, isNull);
  });

  test(
    'DB rejects arbitrary outcomes and strict decode rejects injected corruption',
    () {
      store = open();
      store!.writeEvening(
        first,
        outcome: EveningOutcome.met,
        notes: 'Retained note',
      );
      final injector = sqlite3.open(file.path);
      try {
        for (final invalid in ['other', 'partly met', 'MET', '', ' ']) {
          expect(
            () => injector.execute(
              'UPDATE local_check_in_days SET evening_status = ? WHERE day = ?',
              [invalid, first.key],
            ),
            throwsA(isA<SqliteException>()),
          );
          expect(
            () => EveningOutcome.fromStorageKey(invalid),
            throwsFormatException,
          );
        }
        expect(store!.read(first)!.eveningOutcome, EveningOutcome.met);
        // Deliberately bypass SQLite CHECKs in this synthetic corruption fixture.
        injector.execute('PRAGMA ignore_check_constraints = ON');
        injector.execute(
          'UPDATE local_check_in_days SET evening_status = ? WHERE day = ?',
          ['Invalid synthetic outcome', first.key],
        );
      } finally {
        injector.close();
      }
      store!.close();
      store = open();
      expect(
        () => store!.read(first),
        throwsA(isA<LocalCheckInStorageException>()),
      );
      expect(
        () => store!.history(),
        throwsA(isA<LocalCheckInStorageException>()),
      );
      expect(store!.read(next), isNull);
    },
  );

  test(
    'untyped private prototype is rejected without migration or byte changes',
    () {
      final prototype = sqlite3.open(file.path);
      prototype.execute('PRAGMA application_id = 0x4e4d4143');
      prototype.execute('PRAGMA user_version = 1');
      prototype.execute('''CREATE TABLE local_check_in_days (
      day TEXT PRIMARY KEY, morning_json TEXT, evening_status TEXT, evening_notes TEXT
    )''');
      prototype.execute(
        "INSERT INTO local_check_in_days VALUES ('2026-11-16', NULL, 'Synthetic legacy status', NULL)",
      );
      prototype.close();
      final before = file.readAsBytesSync();
      expect(open, throwsA(isA<LocalCheckInStorageException>()));
      expect(file.readAsBytesSync(), before);
    },
  );

  test('existing foreign database is rejected without modifying its bytes', () {
    final foreign = sqlite3.open(file.path);
    foreign.execute('CREATE TABLE synthetic_sentinel(value TEXT)');
    foreign.execute("INSERT INTO synthetic_sentinel VALUES ('Preserve')");
    foreign.close();
    final before = file.readAsBytesSync();
    expect(open, throwsA(isA<LocalCheckInStorageException>()));
    expect(file.readAsBytesSync(), before);
  });

  test(
    'canonical local dates preserve DST day identity and reject rollover',
    () {
      store = open();
      for (final day in [
        CheckInDay(2026, 3, 8),
        CheckInDay(2026, 3, 9),
        CheckInDay(2026, 11, 1),
        CheckInDay(2026, 11, 2),
      ]) {
        expect(
          CheckInDay.fromLocal(DateTime(day.year, day.month, day.day)),
          day,
        );
        expect(CheckInDay.parse(day.key), day);
        store!.writeMorning(day, [day.key]);
      }
      expect(
        store!.history().map((entry) => entry.day.key).toSet(),
        hasLength(4),
      );
      expect(() => CheckInDay(2026, 2, 30), throwsArgumentError);
      expect(() => CheckInDay.parse('2026-1-01'), throwsFormatException);
      expect(() => EveningOutcome.fromStorageKey(' '), throwsFormatException);
      expect(() => store!.writeMorning(first, [' ']), throwsArgumentError);
      expect(store!.read(first), isNull);
      expect(() => store!.history(limit: 0), throwsArgumentError);
      store!.close();
      expect(
        () => store!.read(first),
        throwsA(isA<LocalCheckInStorageException>()),
      );
    },
  );
}
