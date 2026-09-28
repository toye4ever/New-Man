import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/word/bible/data/drift_reader_state_repository.dart';
import 'package:scripture_planner/src/features/word/bible/data/local/word_reader_state_dao.dart';
import 'package:scripture_planner/src/features/word/bible/domain/reader_position.dart';
import 'package:scripture_planner/src/features/word/translations/domain/bible_translation.dart';

void main() {
  late AppDatabase database;
  late DriftReaderStateRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftReaderStateRepository(WordReaderStateDao(database));
  });

  tearDown(() => database.close());

  test(
    'reader state starts empty, saves, and overwrites one latest row',
    () async {
      expect(await repository.load(), isNull);

      await repository.save(
        ReaderPosition(
          book: 'Romans',
          chapter: 8,
          translation: BibleTranslation.kjv,
          updatedAt: DateTime.utc(2026, 8, 15, 10),
        ),
      );
      var loaded = await repository.load();
      expect(loaded?.book, 'Romans');
      expect(loaded?.chapter, 8);
      expect(loaded?.translation, BibleTranslation.kjv);

      await repository.save(
        ReaderPosition(
          book: 'John',
          chapter: 3,
          translation: BibleTranslation.nlt,
          updatedAt: DateTime.utc(2026, 8, 15, 11),
        ),
      );
      loaded = await repository.load();
      expect(loaded?.book, 'John');
      expect(loaded?.chapter, 3);
      expect(loaded?.translation, BibleTranslation.nlt);
      expect(
        await database.select(database.wordReaderStates).get(),
        hasLength(1),
      );
    },
  );
}
