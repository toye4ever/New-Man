import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bible_books.dart';
import '../features/word/translations/domain/translation_state.dart';
import '../models/reading_plan.dart';

class BibleVersionRepository {
  BibleVersionRepository({
    http.Client? httpClient,
    Future<File> Function()? kjvFileProvider,
    Future<Map<String, dynamic>> Function(List<int>)? archiveConverter,
  }) : _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null,
       _kjvFileProvider = kjvFileProvider ?? kjvDataFile,
       _archiveConverter = archiveConverter ?? convertKjvArchiveInBackground;

  static const String storageKey = 'scripture_planner.installed_versions.v2';
  static const _kjvDownloadUrl =
      'https://ebible.org/Scriptures/eng-kjv_vpl.zip';
  SharedPreferencesAsync? _preferences;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final Future<File> Function() _kjvFileProvider;
  final Future<Map<String, dynamic>> Function(List<int>) _archiveConverter;

  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  Future<Set<BibleTranslation>> loadInstalled() async {
    final stored = await _store.getStringList(storageKey);
    final result = <BibleTranslation>{
      ...?stored?.map((name) => BibleTranslation.values.byName(name)),
    };
    if (await isKjvInstalled()) {
      result.add(BibleTranslation.kjv);
    } else {
      result.remove(BibleTranslation.kjv);
    }
    return result;
  }

  Future<void> saveInstalled(Set<BibleTranslation> translations) async {
    await _store.setStringList(
      storageKey,
      translations.map((item) => item.name).toList(),
    );
  }

  Future<TranslationRepositoryState> loadTranslationState() async {
    final enabled = await loadInstalled();
    return TranslationRepositoryState(
      installations: <BibleTranslation, TranslationInstallationState>{
        if (enabled.contains(BibleTranslation.kjv))
          BibleTranslation.kjv: TranslationInstallationState(
            status: TranslationInstallationStatus.installed,
            updatedAt: DateTime.now().toUtc(),
          ),
      },
      onlineEnabled: <BibleTranslation>{
        if (enabled.contains(BibleTranslation.nlt)) BibleTranslation.nlt,
      },
    );
  }

  Future<void> install(
    BibleTranslation translation, {
    void Function(TranslationInstallationState state)? onStateChanged,
  }) async {
    if (!translation.definition.supportsOfflineDownload) {
      throw TranslationInstallationException(
        'not_downloadable',
        '${translation.shortLabel} is available online and cannot be downloaded by this app.',
      );
    }

    try {
      await _emitInstallationState(
        translation,
        const TranslationInstallationState(
          status: TranslationInstallationStatus.downloading,
        ),
        onStateChanged,
      );
      await _downloadAndInstallKjv(
        onProgress: (progress) => _emitInstallationState(
          translation,
          TranslationInstallationState(
            status: TranslationInstallationStatus.downloading,
            progress: progress,
            updatedAt: DateTime.now().toUtc(),
          ),
          onStateChanged,
        ),
        onProcessing: () => _emitInstallationState(
          translation,
          TranslationInstallationState(
            status: TranslationInstallationStatus.processing,
            updatedAt: DateTime.now().toUtc(),
          ),
          onStateChanged,
        ),
      );
      if (!await isKjvInstalled()) {
        throw const FormatException('Installed KJV content failed validation.');
      }
      await _emitInstallationState(
        translation,
        TranslationInstallationState(
          status: TranslationInstallationStatus.installed,
          updatedAt: DateTime.now().toUtc(),
        ),
        onStateChanged,
      );
    } catch (error) {
      final code = _installationFailureCode(error);
      await _emitInstallationState(
        translation,
        TranslationInstallationState(
          status: TranslationInstallationStatus.failed,
          failureCode: code,
          updatedAt: DateTime.now().toUtc(),
        ),
        onStateChanged,
      );
      throw TranslationInstallationException(
        code,
        _installationFailureMessage(code),
      );
    }
  }

  Future<void> saveInstallationState(
    BibleTranslation translation,
    TranslationInstallationState state,
  ) async {
    if (state.status != TranslationInstallationStatus.installed) return;
    final enabled = await loadInstalled();
    await saveInstalled(<BibleTranslation>{...enabled, translation});
  }

  Future<void> _emitInstallationState(
    BibleTranslation translation,
    TranslationInstallationState state,
    void Function(TranslationInstallationState state)? onStateChanged,
  ) async {
    await saveInstallationState(translation, state);
    onStateChanged?.call(state);
  }

  static Future<File> kjvDataFile() async {
    final directory = await getApplicationSupportDirectory();
    final versions = Directory(
      '${directory.path}${Platform.pathSeparator}bibles',
    );
    await versions.create(recursive: true);
    return File('${versions.path}${Platform.pathSeparator}kjv.json');
  }

  Future<bool> isKjvInstalled() async {
    final file = await _kjvFileProvider();
    if (!await file.exists()) return false;
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, dynamic> &&
          (decoded['metadata'] as Map<String, dynamic>?)?['complete'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _downloadAndInstallKjv({
    required Future<void> Function(double progress) onProgress,
    required Future<void> Function() onProcessing,
  }) async {
    final request = http.Request('GET', Uri.parse(_kjvDownloadUrl))
      ..headers['User-Agent'] = 'ScripturePlanner/0.2';
    final response = await _httpClient
        .send(request)
        .timeout(const Duration(minutes: 2));
    if (response.statusCode != 200) {
      throw HttpException(
        'KJV download failed with status ${response.statusCode}.',
        uri: Uri.parse(_kjvDownloadUrl),
      );
    }

    final bytes = BytesBuilder(copy: false);
    final totalBytes = response.contentLength;
    var receivedBytes = 0;
    var lastReportedPermille = -1;
    await for (final chunk in response.stream.timeout(
      const Duration(minutes: 2),
    )) {
      bytes.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes != null && totalBytes > 0) {
        final permille = (receivedBytes * 1000 / totalBytes).floor().clamp(
          0,
          1000,
        );
        if (permille == 1000 || permille - lastReportedPermille >= 25) {
          lastReportedPermille = permille;
          await onProgress(permille / 1000);
        }
      }
    }

    await onProcessing();
    final payload = await _archiveConverter(bytes.takeBytes());
    final destination = await _kjvFileProvider();
    final temporary = File('${destination.path}.download');
    await temporary.writeAsString(jsonEncode(payload), flush: true);
    if (await destination.exists()) await destination.delete();
    await temporary.rename(destination.path);
  }

  void dispose() {
    if (_ownsHttpClient) _httpClient.close();
  }
}

class TranslationInstallationException implements Exception {
  const TranslationInstallationException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

Future<Map<String, dynamic>> convertKjvArchiveInBackground(List<int> bytes) =>
    Isolate.run(() => convertKjvArchive(bytes));

String _installationFailureCode(Object error) => switch (error) {
  FormatException() => 'invalid_package',
  HttpException() => 'download_failed',
  SocketException() => 'network_unavailable',
  TimeoutException() => 'download_timeout',
  FileSystemException() => 'storage_failed',
  _ => 'installation_failed',
};

String _installationFailureMessage(String code) => switch (code) {
  'network_unavailable' || 'download_failed' || 'download_timeout' =>
    'The KJV download could not be completed. Check your connection and retry.',
  'invalid_package' =>
    'The KJV package could not be verified. Retry the download later.',
  'storage_failed' =>
    'The KJV package downloaded but could not be saved on this device. Retry after freeing storage.',
  _ => 'The KJV package could not be installed. Retry the download.',
};

/// Converts eBible's standardized VPL archive into the canonical local model.
/// Provider codes stay local to import; they do not change reference parsing.
Map<String, dynamic> convertKjvArchive(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final aliases = buildBibleAliasMap();
  final books = <String, Map<String, Map<String, String>>>{};
  var parsedCount = 0;

  for (final file in archive) {
    final lowerName = file.name.toLowerCase();
    if (!file.isFile ||
        (!lowerName.endsWith('.txt') && !lowerName.endsWith('.vpl')) ||
        lowerName.contains('copyright') ||
        lowerName.contains('readme')) {
      continue;
    }

    final content = file.readBytes();
    if (content == null) continue;
    final text = utf8.decode(content, allowMalformed: true);
    for (final rawLine in const LineSplitter().convert(text)) {
      final line = rawLine.trim();
      final match = RegExp(r'^(\S+)\s+(\d+):(\d+)\s+(.+)$').firstMatch(line);
      if (match == null) continue;
      final providerCode = match.group(1)!;
      final book =
          _eBibleVplBooks[providerCode.toUpperCase()] ??
          aliases[providerCode.toLowerCase()];
      if (book == null) continue;
      final chapter = match.group(2)!;
      final verse = match.group(3)!;
      final verseText = match.group(4)!.trim();
      books
              .putIfAbsent(book.name, () => <String, Map<String, String>>{})
              .putIfAbsent(chapter, () => <String, String>{})[verse] =
          verseText;
      parsedCount++;
    }
  }

  if (parsedCount < 30000) {
    throw const FormatException(
      'The downloaded KJV package used an unexpected format.',
    );
  }

  return <String, dynamic>{
    'metadata': <String, dynamic>{
      'translation': 'King James Version',
      'source': 'eBible.org standardized 1769 KJV',
      'complete': true,
      'verseCount': parsedCount,
    },
    'books': books,
  };
}

const Map<String, String> eBibleVplBookNames = <String, String>{
  'GEN': 'Genesis',
  'EXO': 'Exodus',
  'LEV': 'Leviticus',
  'NUM': 'Numbers',
  'DEU': 'Deuteronomy',
  'JOS': 'Joshua',
  'JDG': 'Judges',
  'RUT': 'Ruth',
  '1SA': '1 Samuel',
  '2SA': '2 Samuel',
  '1KI': '1 Kings',
  '2KI': '2 Kings',
  '1CH': '1 Chronicles',
  '2CH': '2 Chronicles',
  'EZR': 'Ezra',
  'NEH': 'Nehemiah',
  'EST': 'Esther',
  'JOB': 'Job',
  'PSA': 'Psalms',
  'PRO': 'Proverbs',
  'ECC': 'Ecclesiastes',
  'SNG': 'Song of Solomon',
  'ISA': 'Isaiah',
  'JER': 'Jeremiah',
  'LAM': 'Lamentations',
  'EZK': 'Ezekiel',
  'DAN': 'Daniel',
  'HOS': 'Hosea',
  'JOL': 'Joel',
  'AMO': 'Amos',
  'OBA': 'Obadiah',
  'JON': 'Jonah',
  'MIC': 'Micah',
  'NAM': 'Nahum',
  'HAB': 'Habakkuk',
  'ZEP': 'Zephaniah',
  'HAG': 'Haggai',
  'ZEC': 'Zechariah',
  'MAL': 'Malachi',
  'MAT': 'Matthew',
  'MRK': 'Mark',
  'LUK': 'Luke',
  'JHN': 'John',
  'ACT': 'Acts',
  'ROM': 'Romans',
  '1CO': '1 Corinthians',
  '2CO': '2 Corinthians',
  'GAL': 'Galatians',
  'EPH': 'Ephesians',
  'PHP': 'Philippians',
  'COL': 'Colossians',
  '1TH': '1 Thessalonians',
  '2TH': '2 Thessalonians',
  '1TI': '1 Timothy',
  '2TI': '2 Timothy',
  'TIT': 'Titus',
  'PHM': 'Philemon',
  'HEB': 'Hebrews',
  'JAS': 'James',
  '1PE': '1 Peter',
  '2PE': '2 Peter',
  '1JN': '1 John',
  '2JN': '2 John',
  '3JN': '3 John',
  'JUD': 'Jude',
  'REV': 'Revelation',
};

final Map<String, BibleBook> _eBibleVplBooks = <String, BibleBook>{
  for (final entry in eBibleVplBookNames.entries)
    entry.key: buildBibleAliasMap()[entry.value.toLowerCase()]!,
  'SOL': buildBibleAliasMap()['song of solomon']!,
  'JOE': buildBibleAliasMap()['joel']!,
  'MAR': buildBibleAliasMap()['mark']!,
  'JOH': buildBibleAliasMap()['john']!,
  'PHI': buildBibleAliasMap()['philippians']!,
  '1JO': buildBibleAliasMap()['1 john']!,
  '2JO': buildBibleAliasMap()['2 john']!,
  '3JO': buildBibleAliasMap()['3 john']!,
};
