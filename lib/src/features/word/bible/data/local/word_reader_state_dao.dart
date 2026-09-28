import '../../../../../core/database/app_database.dart';
import '../../domain/reader_position.dart';
import '../../../translations/domain/bible_translation.dart';

class WordReaderStateDao {
  WordReaderStateDao(this.database);

  static const stateId = 'latest';

  final AppDatabase database;

  Future<ReaderPosition?> load() async {
    final row = await (database.select(
      database.wordReaderStates,
    )..where((table) => table.id.equals(stateId))).getSingleOrNull();
    if (row == null) return null;
    return ReaderPosition(
      book: row.book,
      chapter: row.chapter,
      translation: BibleTranslation.values.byName(row.translationId),
      updatedAt: DateTime.fromMicrosecondsSinceEpoch(
        row.updatedAtUtcMicros,
        isUtc: true,
      ),
    );
  }

  Future<void> save(ReaderPosition position) async {
    await database
        .into(database.wordReaderStates)
        .insertOnConflictUpdate(
          WordReaderStatesCompanion.insert(
            id: stateId,
            book: position.book,
            chapter: position.chapter,
            translationId: position.translation.name,
            updatedAtUtcMicros: position.updatedAt
                .toUtc()
                .microsecondsSinceEpoch,
          ),
        );
  }
}
