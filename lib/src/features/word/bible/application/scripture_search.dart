import '../domain/reference_parser.dart';
import '../domain/scripture_reference.dart';

class SearchVerse {
  const SearchVerse(this.reference, this.text);
  final ScriptureReference reference;
  final String text;
}

class ScriptureSearchResult {
  const ScriptureSearchResult(this.reference, this.preview, {this.topic});
  final ScriptureReference reference;
  final String preview;
  final String? topic;
}

/// Local, deterministic Scripture retrieval. Concepts are an explicit editorial
/// index of canonical passages, never generated claims or remote user queries.
class ScriptureSearch {
  ScriptureSearch(this.loadVerses);
  final Future<List<SearchVerse>> Function() loadVerses;
  List<SearchVerse>? _verses;
  final _parser = ReferenceParser();

  Future<List<ScriptureSearchResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final parsed = _parser.parse(trimmed);
    if (parsed.isValid && parsed.references.length == 1) {
      return [ScriptureSearchResult(parsed.references.single, '')];
    }
    final normalized = normalize(trimmed);
    final words = normalized
        .split(' ')
        .where(
          (w) => !const {
            'the',
            'a',
            'an',
            'of',
            'and',
            'about',
            'on',
            'in',
            'what',
            'is',
            'are',
            'for',
            'to',
          }.contains(w),
        )
        .toSet();
    if (words.isEmpty) return [];
    final verses = _verses ??= await loadVerses();
    final ranked = <({int score, ScriptureSearchResult result})>[];
    for (final entry in topics) {
      final aliases = entry.aliases.map(normalize);
      if (!aliases.any(
        (alias) =>
            alias == normalized ||
            words.every(alias.split(' ').toSet().contains),
      )) {
        continue;
      }
      for (final ref in entry.references) {
        final text = verses
            .where(
              (v) =>
                  v.reference.book == ref.book &&
                  v.reference.startChapter == ref.startChapter &&
                  v.reference.startVerse! >= (ref.startVerse ?? 1) &&
                  v.reference.startVerse! <=
                      (ref.endVerse ?? ref.startVerse ?? 999),
            )
            .take(3)
            .map((v) => v.text)
            .join(' ');
        ranked.add((
          score: 200,
          result: ScriptureSearchResult(ref, text, topic: entry.name),
        ));
      }
    }
    for (final verse in verses) {
      final text = normalize(verse.text);
      final tokens = text.split(' ').toSet();
      final exact = ' $text '.contains(' $normalized ');
      if (!exact && !words.every(tokens.contains)) continue;
      ranked.add((
        score: exact ? 150 : 80,
        result: ScriptureSearchResult(verse.reference, verse.text),
      ));
    }
    final order = {for (var i = 0; i < ranked.length; i++) ranked[i].result: i};
    ranked.sort((a, b) {
      final score = b.score.compareTo(a.score);
      return score != 0 ? score : order[a.result]!.compareTo(order[b.result]!);
    });
    final seen = <String>{};
    return ranked
        .where((v) => seen.add(v.result.reference.display))
        .take(30)
        .map((v) => v.result)
        .toList();
  }

  static String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

class ScriptureTopic {
  const ScriptureTopic(this.name, this.aliases, this.references);
  final String name;
  final List<String> aliases;
  final List<ScriptureReference> references;
}

const topics = <ScriptureTopic>[
  ScriptureTopic(
    'Ten Commandments',
    ['ten commandments', 'decalogue', 'law of moses'],
    [
      ScriptureReference(
        book: 'Exodus',
        startChapter: 20,
        startVerse: 1,
        endVerse: 17,
      ),
      ScriptureReference(
        book: 'Deuteronomy',
        startChapter: 5,
        startVerse: 6,
        endVerse: 21,
      ),
    ],
  ),
  ScriptureTopic(
    'Creation',
    ['creation', 'beginning of the world'],
    [ScriptureReference(book: 'Genesis', startChapter: 1)],
  ),
  ScriptureTopic(
    'Noah and the flood',
    ['noah', 'noah ark', 'noahs ark', 'flood'],
    [
      ScriptureReference(book: 'Genesis', startChapter: 6),
      ScriptureReference(book: 'Genesis', startChapter: 7),
    ],
  ),
  ScriptureTopic(
    'The Exodus',
    ['exodus', 'red sea', 'crossing the red sea'],
    [ScriptureReference(book: 'Exodus', startChapter: 14)],
  ),
  ScriptureTopic(
    'David and Goliath',
    ['david and goliath', 'goliath'],
    [ScriptureReference(book: '1 Samuel', startChapter: 17)],
  ),
  ScriptureTopic(
    'The Good Shepherd',
    ['good shepherd', 'lord is my shepherd', 'psalm of the shepherd'],
    [
      ScriptureReference(book: 'Psalms', startChapter: 23),
      ScriptureReference(
        book: 'John',
        startChapter: 10,
        startVerse: 11,
        endVerse: 18,
      ),
    ],
  ),
  ScriptureTopic(
    'Sermon on the Mount',
    ['sermon on the mount', 'beatitudes'],
    [
      ScriptureReference(
        book: 'Matthew',
        startChapter: 5,
        startVerse: 1,
        endVerse: 12,
      ),
    ],
  ),
  ScriptureTopic(
    'The Lord’s Prayer',
    ['lords prayer', 'lord s prayer', 'our father', 'prayer'],
    [
      ScriptureReference(
        book: 'Matthew',
        startChapter: 6,
        startVerse: 9,
        endVerse: 13,
      ),
      ScriptureReference(
        book: 'Luke',
        startChapter: 11,
        startVerse: 1,
        endVerse: 4,
      ),
    ],
  ),
  ScriptureTopic(
    'The Good Samaritan',
    ['good samaritan', 'samaritan'],
    [
      ScriptureReference(
        book: 'Luke',
        startChapter: 10,
        startVerse: 25,
        endVerse: 37,
      ),
    ],
  ),
  ScriptureTopic(
    'The Prodigal Son',
    ['prodigal son', 'lost son'],
    [
      ScriptureReference(
        book: 'Luke',
        startChapter: 15,
        startVerse: 11,
        endVerse: 32,
      ),
    ],
  ),
  ScriptureTopic(
    'Birth of Jesus',
    ['birth of jesus', 'nativity', 'christmas'],
    [
      ScriptureReference(
        book: 'Luke',
        startChapter: 2,
        startVerse: 1,
        endVerse: 20,
      ),
    ],
  ),
  ScriptureTopic(
    'Resurrection',
    ['resurrection', 'easter', 'empty tomb'],
    [
      ScriptureReference(
        book: 'Matthew',
        startChapter: 28,
        startVerse: 1,
        endVerse: 10,
      ),
      ScriptureReference(
        book: 'John',
        startChapter: 20,
        startVerse: 1,
        endVerse: 18,
      ),
    ],
  ),
  ScriptureTopic(
    'Love',
    ['love', 'love chapter'],
    [ScriptureReference(book: '1 Corinthians', startChapter: 13)],
  ),
  ScriptureTopic(
    'Faith',
    ['faith', 'heroes of faith'],
    [ScriptureReference(book: 'Hebrews', startChapter: 11)],
  ),
  ScriptureTopic(
    'Anxiety and worry',
    ['anxiety', 'worry', 'fear', 'peace'],
    [
      ScriptureReference(
        book: 'Philippians',
        startChapter: 4,
        startVerse: 6,
        endVerse: 8,
      ),
      ScriptureReference(
        book: 'Matthew',
        startChapter: 6,
        startVerse: 25,
        endVerse: 34,
      ),
    ],
  ),
  ScriptureTopic(
    'Forgiveness',
    ['forgiveness', 'forgive'],
    [
      ScriptureReference(
        book: 'Matthew',
        startChapter: 18,
        startVerse: 21,
        endVerse: 35,
      ),
      ScriptureReference(book: 'Ephesians', startChapter: 4, startVerse: 32),
    ],
  ),
  ScriptureTopic(
    'Salvation',
    ['salvation', 'born again'],
    [
      ScriptureReference(
        book: 'John',
        startChapter: 3,
        startVerse: 1,
        endVerse: 21,
      ),
      ScriptureReference(
        book: 'Ephesians',
        startChapter: 2,
        startVerse: 8,
        endVerse: 10,
      ),
    ],
  ),
  ScriptureTopic(
    'Fruit of the Spirit',
    ['fruit of the spirit', 'fruits of the spirit'],
    [
      ScriptureReference(
        book: 'Galatians',
        startChapter: 5,
        startVerse: 22,
        endVerse: 23,
      ),
    ],
  ),
  ScriptureTopic(
    'Armour of God',
    ['armor of god', 'armour of god', 'spiritual warfare'],
    [
      ScriptureReference(
        book: 'Ephesians',
        startChapter: 6,
        startVerse: 10,
        endVerse: 18,
      ),
    ],
  ),
  ScriptureTopic(
    'Wisdom',
    ['wisdom'],
    [
      ScriptureReference(book: 'James', startChapter: 1, startVerse: 5),
      ScriptureReference(
        book: 'Proverbs',
        startChapter: 3,
        startVerse: 5,
        endVerse: 6,
      ),
    ],
  ),
  ScriptureTopic(
    'The Great Commission',
    ['great commission', 'make disciples'],
    [
      ScriptureReference(
        book: 'Matthew',
        startChapter: 28,
        startVerse: 18,
        endVerse: 20,
      ),
    ],
  ),
];
