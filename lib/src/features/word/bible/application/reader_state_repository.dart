import '../domain/reader_position.dart';

abstract interface class ReaderStateRepository {
  Future<ReaderPosition?> load();

  Future<void> save(ReaderPosition position);
}

class VolatileReaderStateRepository implements ReaderStateRepository {
  ReaderPosition? _position;

  @override
  Future<ReaderPosition?> load() async => _position;

  @override
  Future<void> save(ReaderPosition position) async {
    _position = position;
  }
}
