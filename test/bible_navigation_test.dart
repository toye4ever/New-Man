import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/word/bible/domain/bible_books.dart';
import 'package:scripture_planner/src/features/word/bible/domain/bible_chapter_navigation.dart';
import 'package:scripture_planner/src/features/word/bible/domain/scripture_reference.dart';

void main() {
  const navigation = BibleChapterNavigation();

  test('canonical metadata contains the ordered 66-book canon', () {
    expect(bibleBooks, hasLength(66));
    expect(bibleBooks.first.name, 'Genesis');
    expect(bibleBooks.last.name, 'Revelation');
    expect(bibleBooks.map((book) => book.canonicalId).toSet(), hasLength(66));
    expect(bibleBookByName('Genesis')?.chapterCount, 50);
    expect(bibleBookByName('Psalms')?.chapterCount, 150);
    expect(bibleBookByName('Romans')?.chapterCount, 16);
    expect(bibleBookByName('Revelation')?.chapterCount, 22);
  });

  test('navigation respects Bible boundaries and crosses books', () {
    const genesis1 = ScriptureReference(book: 'Genesis', startChapter: 1);
    expect(navigation.previousChapter(genesis1), isNull);
    expect(navigation.isFirstChapter(genesis1), isTrue);

    expect(
      navigation
          .nextChapter(
            const ScriptureReference(book: 'Genesis', startChapter: 50),
          )
          ?.display,
      'Exodus 1',
    );
    expect(
      navigation
          .nextChapter(
            const ScriptureReference(book: 'Malachi', startChapter: 4),
          )
          ?.display,
      'Matthew 1',
    );
    expect(
      navigation
          .nextChapter(
            const ScriptureReference(book: 'Matthew', startChapter: 28),
          )
          ?.display,
      'Mark 1',
    );

    const revelation22 = ScriptureReference(
      book: 'Revelation',
      startChapter: 22,
    );
    expect(navigation.nextChapter(revelation22), isNull);
    expect(navigation.isLastChapter(revelation22), isTrue);
  });

  test('same-book previous and next return whole chapters', () {
    const romans8 = ScriptureReference(
      book: 'Romans',
      startChapter: 8,
      startVerse: 1,
      endVerse: 4,
    );
    expect(navigation.previousChapter(romans8)?.display, 'Romans 7');
    expect(navigation.nextChapter(romans8)?.display, 'Romans 9');
  });
}
