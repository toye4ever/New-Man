import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/services/scripture_service.dart';
import 'package:scripture_planner/src/models/scripture_reference.dart';
import 'package:scripture_planner/src/services/recoverable_kjv_file.dart';

String payload(String text) => jsonEncode({
  'metadata': {'complete': true},
  'books': {'Synthetic': text},
});
void main() {
  late Directory directory;
  late File destination;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('synthetic-kjv-');
    destination = File('${directory.path}/kjv.json');
    await destination.writeAsString(payload('old'));
  });
  tearDown(() async => directory.delete(recursive: true));

  test(
    'primary read I/O failure aborts before losing an unretained edition',
    () async {
      final store = RecoverableKjvFile(_UnreadableFile(destination));
      await expectLater(
        store.replace(payload('new')),
        throwsA(isA<FileSystemException>()),
      );
      expect(await destination.readAsString(), payload('old'));
    },
  );

  test(
    'fresh reader recovers after interrupted promotion and invalid UTF-8',
    () async {
      final old = jsonEncode({
        'metadata': {'complete': true},
        'books': {
          'Matthew': {
            '1': {'1': 'Synthetic recovery verse'},
          },
        },
      });
      await destination.writeAsString(old);
      final store = RecoverableKjvFile(
        destination,
        promote: (source, target) async {
          if (target.path == destination.path) {
            await target.delete();
            throw const FileSystemException('injected interruption');
          }
          await source.rename(target.path);
        },
      );
      await expectLater(
        store.replace(payload('new')),
        throwsA(isA<FileSystemException>()),
      );
      final reader = KjvScriptureService(
        kjvFileProvider: () async => destination,
      );
      final passage = await reader.getPassage(
        const ScriptureReference(
          book: 'Matthew',
          startChapter: 1,
          startVerse: 1,
        ),
      );
      expect(passage.text, contains('Synthetic recovery verse'));
      await destination.writeAsBytes([0xff]);
      expect(await RecoverableKjvFile(destination).read(), old);
    },
  );

  test(
    'failed staged write preserves prior readable edition on reopen',
    () async {
      final store = RecoverableKjvFile(
        destination,
        write: (_, _) async => throw const FileSystemException('injected'),
      );
      await expectLater(
        store.replace(payload('new')),
        throwsA(isA<FileSystemException>()),
      );
      expect(await RecoverableKjvFile(destination).read(), payload('old'));
    },
  );
  test(
    'invalid payload and truncated staged write never replace old edition',
    () async {
      await expectLater(
        RecoverableKjvFile(destination).replace('{}'),
        throwsFormatException,
      );
      final store = RecoverableKjvFile(
        destination,
        write: (file, _) async {
          await file.writeAsString('{}');
        },
      );
      await expectLater(
        store.replace(payload('new')),
        throwsA(isA<FileSystemException>()),
      );
      expect(await RecoverableKjvFile(destination).read(), payload('old'));
    },
  );
  test('failed backup promotion leaves primary untouched', () async {
    final store = RecoverableKjvFile(
      destination,
      promote: (_, _) async => throw const FileSystemException('injected'),
    );
    await expectLater(
      store.replace(payload('new')),
      throwsA(isA<FileSystemException>()),
    );
    expect(await destination.readAsString(), payload('old'));
  });
  test(
    'Windows-like removal followed by failed promotion recovers on reopen',
    () async {
      final store = RecoverableKjvFile(
        destination,
        promote: (source, target) async {
          if (target.path == destination.path) {
            await target.delete();
            throw const FileSystemException(
              'injected after destination removal',
            );
          }
          await source.rename(target.path);
        },
      );
      await expectLater(
        store.replace(payload('new')),
        throwsA(isA<FileSystemException>()),
      );
      expect(await destination.exists(), isFalse);
      expect(await RecoverableKjvFile(destination).read(), payload('old'));
      await RecoverableKjvFile(destination).replace(payload('retry'));
      expect(await RecoverableKjvFile(destination).read(), payload('retry'));
    },
  );
  test(
    'corrupt primary never overwrites good fallback during failed retry',
    () async {
      await RecoverableKjvFile(destination).replace(payload('new'));
      await destination.writeAsString('{broken');
      final store = RecoverableKjvFile(
        destination,
        promote: (_, _) async => throw const FileSystemException('injected'),
      );
      await expectLater(
        store.replace(payload('retry')),
        throwsA(isA<FileSystemException>()),
      );
      expect(await RecoverableKjvFile(destination).read(), payload('old'));
    },
  );
  test(
    'concurrent repositories cannot share stage or promote concurrently',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final first = RecoverableKjvFile(
        destination,
        write: (file, text) async {
          if (!entered.isCompleted) {
            entered.complete();
            await release.future;
          }
          await file.writeAsString(text, flush: true);
        },
      );
      final replacing = first.replace(payload('new'));
      await entered.future;
      await expectLater(
        RecoverableKjvFile(destination).replace(payload('other')),
        throwsA(isA<FileSystemException>()),
      );
      release.complete();
      await replacing;
      expect(await RecoverableKjvFile(destination).read(), payload('new'));
      expect((await directory.list().toList()).whereType<Directory>(), isEmpty);
    },
  );
}

class _UnreadableFile implements File {
  _UnreadableFile(this.file);
  final File file;
  @override
  String get path => file.path;
  @override
  File get absolute => file.absolute;
  @override
  Directory get parent => file.parent;
  @override
  Future<bool> exists() => file.exists();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async =>
      throw const FileSystemException('injected primary read failure');
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
