import '../../bible/domain/scripture_anchor.dart';
import '../domain/saved_scripture.dart';

abstract interface class SavedScriptureRepository {
  Future<List<ScriptureBookmark>> loadBookmarks();
  Future<bool> isBookmarked(ScriptureAnchor anchor);
  Future<void> saveBookmark(ScriptureAnchor anchor);
  Future<void> removeBookmark(ScriptureAnchor anchor);
  Future<List<ScriptureHighlight>> loadHighlights();
  Future<ScriptureHighlight?> highlightFor(ScriptureAnchor anchor);
  Future<void> saveHighlight(ScriptureAnchor anchor, HighlightStyle style);
  Future<void> removeHighlight(ScriptureAnchor anchor);
  Future<List<ScriptureNote>> loadNotes();
  Future<void> saveNote(ScriptureNote note);
  Future<void> deleteNote(String id);
  Future<List<ReadingHistoryItem>> loadHistory();
  Future<void> recordSuccessfulOpen(ScriptureAnchor anchor);
  Future<void> deleteHistory(ScriptureAnchor anchor);
  Future<void> clearHistory();
}

class VolatileSavedScriptureRepository implements SavedScriptureRepository {
  final Map<String, ScriptureBookmark> _bookmarks = {};
  final Map<String, ScriptureHighlight> _highlights = {};
  final Map<String, ScriptureNote> _notes = {};
  final Map<String, ReadingHistoryItem> _history = {};
  @override
  Future<List<ScriptureBookmark>> loadBookmarks() async =>
      _bookmarks.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  @override
  Future<bool> isBookmarked(ScriptureAnchor a) async =>
      _bookmarks.containsKey(a.key);
  @override
  Future<void> saveBookmark(ScriptureAnchor a) async {
    a.validate();
    _bookmarks[a.key] = ScriptureBookmark(
      anchor: a,
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> removeBookmark(ScriptureAnchor a) async {
    _bookmarks.remove(a.key);
  }

  @override
  Future<List<ScriptureHighlight>> loadHighlights() async =>
      _highlights.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  @override
  Future<ScriptureHighlight?> highlightFor(ScriptureAnchor a) async =>
      _highlights[a.key];
  @override
  Future<void> saveHighlight(ScriptureAnchor a, HighlightStyle s) async {
    a.validate();
    _highlights[a.key] = ScriptureHighlight(
      anchor: a,
      style: s,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> removeHighlight(ScriptureAnchor a) async {
    _highlights.remove(a.key);
  }

  @override
  Future<List<ScriptureNote>> loadNotes() async =>
      _notes.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  @override
  Future<void> saveNote(ScriptureNote n) async {
    if (n.anchors.isEmpty) throw ArgumentError('A Scripture note needs an anchor.');
    for (final anchor in n.anchors) { anchor.validate(); }
    _notes[n.id] = n;
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.remove(id);
  }

  @override
  Future<List<ReadingHistoryItem>> loadHistory() async =>
      _history.values.toList()
        ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
  @override
  Future<void> recordSuccessfulOpen(ScriptureAnchor a) async {
    a.validate();
    _history[a.key] = ReadingHistoryItem(
      anchor: a,
      openedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> deleteHistory(ScriptureAnchor a) async {
    _history.remove(a.key);
  }

  @override
  Future<void> clearHistory() async {
    _history.clear();
  }
}
