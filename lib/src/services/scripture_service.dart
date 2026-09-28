import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/word/bible/application/scripture_repository.dart';
import '../models/reading_plan.dart';
import 'bible_version_repository.dart';
import '../models/scripture_reference.dart';

export '../features/word/bible/application/scripture_repository.dart';

abstract class ScriptureService implements ScriptureRepository {}

class KjvScriptureService implements ScriptureService {
  Map<String, dynamic>? _data;

  Future<Map<String, dynamic>> _load() async {
    if (_data != null) {
      return _data!;
    }
    final installedFile = await BibleVersionRepository.kjvDataFile();
    final installedFileExists = await installedFile.exists();
    final raw = installedFileExists
        ? await installedFile.readAsString()
        : await rootBundle.loadString('assets/data/kjv.json');
    _data = jsonDecode(raw) as Map<String, dynamic>;
    return _data!;
  }

  @override
  Future<ScriptureTextResult> getPassage(ScriptureReference reference) async {
    final data = await _load();
    final metadata =
        data['metadata'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final isFullAsset = metadata['complete'] as bool? ?? false;
    final books = data['books'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final book = books[reference.book] as Map<String, dynamic>?;
    if (book == null) {
      throw ScriptureUnavailableException(
        '${reference.book} is not included in the demo KJV asset. Import the full KJV asset to read this passage offline.',
      );
    }

    final lines = <String>[];
    var hasMissingChapter = false;
    for (
      var chapter = reference.startChapter;
      chapter <= reference.resolvedEndChapter;
      chapter++
    ) {
      final verses = book['$chapter'] as Map<String, dynamic>?;
      if (verses == null) {
        hasMissingChapter = true;
        continue;
      }

      final available = verses.keys.map(int.parse).toList()..sort();
      final startVerse = chapter == reference.startChapter
          ? reference.startVerse
          : null;
      final endVerse = chapter == reference.resolvedEndChapter
          ? reference.endVerse
          : null;

      for (final verseNumber in available) {
        if (startVerse != null && verseNumber < startVerse) {
          continue;
        }
        if (endVerse != null && verseNumber > endVerse) {
          continue;
        }
        lines.add('$verseNumber ${verses['$verseNumber']}');
      }
    }

    if (lines.isEmpty) {
      throw ScriptureUnavailableException(
        '${reference.display} is not included in the demo KJV asset. Run the KJV importer to install the full Bible.',
      );
    }

    final incomplete =
        !isFullAsset &&
        (hasMissingChapter ||
            reference.startVerse == null ||
            reference.endVerse == null);

    return ScriptureTextResult(
      reference: '${reference.display} KJV',
      text: lines.join('\n\n'),
      notice: incomplete
          ? 'This starter includes only sample KJV verses. Import the full public-domain KJV asset for complete chapters.'
          : null,
    );
  }
}

class NltScriptureService implements ScriptureService {
  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      _supabaseUrl.isNotEmpty && _supabaseKey.isNotEmpty;

  @override
  Future<ScriptureTextResult> getPassage(ScriptureReference reference) async {
    if (!isConfigured) {
      throw const ScriptureUnavailableException(
        'NLT is not configured yet. Deploy the included Supabase Edge Function and launch the app with the Supabase dart-defines.',
      );
    }

    final response = await Supabase.instance.client.functions.invoke(
      'nlt-passage',
      body: <String, dynamic>{'reference': reference.display},
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ScriptureUnavailableException(
        'The NLT service returned an unexpected response.',
      );
    }
    if (data['error'] != null) {
      throw ScriptureUnavailableException(data['error'] as String);
    }

    final text = data['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw const ScriptureUnavailableException(
        'No NLT text was returned for this passage.',
      );
    }

    return ScriptureTextResult(
      reference: '${reference.display} NLT',
      text: text.trim(),
      notice:
          'New Living Translation text is provided under Tyndale’s applicable API and licensing terms.',
    );
  }
}

ScriptureService scriptureServiceFor(BibleTranslation translation) {
  return switch (translation) {
    BibleTranslation.kjv => KjvScriptureService(),
    BibleTranslation.nlt => NltScriptureService(),
  };
}
