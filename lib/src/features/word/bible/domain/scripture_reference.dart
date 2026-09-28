class ScriptureReference {
  const ScriptureReference({
    required this.book,
    required this.startChapter,
    this.startVerse,
    this.endChapter,
    this.endVerse,
  });

  final String book;
  final int startChapter;
  final int? startVerse;
  final int? endChapter;
  final int? endVerse;

  int get resolvedEndChapter => endChapter ?? startChapter;

  String get display {
    final buffer = StringBuffer('$book $startChapter');
    if (startVerse != null) {
      buffer.write(':$startVerse');
    }

    final hasRange = endChapter != null || endVerse != null;
    if (hasRange) {
      buffer.write('-');
      if (resolvedEndChapter != startChapter) {
        buffer.write(resolvedEndChapter);
        if (endVerse != null) {
          buffer.write(':$endVerse');
        }
      } else if (endVerse != null) {
        buffer.write(endVerse);
      } else {
        buffer.write(resolvedEndChapter);
      }
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'book': book,
    'startChapter': startChapter,
    'startVerse': startVerse,
    'endChapter': endChapter,
    'endVerse': endVerse,
  };

  factory ScriptureReference.fromJson(Map<String, dynamic> json) {
    return ScriptureReference(
      book: json['book'] as String,
      startChapter: json['startChapter'] as int,
      startVerse: json['startVerse'] as int?,
      endChapter: json['endChapter'] as int?,
      endVerse: json['endVerse'] as int?,
    );
  }

  @override
  String toString() => display;
}
