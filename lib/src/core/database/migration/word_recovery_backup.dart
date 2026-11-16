import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

abstract interface class WordRecoveryBackup {
  Future<void> writeSnapshot(String fingerprint, String exactPayload);

  Future<void> writeFailure(String fingerprint, String failureCode);
}

class FileWordRecoveryBackup implements WordRecoveryBackup {
  const FileWordRecoveryBackup({this.supportDirectoryProvider});

  final Future<Directory> Function()? supportDirectoryProvider;

  @override
  Future<void> writeSnapshot(String fingerprint, String exactPayload) async {
    if (sha256.convert(utf8.encode(exactPayload)).toString() != fingerprint) {
      throw ArgumentError('Recovery fingerprint does not match the snapshot.');
    }
    final directory = await _directory();
    final destination = File(
      '${directory.path}${Platform.pathSeparator}word_$fingerprint.json',
    );
    await _writeAtomically(destination, exactPayload, verifyExisting: true);
    await _verifySnapshot(destination, exactPayload);
  }

  @override
  Future<void> writeFailure(String fingerprint, String failureCode) async {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(fingerprint)) {
      throw ArgumentError('Invalid recovery fingerprint.');
    }
    final directory = await _directory();
    final destination = File(
      '${directory.path}${Platform.pathSeparator}word_failure_$fingerprint.json',
    );
    await _writeAtomically(
      destination,
      jsonEncode({
        'sourceFingerprint': fingerprint,
        'failureCode': failureCode,
      }),
    );
  }

  Future<Directory> _directory() async {
    final support =
        await (supportDirectoryProvider ?? getApplicationSupportDirectory)();
    final directory = Directory(
      '${support.path}${Platform.pathSeparator}migration-recovery',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<void> _verifySnapshot(File destination, String expected) async {
    final actualBytes = await destination.readAsBytes();
    final expectedBytes = utf8.encode(expected);
    if (actualBytes.length != expectedBytes.length ||
        actualBytes.indexed.any(
          (entry) => entry.$2 != expectedBytes[entry.$1],
        )) {
      throw FileSystemException(
        'The existing recovery snapshot does not match the source. Migration stopped.',
        destination.path,
      );
    }
  }

  Future<void> _writeAtomically(
    File destination,
    String content, {
    bool verifyExisting = false,
  }) async {
    if (await destination.exists()) {
      if (verifyExisting) await _verifySnapshot(destination, content);
      return;
    }
    // Separate staging directories prevent concurrent attempts from sharing
    // or deleting each other's temporary payload. Rename stays on one volume.
    final staging = await destination.parent.createTemp('.word-backup-');
    try {
      final temporary = File('${staging.path}${Platform.pathSeparator}payload');
      await temporary.writeAsString(content, flush: true);
      if (verifyExisting) await _verifySnapshot(temporary, content);
      if (await destination.exists()) {
        if (verifyExisting) await _verifySnapshot(destination, content);
        return;
      }
      await temporary.rename(destination.path);
    } finally {
      await staging.delete(recursive: true);
    }
  }
}
