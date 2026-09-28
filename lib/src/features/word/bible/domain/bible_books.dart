import 'scripture_reference.dart';

class BibleBook {
  const BibleBook({
    required this.name,
    required this.chapterCount,
    required this.testament,
    required this.aliases,
  });

  final String name;
  final int chapterCount;
  final String testament;
  final List<String> aliases;

  String get canonicalId => name.toLowerCase().replaceAll(' ', '-');
}

const bibleBooks = <BibleBook>[
  BibleBook(
    name: 'Genesis',
    chapterCount: 50,
    testament: 'OT',
    aliases: ['gen', 'ge', 'gn'],
  ),
  BibleBook(
    name: 'Exodus',
    chapterCount: 40,
    testament: 'OT',
    aliases: ['exod', 'exo', 'ex'],
  ),
  BibleBook(
    name: 'Leviticus',
    chapterCount: 27,
    testament: 'OT',
    aliases: ['lev', 'lv'],
  ),
  BibleBook(
    name: 'Numbers',
    chapterCount: 36,
    testament: 'OT',
    aliases: ['num', 'nu', 'nm'],
  ),
  BibleBook(
    name: 'Deuteronomy',
    chapterCount: 34,
    testament: 'OT',
    aliases: ['deut', 'dt'],
  ),
  BibleBook(
    name: 'Joshua',
    chapterCount: 24,
    testament: 'OT',
    aliases: ['josh', 'jos'],
  ),
  BibleBook(
    name: 'Judges',
    chapterCount: 21,
    testament: 'OT',
    aliases: ['judg', 'jdg'],
  ),
  BibleBook(name: 'Ruth', chapterCount: 4, testament: 'OT', aliases: ['rth']),
  BibleBook(
    name: '1 Samuel',
    chapterCount: 31,
    testament: 'OT',
    aliases: ['1 samuel', '1 sam', '1sa', 'i samuel'],
  ),
  BibleBook(
    name: '2 Samuel',
    chapterCount: 24,
    testament: 'OT',
    aliases: ['2 samuel', '2 sam', '2sa', 'ii samuel'],
  ),
  BibleBook(
    name: '1 Kings',
    chapterCount: 22,
    testament: 'OT',
    aliases: ['1 kings', '1 king', '1ki', 'i kings'],
  ),
  BibleBook(
    name: '2 Kings',
    chapterCount: 25,
    testament: 'OT',
    aliases: ['2 kings', '2 king', '2ki', 'ii kings'],
  ),
  BibleBook(
    name: '1 Chronicles',
    chapterCount: 29,
    testament: 'OT',
    aliases: ['1 chronicles', '1 chron', '1 chr', '1ch'],
  ),
  BibleBook(
    name: '2 Chronicles',
    chapterCount: 36,
    testament: 'OT',
    aliases: ['2 chronicles', '2 chron', '2 chr', '2ch'],
  ),
  BibleBook(name: 'Ezra', chapterCount: 10, testament: 'OT', aliases: ['ezr']),
  BibleBook(
    name: 'Nehemiah',
    chapterCount: 13,
    testament: 'OT',
    aliases: ['neh', 'ne'],
  ),
  BibleBook(
    name: 'Esther',
    chapterCount: 10,
    testament: 'OT',
    aliases: ['esth', 'est'],
  ),
  BibleBook(name: 'Job', chapterCount: 42, testament: 'OT', aliases: []),
  BibleBook(
    name: 'Psalms',
    chapterCount: 150,
    testament: 'OT',
    aliases: ['psalm', 'ps', 'psa'],
  ),
  BibleBook(
    name: 'Proverbs',
    chapterCount: 31,
    testament: 'OT',
    aliases: ['prov', 'pro', 'pr'],
  ),
  BibleBook(
    name: 'Ecclesiastes',
    chapterCount: 12,
    testament: 'OT',
    aliases: ['eccles', 'ecc', 'eccl'],
  ),
  BibleBook(
    name: 'Song of Solomon',
    chapterCount: 8,
    testament: 'OT',
    aliases: ['song of songs', 'song', 'songs', 'sos'],
  ),
  BibleBook(
    name: 'Isaiah',
    chapterCount: 66,
    testament: 'OT',
    aliases: ['isa', 'is'],
  ),
  BibleBook(
    name: 'Jeremiah',
    chapterCount: 52,
    testament: 'OT',
    aliases: ['jer', 'je'],
  ),
  BibleBook(
    name: 'Lamentations',
    chapterCount: 5,
    testament: 'OT',
    aliases: ['lam'],
  ),
  BibleBook(
    name: 'Ezekiel',
    chapterCount: 48,
    testament: 'OT',
    aliases: ['ezek', 'eze'],
  ),
  BibleBook(
    name: 'Daniel',
    chapterCount: 12,
    testament: 'OT',
    aliases: ['dan', 'da'],
  ),
  BibleBook(name: 'Hosea', chapterCount: 14, testament: 'OT', aliases: ['hos']),
  BibleBook(name: 'Joel', chapterCount: 3, testament: 'OT', aliases: ['jl']),
  BibleBook(name: 'Amos', chapterCount: 9, testament: 'OT', aliases: ['am']),
  BibleBook(
    name: 'Obadiah',
    chapterCount: 1,
    testament: 'OT',
    aliases: ['obad', 'ob'],
  ),
  BibleBook(name: 'Jonah', chapterCount: 4, testament: 'OT', aliases: ['jon']),
  BibleBook(name: 'Micah', chapterCount: 7, testament: 'OT', aliases: ['mic']),
  BibleBook(name: 'Nahum', chapterCount: 3, testament: 'OT', aliases: ['nah']),
  BibleBook(
    name: 'Habakkuk',
    chapterCount: 3,
    testament: 'OT',
    aliases: ['hab'],
  ),
  BibleBook(
    name: 'Zephaniah',
    chapterCount: 3,
    testament: 'OT',
    aliases: ['zeph', 'zep'],
  ),
  BibleBook(name: 'Haggai', chapterCount: 2, testament: 'OT', aliases: ['hag']),
  BibleBook(
    name: 'Zechariah',
    chapterCount: 14,
    testament: 'OT',
    aliases: ['zech', 'zec'],
  ),
  BibleBook(
    name: 'Malachi',
    chapterCount: 4,
    testament: 'OT',
    aliases: ['mal'],
  ),
  BibleBook(
    name: 'Matthew',
    chapterCount: 28,
    testament: 'NT',
    aliases: ['matt', 'mt'],
  ),
  BibleBook(
    name: 'Mark',
    chapterCount: 16,
    testament: 'NT',
    aliases: ['mrk', 'mk'],
  ),
  BibleBook(
    name: 'Luke',
    chapterCount: 24,
    testament: 'NT',
    aliases: ['luk', 'lk'],
  ),
  BibleBook(
    name: 'John',
    chapterCount: 21,
    testament: 'NT',
    aliases: ['jn', 'jhn'],
  ),
  BibleBook(
    name: 'Acts',
    chapterCount: 28,
    testament: 'NT',
    aliases: ['act', 'ac'],
  ),
  BibleBook(
    name: 'Romans',
    chapterCount: 16,
    testament: 'NT',
    aliases: ['rom', 'ro'],
  ),
  BibleBook(
    name: '1 Corinthians',
    chapterCount: 16,
    testament: 'NT',
    aliases: ['1 corinthians', '1 cor', '1co'],
  ),
  BibleBook(
    name: '2 Corinthians',
    chapterCount: 13,
    testament: 'NT',
    aliases: ['2 corinthians', '2 cor', '2co'],
  ),
  BibleBook(
    name: 'Galatians',
    chapterCount: 6,
    testament: 'NT',
    aliases: ['gal'],
  ),
  BibleBook(
    name: 'Ephesians',
    chapterCount: 6,
    testament: 'NT',
    aliases: ['eph'],
  ),
  BibleBook(
    name: 'Philippians',
    chapterCount: 4,
    testament: 'NT',
    aliases: ['phil', 'php'],
  ),
  BibleBook(
    name: 'Colossians',
    chapterCount: 4,
    testament: 'NT',
    aliases: ['col'],
  ),
  BibleBook(
    name: '1 Thessalonians',
    chapterCount: 5,
    testament: 'NT',
    aliases: ['1 thessalonians', '1 thess', '1th'],
  ),
  BibleBook(
    name: '2 Thessalonians',
    chapterCount: 3,
    testament: 'NT',
    aliases: ['2 thessalonians', '2 thess', '2th'],
  ),
  BibleBook(
    name: '1 Timothy',
    chapterCount: 6,
    testament: 'NT',
    aliases: ['1 timothy', '1 tim', '1ti'],
  ),
  BibleBook(
    name: '2 Timothy',
    chapterCount: 4,
    testament: 'NT',
    aliases: ['2 timothy', '2 tim', '2ti'],
  ),
  BibleBook(name: 'Titus', chapterCount: 3, testament: 'NT', aliases: ['tit']),
  BibleBook(
    name: 'Philemon',
    chapterCount: 1,
    testament: 'NT',
    aliases: ['philem', 'phm'],
  ),
  BibleBook(
    name: 'Hebrews',
    chapterCount: 13,
    testament: 'NT',
    aliases: ['heb'],
  ),
  BibleBook(
    name: 'James',
    chapterCount: 5,
    testament: 'NT',
    aliases: ['jas', 'jam'],
  ),
  BibleBook(
    name: '1 Peter',
    chapterCount: 5,
    testament: 'NT',
    aliases: ['1 peter', '1 pet', '1pe'],
  ),
  BibleBook(
    name: '2 Peter',
    chapterCount: 3,
    testament: 'NT',
    aliases: ['2 peter', '2 pet', '2pe'],
  ),
  BibleBook(
    name: '1 John',
    chapterCount: 5,
    testament: 'NT',
    aliases: ['1 john', '1 jn', '1jn'],
  ),
  BibleBook(
    name: '2 John',
    chapterCount: 1,
    testament: 'NT',
    aliases: ['2 john', '2 jn', '2jn'],
  ),
  BibleBook(
    name: '3 John',
    chapterCount: 1,
    testament: 'NT',
    aliases: ['3 john', '3 jn', '3jn'],
  ),
  BibleBook(name: 'Jude', chapterCount: 1, testament: 'NT', aliases: ['jud']),
  BibleBook(
    name: 'Revelation',
    chapterCount: 22,
    testament: 'NT',
    aliases: ['rev', 'revelations', 'apocalypse'],
  ),
];

Map<String, BibleBook> buildBibleAliasMap() {
  final result = <String, BibleBook>{};
  for (final book in bibleBooks) {
    result[book.name.toLowerCase()] = book;
    for (final alias in book.aliases) {
      result[alias.toLowerCase()] = book;
    }
  }
  return result;
}

List<ScriptureReference> allChapters({String? testament}) {
  final references = <ScriptureReference>[];
  for (final book in bibleBooks) {
    if (testament != null && book.testament != testament) {
      continue;
    }
    for (var chapter = 1; chapter <= book.chapterCount; chapter++) {
      references.add(
        ScriptureReference(book: book.name, startChapter: chapter),
      );
    }
  }
  return references;
}

List<ScriptureReference> chaptersForBooks(Iterable<String> names) {
  final wanted = names.toSet();
  final references = <ScriptureReference>[];
  for (final book in bibleBooks.where((item) => wanted.contains(item.name))) {
    for (var chapter = 1; chapter <= book.chapterCount; chapter++) {
      references.add(
        ScriptureReference(book: book.name, startChapter: chapter),
      );
    }
  }
  return references;
}

BibleBook? bibleBookByName(String name) {
  final normalized = name.trim().toLowerCase();
  for (final book in bibleBooks) {
    if (book.name.toLowerCase() == normalized ||
        book.aliases.any((alias) => alias.toLowerCase() == normalized)) {
      return book;
    }
  }
  return null;
}
