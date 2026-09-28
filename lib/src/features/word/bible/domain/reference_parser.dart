import 'bible_books.dart';
import 'reference_parse_result.dart';
import 'scripture_reference.dart';

class ReferenceParser {
  ReferenceParser() : _aliases = buildBibleAliasMap() {
    _sortedAliases = _aliases.keys.toList()
      ..sort((left, right) => right.length.compareTo(left.length));
  }

  final Map<String, BibleBook> _aliases;
  late final List<String> _sortedAliases;

  ReferenceParseResult parse(String input) {
    var normalized = input
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'\s+and\s+', caseSensitive: false), ',')
        .trim();

    // Go To accepts the compact forms people commonly type on a keyboard
    // ("rom 4 3" and "rom 4 3 8") without making parsing heuristic. This
    // transformation is deliberately limited to a book followed by two or
    // three positive integer tokens; all other grammar remains unchanged.
    normalized = _normalizeCompactVerseSyntax(normalized);

    if (normalized.isEmpty) {
      return const ReferenceParseResult(
        references: <ScriptureReference>[],
        issues: <ReferenceParseIssue>[],
      );
    }

    final references = <ScriptureReference>[];
    final issues = <ReferenceParseIssue>[];
    BibleBook? currentBook;

    final groups = normalized.split(RegExp(r'[;\n\r]+'));
    for (final group in groups) {
      final pieces = group.split(',');
      for (final rawPiece in pieces) {
        final piece = rawPiece.trim();
        if (piece.isEmpty) {
          continue;
        }

        final match = _matchBook(piece);
        String numberPart;
        if (match != null) {
          currentBook = match.book;
          numberPart = piece.substring(match.aliasLength).trim();
        } else {
          numberPart = piece;
        }

        if (currentBook == null) {
          issues.add(
            ReferenceParseIssue(
              input: piece,
              message: 'Add a Bible book before this chapter or verse.',
            ),
          );
          continue;
        }

        final parsed = _parseNumberPart(currentBook, numberPart);
        if (parsed.reference != null) {
          references.add(parsed.reference!);
        } else {
          issues.add(
            ReferenceParseIssue(
              input: piece,
              message:
                  parsed.error ?? 'This reference could not be understood.',
            ),
          );
        }
      }
    }

    return ReferenceParseResult(references: references, issues: issues);
  }

  String _normalizeCompactVerseSyntax(String input) {
    final match = RegExp(r'^(.*?\D)\s+(\d+)\s+(\d+)(?:\s+(\d+))?$')
        .firstMatch(input);
    if (match == null || _matchBook(match.group(1)!.trim()) == null) {
      return input;
    }
    final book = match.group(1)!.trim();
    final chapter = match.group(2)!;
    final firstVerse = match.group(3)!;
    final lastVerse = match.group(4);
    return '$book $chapter:$firstVerse${lastVerse == null ? '' : '-$lastVerse'}';
  }

  _BookMatch? _matchBook(String input) {
    final lower = input.toLowerCase();
    for (final alias in _sortedAliases) {
      if (!lower.startsWith(alias)) {
        continue;
      }
      if (lower.length == alias.length) {
        return _BookMatch(book: _aliases[alias]!, aliasLength: alias.length);
      }
      final boundary = lower[alias.length];
      if (boundary == ' ' || RegExp(r'\d').hasMatch(boundary)) {
        return _BookMatch(book: _aliases[alias]!, aliasLength: alias.length);
      }
    }
    return null;
  }

  _ParsedReference _parseNumberPart(BibleBook book, String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) {
      return const _ParsedReference(error: 'Add a chapter number.');
    }

    final match = RegExp(
      r'^(\d+)(?::(\d+))?(?:\s*-\s*(\d+)(?::(\d+))?)?$',
    ).firstMatch(cleaned);
    if (match == null) {
      return const _ParsedReference(
        error: 'Use a format such as Matthew 5, John 1-3, or Romans 8:1-17.',
      );
    }

    final startChapter = int.parse(match.group(1)!);
    final startVerse = int.tryParse(match.group(2) ?? '');
    final rangeNumber = int.tryParse(match.group(3) ?? '');
    final finalVerse = int.tryParse(match.group(4) ?? '');

    if (startChapter < 1 || startChapter > book.chapterCount) {
      return _ParsedReference(
        error:
            '${book.name} has ${book.chapterCount} chapter${book.chapterCount == 1 ? '' : 's'}.',
      );
    }

    int? endChapter;
    int? endVerse;

    if (rangeNumber != null) {
      if (startVerse == null) {
        endChapter = rangeNumber;
      } else if (finalVerse == null) {
        endChapter = startChapter;
        endVerse = rangeNumber;
      } else {
        endChapter = rangeNumber;
        endVerse = finalVerse;
      }
    }

    if (endChapter != null &&
        (endChapter < startChapter || endChapter > book.chapterCount)) {
      return _ParsedReference(
        error:
            'The ending chapter must be between $startChapter and ${book.chapterCount}.',
      );
    }

    if (startVerse != null && startVerse < 1) {
      return const _ParsedReference(
        error: 'Verse numbers must be greater than zero.',
      );
    }
    if (endVerse != null && endVerse < 1) {
      return const _ParsedReference(
        error: 'Verse numbers must be greater than zero.',
      );
    }
    if (endChapter == startChapter &&
        startVerse != null &&
        endVerse != null &&
        endVerse < startVerse) {
      return const _ParsedReference(
        error: 'The ending verse cannot come before the starting verse.',
      );
    }

    return _ParsedReference(
      reference: ScriptureReference(
        book: book.name,
        startChapter: startChapter,
        startVerse: startVerse,
        endChapter: endChapter,
        endVerse: endVerse,
      ),
    );
  }
}

class _BookMatch {
  const _BookMatch({required this.book, required this.aliasLength});

  final BibleBook book;
  final int aliasLength;
}

class _ParsedReference {
  const _ParsedReference({this.reference, this.error});

  final ScriptureReference? reference;
  final String? error;
}
