import '../application/reader_state_repository.dart';
import '../domain/reader_position.dart';
import 'local/word_reader_state_dao.dart';

class DriftReaderStateRepository implements ReaderStateRepository {
  const DriftReaderStateRepository(this.dao);

  final WordReaderStateDao dao;

  @override
  Future<ReaderPosition?> load() => dao.load();

  @override
  Future<void> save(ReaderPosition position) => dao.save(position);
}
