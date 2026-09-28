import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract interface class WordRecoveryBackup {
  Future<void> writeSnapshot(String fingerprint, String exactPayload);

  Future<void> writeFailure(String fingerprint, String failureCode);
}

class FileWordRecoveryBackup implements WordRecoveryBackup {
  const FileWordRecoveryBackup();

  @override
  Future<void> writeSnapshot(String fingerprint, String exactPayload) async {
    final directory = await _directory();
    final destination = File(
      '${directory.path}${Platform.pathSeparator}word_$fingerprint.json',
    );
    if (await destination.exists()) return;
    await _writeAtomically(destination, exactPayload);
  }

  @override
  Future<void> writeFailure(String fingerprint, String failureCode) async {
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
    final support = await getApplicationSupportDirectory();
    final directory = Directory(
      '${support.path}${Platform.pathSeparator}migration-recovery',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<void> _writeAtomically(File destination, String content) async {
    final temporary = File('${destination.path}.tmp');
    await temporary.writeAsString(content, flush: true);
    if (await destination.exists()) {
      await temporary.delete();
      return;
    }
    await temporary.rename(destination.path);
  }
}
