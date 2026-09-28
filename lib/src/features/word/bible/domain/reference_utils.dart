import 'scripture_reference.dart';

class ReferenceUtils {
  const ReferenceUtils._();

  static List<ScriptureReference> chapterOnly(
    Iterable<ScriptureReference> references,
  ) {
    final result = <ScriptureReference>[];
    final seen = <String>{};

    for (final reference in references) {
      for (
        var chapter = reference.startChapter;
        chapter <= reference.resolvedEndChapter;
        chapter++
      ) {
        final item = ScriptureReference(
          book: reference.book,
          startChapter: chapter,
        );
        if (seen.add(key(item))) {
          result.add(item);
        }
      }
    }
    return result;
  }

  static String formatForEditor(Iterable<ScriptureReference> references) {
    final items = references.toList();
    if (items.isEmpty) return '';

    final lines = <String>[];
    String? runBook;
    int? runStart;
    int? runEnd;

    void flushRun() {
      if (runBook == null || runStart == null || runEnd == null) return;
      lines.add(
        runStart == runEnd
            ? '$runBook $runStart'
            : '$runBook $runStart-$runEnd',
      );
      runBook = null;
      runStart = null;
      runEnd = null;
    }

    for (final reference in items) {
      final isWholeChapter =
          reference.startVerse == null && reference.endVerse == null;
      if (!isWholeChapter) {
        flushRun();
        lines.add(reference.display);
        continue;
      }

      for (
        var chapter = reference.startChapter;
        chapter <= reference.resolvedEndChapter;
        chapter++
      ) {
        if (runBook == reference.book &&
            runEnd != null &&
            chapter == runEnd! + 1) {
          runEnd = chapter;
        } else {
          flushRun();
          runBook = reference.book;
          runStart = chapter;
          runEnd = chapter;
        }
      }
    }
    flushRun();
    return lines.join('\n');
  }

  static List<ScriptureReference> deduplicate(
    Iterable<ScriptureReference> references,
  ) {
    final result = <ScriptureReference>[];
    final seen = <String>{};
    for (final reference in references) {
      if (seen.add(key(reference))) result.add(reference);
    }
    return result;
  }

  static String key(ScriptureReference reference) =>
      '${reference.book}|${reference.startChapter}|${reference.startVerse ?? ''}|'
      '${reference.endChapter ?? ''}|${reference.endVerse ?? ''}';
}
