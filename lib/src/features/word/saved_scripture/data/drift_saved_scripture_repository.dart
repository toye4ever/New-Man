import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../bible/domain/scripture_anchor.dart';
import '../application/saved_scripture_repository.dart';
import '../domain/saved_scripture.dart';

class DriftSavedScriptureRepository implements SavedScriptureRepository {
  const DriftSavedScriptureRepository(this.database);
  final AppDatabase database;

  int _now() => DateTime.now().toUtc().microsecondsSinceEpoch;
  ScriptureAnchor _anchor(String book, int chapter, int? start, int? end) =>
      ScriptureAnchor(
        book: book,
        chapter: chapter,
        startVerse: start,
        endVerse: end,
      );

  @override
  Future<List<ScriptureBookmark>> loadBookmarks() async =>
      (await (database.select(
            database.wordScriptureBookmarks,
          )..orderBy([(t) => OrderingTerm.desc(t.createdAtUtcMicros)])).get())
          .map(
            (r) => ScriptureBookmark(
              anchor: _anchor(r.book, r.chapter, r.startVerse, r.endVerse),
              createdAt: DateTime.fromMicrosecondsSinceEpoch(
                r.createdAtUtcMicros,
                isUtc: true,
              ),
            ),
          )
          .toList();
  @override
  Future<bool> isBookmarked(ScriptureAnchor a) async => (await (database.select(
    database.wordScriptureBookmarks,
  )..where((t) => t.anchorKey.equals(a.key))).get()).isNotEmpty;
  @override
  Future<void> saveBookmark(ScriptureAnchor a) async {
    a.validate();
    await database
        .into(database.wordScriptureBookmarks)
        .insertOnConflictUpdate(
          WordScriptureBookmarksCompanion.insert(
            anchorKey: a.key,
            book: a.book,
            chapter: a.chapter,
            startVerse: Value(a.startVerse),
            endVerse: Value(a.endVerse),
            createdAtUtcMicros: _now(),
          ),
        );
  }

  @override
  Future<void> removeBookmark(ScriptureAnchor a) => (database.delete(
    database.wordScriptureBookmarks,
  )..where((t) => t.anchorKey.equals(a.key))).go();

  @override
  Future<List<ScriptureHighlight>> loadHighlights() async =>
      (await (database.select(
            database.wordScriptureHighlights,
          )..orderBy([(t) => OrderingTerm.desc(t.updatedAtUtcMicros)])).get())
          .map(
            (r) => ScriptureHighlight(
              anchor: _anchor(r.book, r.chapter, r.startVerse, r.endVerse),
              style: HighlightStyleLabel.fromStorage(r.style),
              updatedAt: DateTime.fromMicrosecondsSinceEpoch(
                r.updatedAtUtcMicros,
                isUtc: true,
              ),
            ),
          )
          .toList();
  @override
  Future<ScriptureHighlight?> highlightFor(ScriptureAnchor a) async {
    final r = await (database.select(
      database.wordScriptureHighlights,
    )..where((t) => t.anchorKey.equals(a.key))).getSingleOrNull();
    return r == null
        ? null
        : ScriptureHighlight(
            anchor: _anchor(r.book, r.chapter, r.startVerse, r.endVerse),
            style: HighlightStyleLabel.fromStorage(r.style),
            updatedAt: DateTime.fromMicrosecondsSinceEpoch(
              r.updatedAtUtcMicros,
              isUtc: true,
            ),
          );
  }

  @override
  Future<void> saveHighlight(ScriptureAnchor a, HighlightStyle s) async {
    a.validate();
    await database
        .into(database.wordScriptureHighlights)
        .insertOnConflictUpdate(
          WordScriptureHighlightsCompanion.insert(
            anchorKey: a.key,
            book: a.book,
            chapter: a.chapter,
            startVerse: Value(a.startVerse),
            endVerse: Value(a.endVerse),
            style: s.storageValue,
            updatedAtUtcMicros: _now(),
          ),
        );
  }

  @override
  Future<void> removeHighlight(ScriptureAnchor a) => (database.delete(
    database.wordScriptureHighlights,
  )..where((t) => t.anchorKey.equals(a.key))).go();

  @override
  Future<List<ScriptureNote>> loadNotes() async {
    final rows = await (database.select(
            database.wordScriptureNotes,
          )..orderBy([(t) => OrderingTerm.desc(t.updatedAtUtcMicros)])).get();
    return [for (final r in rows) ScriptureNote(
              id: r.id,
              anchors: await _noteAnchors(r.id),
              body: r.body,
              createdAt: DateTime.fromMicrosecondsSinceEpoch(
                r.createdAtUtcMicros,
                isUtc: true,
              ),
              updatedAt: DateTime.fromMicrosecondsSinceEpoch(
                r.updatedAtUtcMicros,
                isUtc: true,
              ),
            )];
  }

  Future<List<ScriptureAnchor>> _noteAnchors(String noteId) async =>
      (await (database.select(database.wordScriptureNoteAnchors)
            ..where((t) => t.noteId.equals(noteId))
            ..orderBy([(t) => OrderingTerm.asc(t.ordinal)])).get())
          .map((r) => _anchor(r.book, r.chapter, r.startVerse, r.endVerse))
          .toList();
  @override
  Future<void> saveNote(ScriptureNote n) async {
    if (n.anchors.isEmpty) throw ArgumentError('A Scripture note needs an anchor.');
    final anchors = <ScriptureAnchor>[];
    for (final anchor in n.anchors) {
      anchor.validate();
      if (!anchors.any((existing) => existing == anchor)) anchors.add(anchor);
    }
    if (n.body.trim().isEmpty) {
      throw ArgumentError('A Scripture note cannot be empty.');
    }
    await database.transaction(() async {
      final primary = anchors.first;
      await database.into(database.wordScriptureNotes).insertOnConflictUpdate(
          WordScriptureNotesCompanion.insert(
            id: n.id,
            anchorKey: primary.key,
            book: primary.book,
            chapter: primary.chapter,
            startVerse: Value(primary.startVerse),
            endVerse: Value(primary.endVerse),
            body: n.body.trim(),
            createdAtUtcMicros: n.createdAt.toUtc().microsecondsSinceEpoch,
            updatedAtUtcMicros: n.updatedAt.toUtc().microsecondsSinceEpoch,
          ),
      );
      await (database.delete(database.wordScriptureNoteAnchors)..where((t) => t.noteId.equals(n.id))).go();
      for (var index = 0; index < anchors.length; index++) {
        final anchor = anchors[index];
        await database.into(database.wordScriptureNoteAnchors).insert(WordScriptureNoteAnchorsCompanion.insert(noteId: n.id, ordinal: index, anchorKey: anchor.key, book: anchor.book, chapter: anchor.chapter, startVerse: Value(anchor.startVerse), endVerse: Value(anchor.endVerse)));
      }
    });
  }

  @override
  Future<void> deleteNote(String id) => (database.delete(
    database.wordScriptureNotes,
  )..where((t) => t.id.equals(id))).go();

  @override
  Future<List<ReadingHistoryItem>> loadHistory() async =>
      (await (database.select(
            database.wordReadingHistory,
          )..orderBy([(t) => OrderingTerm.desc(t.openedAtUtcMicros)])).get())
          .map(
            (r) => ReadingHistoryItem(
              anchor: _anchor(r.book, r.chapter, r.startVerse, r.endVerse),
              openedAt: DateTime.fromMicrosecondsSinceEpoch(
                r.openedAtUtcMicros,
                isUtc: true,
              ),
            ),
          )
          .toList();
  @override
  Future<void> recordSuccessfulOpen(ScriptureAnchor a) async {
    a.validate();
    await database
        .into(database.wordReadingHistory)
        .insertOnConflictUpdate(
          WordReadingHistoryCompanion.insert(
            anchorKey: a.key,
            book: a.book,
            chapter: a.chapter,
            startVerse: Value(a.startVerse),
            endVerse: Value(a.endVerse),
            openedAtUtcMicros: _now(),
          ),
        );
  }

  @override
  Future<void> deleteHistory(ScriptureAnchor a) => (database.delete(
    database.wordReadingHistory,
  )..where((t) => t.anchorKey.equals(a.key))).go();
  @override
  Future<void> clearHistory() =>
      database.delete(database.wordReadingHistory).go();
}
