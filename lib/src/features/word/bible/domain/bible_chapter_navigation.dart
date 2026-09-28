import 'bible_books.dart';
import 'scripture_reference.dart';

class BibleChapterNavigation {
  const BibleChapterNavigation();

  ScriptureReference? previousChapter(ScriptureReference current) {
    final index = _bookIndex(current.book);
    if (index == null || !_isValidChapter(index, current.startChapter)) {
      return null;
    }
    if (current.startChapter > 1) {
      return _chapter(bibleBooks[index], current.startChapter - 1);
    }
    if (index == 0) return null;
    final previousBook = bibleBooks[index - 1];
    return _chapter(previousBook, previousBook.chapterCount);
  }

  ScriptureReference? nextChapter(ScriptureReference current) {
    final index = _bookIndex(current.book);
    if (index == null || !_isValidChapter(index, current.resolvedEndChapter)) {
      return null;
    }
    final chapter = current.resolvedEndChapter;
    if (chapter < bibleBooks[index].chapterCount) {
      return _chapter(bibleBooks[index], chapter + 1);
    }
    if (index == bibleBooks.length - 1) return null;
    return _chapter(bibleBooks[index + 1], 1);
  }

  bool isFirstChapter(ScriptureReference current) =>
      previousChapter(current) == null;

  bool isLastChapter(ScriptureReference current) =>
      nextChapter(current) == null;

  int? _bookIndex(String name) {
    final canonical = bibleBookByName(name);
    if (canonical == null) return null;
    final index = bibleBooks.indexOf(canonical);
    return index < 0 ? null : index;
  }

  bool _isValidChapter(int bookIndex, int chapter) =>
      chapter >= 1 && chapter <= bibleBooks[bookIndex].chapterCount;

  ScriptureReference _chapter(BibleBook book, int chapter) =>
      ScriptureReference(book: book.name, startChapter: chapter);
}
