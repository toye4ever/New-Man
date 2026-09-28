import '../../translations/domain/bible_translation.dart';

class ReaderPosition {
  const ReaderPosition({
    required this.book,
    required this.chapter,
    required this.translation,
    required this.updatedAt,
  });

  final String book;
  final int chapter;
  final BibleTranslation translation;
  final DateTime updatedAt;

  ReaderPosition copyWith({
    String? book,
    int? chapter,
    BibleTranslation? translation,
    DateTime? updatedAt,
  }) => ReaderPosition(
    book: book ?? this.book,
    chapter: chapter ?? this.chapter,
    translation: translation ?? this.translation,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
