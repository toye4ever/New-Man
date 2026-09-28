import 'bible_books.dart';
import 'scripture_reference.dart';

/// A canonical, translation-independent passage within one Bible chapter.
///
/// This intentionally reuses [ScriptureReference]'s canonical book identity
/// rather than creating a second catalogue or persisting rendered text.
class ScriptureAnchor {
  const ScriptureAnchor({
    required this.book,
    required this.chapter,
    this.startVerse,
    int? endVerse,
  }) : endVerse = startVerse == endVerse ? null : endVerse;

  final String book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;

  ScriptureReference get reference => ScriptureReference(
    book: book,
    startChapter: chapter,
    startVerse: startVerse,
    endVerse: endVerse,
  );

  String get display => reference.display;

  /// Stable persistence identity. Translation and presentation are excluded.
  String get key => '$book|$chapter|${startVerse ?? ''}|${endVerse ?? ''}';

  void validate() {
    final canonicalBook = bibleBookByName(book);
    if (canonicalBook == null ||
        chapter < 1 ||
        chapter > canonicalBook.chapterCount) {
      throw ArgumentError('Invalid canonical Scripture anchor.');
    }
    if (startVerse != null && startVerse! < 1 ||
        endVerse != null && endVerse! < 1) {
      throw ArgumentError('Verse numbers must be positive.');
    }
    if (startVerse != null && endVerse != null && endVerse! < startVerse!) {
      throw ArgumentError(
        'The ending verse cannot precede the starting verse.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ScriptureAnchor && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
