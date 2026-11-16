import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/migration/word_recovery_backup.dart';

void main() {
  late Directory support;
  late FileWordRecoveryBackup backup;
  const payload =
      '{"planPayload":"synthetic reading plan é\\n","translationPayload":["kjv"]}';
  final fingerprint = sha256.convert(utf8.encode(payload)).toString();
  File snapshot() =>
      File('${support.path}/migration-recovery/word_$fingerprint.json');
  setUp(() async {
    support = await Directory.systemTemp.createTemp('newman-recovery-');
    backup = FileWordRecoveryBackup(
      supportDirectoryProvider: () async => support,
    );
  });
  tearDown(() => support.delete(recursive: true));

  test(
    'writes exact UTF-8 payload and verifies retry without replacing it',
    () async {
      await backup.writeSnapshot(fingerprint, payload);
      expect(await snapshot().readAsBytes(), utf8.encode(payload));
      final modified = await snapshot().lastModified();
      await backup.writeSnapshot(fingerprint, payload);
      expect(await snapshot().lastModified(), modified);
      expect(await snapshot().parent.list().length, 1);
    },
  );

  test(
    'corrupt existing snapshot stops instead of trusting or replacing it',
    () async {
      await snapshot().parent.create(recursive: true);
      await snapshot().writeAsString('{"truncated":');
      await expectLater(
        backup.writeSnapshot(fingerprint, payload),
        throwsA(isA<FileSystemException>()),
      );
      expect(await snapshot().readAsString(), '{"truncated":');
      expect(await snapshot().parent.list().length, 1);
    },
  );

  test(
    'byte differences such as an extra UTF-8 BOM are not silently accepted',
    () async {
      await snapshot().parent.create(recursive: true);
      await snapshot().writeAsBytes([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(payload),
      ]);
      await expectLater(
        backup.writeSnapshot(fingerprint, payload),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test(
    'concurrent attempts preserve exact snapshot and clean their staging directories',
    () async {
      await Future.wait(
        List.generate(8, (_) => backup.writeSnapshot(fingerprint, payload)),
      );
      expect(await snapshot().readAsBytes(), utf8.encode(payload));
      expect(await snapshot().parent.list().length, 1);
    },
  );

  test(
    'mismatched and path-like fingerprints cannot create recovery files',
    () async {
      await expectLater(
        backup.writeSnapshot('../escape', payload),
        throwsArgumentError,
      );
      await expectLater(
        backup.writeSnapshot('0' * 64, payload),
        throwsArgumentError,
      );
      expect(await support.list().length, 0);
    },
  );

  test('failure report preserves the first diagnostic', () async {
    await backup.writeFailure(fingerprint, 'legacy_format');
    await backup.writeFailure(fingerprint, 'another_failure');
    final file = File(
      '${support.path}/migration-recovery/word_failure_$fingerprint.json',
    );
    expect(jsonDecode(await file.readAsString()), {
      'sourceFingerprint': fingerprint,
      'failureCode': 'legacy_format',
    });
    expect(await file.parent.list().length, 1);
  });
}
