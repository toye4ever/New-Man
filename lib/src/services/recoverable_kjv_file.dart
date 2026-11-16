import 'dart:convert';
import 'dart:io';

/// One-isolate writer coordination; unique staging and retained read fallback.
/// This does not claim filesystem transactions or power-loss durability.
class RecoverableKjvFile {
  RecoverableKjvFile(
    this.destination, {
    Future<void> Function(File, String)? write,
    Future<void> Function(File, File)? promote,
  }) : _write =
           write ??
           ((file, text) async {
             await file.writeAsString(text, flush: true);
           }),
       _promote =
           promote ??
           ((source, target) async {
             await source.rename(target.path);
           });

  final File destination;
  final Future<void> Function(File, String) _write;
  final Future<void> Function(File, File) _promote;
  static final _writers = <String>{};
  File get previous => File('${destination.path}.previous');

  static bool _readable(String text) {
    try {
      final value = jsonDecode(text);
      return value is Map<String, dynamic> &&
          value['metadata'] is Map &&
          value['metadata']['complete'] == true &&
          value['books'] is Map;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _read(File file, {bool strictIO = false}) async {
    if (strictIO && !await file.exists()) return null;
    try {
      final text = await file.readAsString();
      return _readable(text) ? text : null;
    } on FileSystemException {
      if (strictIO) rethrow;
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<String?> read() async =>
      await _read(destination) ?? await _read(previous);

  Future<void> replace(String encoded) async {
    if (!_readable(encoded)) {
      throw const FormatException('Invalid staged KJV model.');
    }
    final key = destination.absolute.path;
    if (!_writers.add(key)) {
      throw FileSystemException(
        'KJV replacement already in progress',
        destination.path,
      );
    }
    Directory? staging;
    try {
      await destination.parent.create(recursive: true);
      staging = await destination.parent.createTemp('kjv-install-');
      final staged = File('${staging.path}${Platform.pathSeparator}new.json');
      await _write(staged, encoded);
      if (await staged.readAsString() != encoded) {
        throw const FileSystemException('Staged KJV write verification failed');
      }
      final old = await _read(destination, strictIO: true);
      if (old != null) {
        final backup = File(
          '${staging.path}${Platform.pathSeparator}previous.json',
        );
        await _write(backup, old);
        if (await backup.readAsString() != old) {
          throw const FileSystemException(
            'Previous KJV copy verification failed',
          );
        }
        // Primary remains readable while replacing the fallback. Only then may
        // the platform's rename replace/remove the primary destination.
        await _promote(backup, previous);
        if (await _read(previous) != old) {
          throw const FileSystemException(
            'Previous KJV promotion verification failed',
          );
        }
      }
      // If primary was already missing/corrupt, retain its existing fallback.
      await _promote(staged, destination);
      if (await _read(destination) != encoded) {
        throw const FileSystemException('KJV promotion verification failed');
      }
    } finally {
      if (staging != null) {
        try {
          await staging.delete(recursive: true);
        } on FileSystemException {
          /* Orphan stage is never read. */
        }
      }
      _writers.remove(key);
    }
  }
}
