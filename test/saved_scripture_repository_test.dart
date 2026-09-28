import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/word/bible/domain/scripture_anchor.dart';
import 'package:scripture_planner/src/features/word/saved_scripture/data/drift_saved_scripture_repository.dart';
import 'package:scripture_planner/src/features/word/saved_scripture/domain/saved_scripture.dart';

void main() {
  late AppDatabase database;
  late DriftSavedScriptureRepository repository;
  const anchor = ScriptureAnchor(
    book: 'Romans',
    chapter: 8,
    startVerse: 1,
    endVerse: 4,
  );

  test('normalizes an equivalent single-verse range into one canonical anchor', () async {
    const single = ScriptureAnchor(book: 'Matthew', chapter: 5, startVerse: 1);
    const equivalentRange = ScriptureAnchor(
      book: 'Matthew',
      chapter: 5,
      startVerse: 1,
      endVerse: 1,
    );
    const range = ScriptureAnchor(
      book: 'Matthew',
      chapter: 5,
      startVerse: 1,
      endVerse: 3,
    );
    expect(equivalentRange.display, 'Matthew 5:1');
    expect(equivalentRange, single);
    expect(range.display, 'Matthew 5:1-3');
    await repository.saveBookmark(single);
    await repository.saveBookmark(equivalentRange);
    expect(await repository.loadBookmarks(), hasLength(1));
  });
  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftSavedScriptureRepository(database);
  });
  tearDown(() => database.close());

  test(
    'canonical bookmarks deduplicate and highlights update in place',
    () async {
      await repository.saveBookmark(anchor);
      await repository.saveBookmark(anchor);
      expect(await repository.isBookmarked(anchor), isTrue);
      expect(await repository.loadBookmarks(), hasLength(1));
      await repository.saveHighlight(anchor, HighlightStyle.gold);
      await repository.saveHighlight(anchor, HighlightStyle.blue);
      final highlights = await repository.loadHighlights();
      expect(highlights, hasLength(1));
      expect(highlights.single.style, HighlightStyle.blue);
      await repository.removeBookmark(anchor);
      await repository.removeHighlight(anchor);
      expect(await repository.loadBookmarks(), isEmpty);
      expect(await repository.loadHighlights(), isEmpty);
    },
  );

  test('plain-text notes persist independently from local history', () async {
    final created = DateTime.utc(2026, 8, 17, 12);
    final note = ScriptureNote(
      id: 'note-1',
      anchors: const [anchor],
      body: 'Keep this private.',
      createdAt: created,
      updatedAt: created,
    );
    await repository.saveNote(note);
    await repository.recordSuccessfulOpen(anchor);
    await repository.clearHistory();
    expect((await repository.loadNotes()).single.body, 'Keep this private.');
    expect(await repository.loadHistory(), isEmpty);
  });

  test('one note keeps ordered sparse anchors without duplicates', () async {
    final created = DateTime.utc(2026, 8, 20, 12);
    const two = ScriptureAnchor(book: 'Exodus', chapter: 6, startVerse: 2);
    const five = ScriptureAnchor(book: 'Exodus', chapter: 6, startVerse: 5);
    const twelve = ScriptureAnchor(book: 'Exodus', chapter: 6, startVerse: 12);
    await repository.saveNote(ScriptureNote(id: 'sparse', anchors: const [two, five, two, twelve], body: 'Private.', createdAt: created, updatedAt: created));
    final note = (await repository.loadNotes()).single;
    expect(note.anchors, [two, five, twelve]);
  });

  test(
    'history refreshes one translation-independent canonical anchor',
    () async {
      await repository.recordSuccessfulOpen(anchor);
      await repository.recordSuccessfulOpen(anchor);
      expect(await repository.loadHistory(), hasLength(1));
    },
  );
}
