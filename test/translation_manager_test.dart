import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:scripture_planner/src/controllers/app_controller.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/word/plans/application/plan_repository.dart';
import 'package:scripture_planner/src/features/word/plans/domain/reading_plan.dart';
import 'package:scripture_planner/src/features/word/translations/data/drift_bible_version_repository.dart';
import 'package:scripture_planner/src/features/word/translations/data/local/word_translation_state_dao.dart';
import 'package:scripture_planner/src/features/word/translations/domain/bible_translation.dart';
import 'package:scripture_planner/src/features/word/translations/domain/translation_state.dart';
import 'package:scripture_planner/src/features/word/translations/presentation/translation_manager_screen.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';

void main() {
  test('catalog has stable unique IDs and truthful capabilities', () {
    expect(translationCatalog, hasLength(2));
    expect(
      translationCatalog.map((entry) => entry.translation.name).toSet(),
      hasLength(translationCatalog.length),
    );
    expect(BibleTranslation.kjv.definition.supportsOfflineDownload, isTrue);
    expect(BibleTranslation.kjv.definition.supportsOnline, isFalse);
    expect(BibleTranslation.nlt.definition.supportsOnline, isTrue);
    expect(BibleTranslation.nlt.definition.supportsOfflineDownload, isFalse);
  });

  test(
    'KJV install persists real lifecycle and restores after restart',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final directory = await Directory.systemTemp.createTemp(
        'new_man_translation_test_',
      );
      final file = File('${directory.path}${Platform.pathSeparator}kjv.json');
      final repository = DriftBibleVersionRepository(
        WordTranslationStateDao(database),
        httpClient: _SequenceClient(<int>[200]),
        kjvFileProvider: () async => file,
        archiveConverter: (_) async => <String, dynamic>{
          'metadata': <String, dynamic>{'complete': true},
          'books': <String, dynamic>{},
        },
      );
      final observed = <TranslationInstallationState>[];

      await repository.install(
        BibleTranslation.kjv,
        onStateChanged: observed.add,
      );

      expect(
        observed.map((state) => state.status),
        containsAllInOrder(<TranslationInstallationStatus>[
          TranslationInstallationStatus.downloading,
          TranslationInstallationStatus.processing,
          TranslationInstallationStatus.installed,
        ]),
      );
      expect(observed.where((state) => state.progress != null), isNotEmpty);
      final restored = await DriftBibleVersionRepository(
        WordTranslationStateDao(database),
        kjvFileProvider: () async => file,
      ).loadTranslationState();
      expect(
        restored.installations[BibleTranslation.kjv]?.status,
        TranslationInstallationStatus.installed,
      );

      repository.dispose();
      await database.close();
      await directory.delete(recursive: true);
    },
  );

  test('eBible VPL converter maps provider aliases and ignores non-canonical records', () {
    final converted = convertKjvArchive(_completeVplZip());
    final books = converted['books'] as Map<String, dynamic>;
    expect(eBibleVplBookNames, hasLength(66));
    expect(books, hasLength(66));
    expect((converted['metadata'] as Map<String, dynamic>)['verseCount'], 31102);
    expect(books.keys.first, 'Genesis');
    expect(
      books.keys,
      containsAll(<String>[
        'Deuteronomy',
        'Ruth',
        'Song of Solomon',
        'Ezekiel',
        'Joel',
        'Amos',
        'Obadiah',
        'Nahum',
        'Matthew',
        'Revelation',
      ]),
    );
    expect((converted['metadata'] as Map<String, dynamic>)['complete'], isTrue);
    expect(books['Song of Solomon'], isNotEmpty);
    expect(books['Joel'], isNotEmpty);
    expect(books['Mark'], isNotEmpty);
    expect(books['John'], isNotEmpty);
    expect(books['Philippians'], isNotEmpty);
    expect(books['1 John'], isNotEmpty);
    expect(books['2 John'], isNotEmpty);
    expect(books['3 John'], isNotEmpty);
    expect(books.containsKey('Tobit'), isFalse);
  });

  test(
    'real converter installs a complete deterministic VPL package',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final directory = await Directory.systemTemp.createTemp(
        'new_man_vpl_install_',
      );
      final file = File('${directory.path}${Platform.pathSeparator}kjv.json');
      final repository = DriftBibleVersionRepository(
        WordTranslationStateDao(database),
        httpClient: _BytesClient(<List<int>>[_completeVplZip()]),
        kjvFileProvider: () async => file,
      );

      await repository.install(BibleTranslation.kjv);

      expect(await repository.isKjvInstalled(), isTrue);
      expect(
        (jsonDecode(await file.readAsString())
            as Map<String, dynamic>)['metadata']['complete'],
        isTrue,
      );
      expect(
        (await repository.loadTranslationState())
            .installations[BibleTranslation.kjv]
            ?.isInstalled,
        isTrue,
      );
      repository.dispose();
      await database.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'invalid KJV package remains retryable with truthful failure wording',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final directory = await Directory.systemTemp.createTemp(
        'new_man_vpl_invalid_',
      );
      final file = File('${directory.path}${Platform.pathSeparator}kjv.json');
      final repository = DriftBibleVersionRepository(
        WordTranslationStateDao(database),
        httpClient: _BytesClient(<List<int>>[_vplZip('GEN 1:1 Too small')]),
        kjvFileProvider: () async => file,
      );

      await expectLater(
        repository.install(BibleTranslation.kjv),
        throwsA(
          isA<TranslationInstallationException>()
              .having((error) => error.code, 'code', 'invalid_package')
              .having(
                (error) => error.message,
                'message',
                contains('could not be verified'),
              ),
        ),
      );
      final state = (await repository.loadTranslationState())
          .installations[BibleTranslation.kjv];
      expect(state?.status, TranslationInstallationStatus.failed);
      final controller = AppController(
        repository: _EmptyPlanRepository(),
        versionRepository: repository,
      );
      await controller.load();
      expect(
        controller.translationAvailability(BibleTranslation.kjv).kind,
        TranslationAvailabilityKind.failed,
      );
      expect(
        controller.translationAvailability(BibleTranslation.kjv).canInstall,
        isTrue,
      );
      repository.dispose();
      await database.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'bundled KJV sample never makes canonical availability installed',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final directory = await Directory.systemTemp.createTemp(
        'new_man_sample_policy_',
      );
      final repository = DriftBibleVersionRepository(
        WordTranslationStateDao(database),
        kjvFileProvider: () async =>
            File('${directory.path}${Platform.pathSeparator}kjv.json'),
      );
      final controller = AppController(
        repository: _EmptyPlanRepository(),
        versionRepository: repository,
      );

      await controller.load();

      expect(
        controller.translationAvailability(BibleTranslation.kjv).kind,
        TranslationAvailabilityKind.downloadAvailable,
      );
      expect(controller.isTranslationUsable(BibleTranslation.kjv), isFalse);
      await database.close();
      await directory.delete(recursive: true);
    },
  );

  test('failed KJV install is persisted and a retry can succeed', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final directory = await Directory.systemTemp.createTemp(
      'new_man_translation_retry_',
    );
    final file = File('${directory.path}${Platform.pathSeparator}kjv.json');
    final repository = DriftBibleVersionRepository(
      WordTranslationStateDao(database),
      httpClient: _SequenceClient(<int>[503, 200]),
      kjvFileProvider: () async => file,
      archiveConverter: (_) async => <String, dynamic>{
        'metadata': <String, dynamic>{'complete': true},
        'books': <String, dynamic>{},
      },
    );

    await expectLater(
      repository.install(BibleTranslation.kjv),
      throwsA(isA<Exception>()),
    );
    var restored = await repository.loadTranslationState();
    expect(
      restored.installations[BibleTranslation.kjv]?.status,
      TranslationInstallationStatus.failed,
    );
    expect(
      restored.installations[BibleTranslation.kjv]?.failureCode,
      'download_failed',
    );

    await repository.install(BibleTranslation.kjv);
    restored = await repository.loadTranslationState();
    expect(
      restored.installations[BibleTranslation.kjv]?.status,
      TranslationInstallationStatus.installed,
    );

    repository.dispose();
    await database.close();
    await directory.delete(recursive: true);
  });

  testWidgets('manager shows KJV download and NLT setup without fake action', (
    tester,
  ) async {
    final controller = AppController(
      repository: _EmptyPlanRepository(),
      versionRepository: _EmptyVersionRepository(),
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(home: TranslationManagerScreen(controller: controller)),
    );

    expect(find.text('AVAILABLE TO DOWNLOAD'), findsOneWidget);
    expect(find.text('SETUP REQUIRED'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Download'), findsOneWidget);
    expect(find.textContaining('New Living Translation'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });
}

class _SequenceClient extends http.BaseClient {
  _SequenceClient(this.statuses);

  final List<int> statuses;
  var _index = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final status = statuses[_index++];
    final bytes = status == 200 ? <int>[1, 2, 3, 4, 5, 6] : <int>[];
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[
        bytes.take(3).toList(),
        bytes.skip(3).toList(),
      ]),
      status,
      contentLength: bytes.length,
      request: request,
    );
  }
}

class _BytesClient extends http.BaseClient {
  _BytesClient(this.responses);
  final List<List<int>> responses;
  var _index = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = responses[_index++];
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[bytes]),
      200,
      contentLength: bytes.length,
      request: request,
    );
  }
}

List<int> _completeVplZip() {
  const verseCounts = <int>[
    1533, 1213, 859, 1288, 959, 658, 618, 85, 810, 695, 816, 719,
    942, 822, 280, 406, 167, 1070, 2461, 915, 222, 117, 1292, 1364,
    154, 1273, 357, 197, 73, 146, 21, 48, 105, 47, 56, 53, 38, 211,
    55, 1071, 678, 1151, 879, 1007, 433, 437, 257, 149, 155, 104,
    95, 89, 47, 113, 83, 46, 25, 303, 108, 105, 61, 105, 13, 14, 25,
    404,
  ];
  const alternateCodes = <String, String>{
    'SNG': 'SOL', 'JOL': 'JOE', 'MRK': 'MAR', 'JHN': 'JOH',
    'PHP': 'PHI', '1JN': '1JO', '2JN': '2JO', '3JN': '3JO',
  };
  final lines = <String>[];
  var bookIndex = 0;
  for (final entry in eBibleVplBookNames.entries) {
    final code = alternateCodes[entry.key] ?? entry.key;
    for (var verse = 1; verse <= verseCounts[bookIndex]; verse++) {
      lines.add('$code 1:$verse generated verse $verse');
    }
    bookIndex++;
  }
  lines.addAll(<String>[
    'TOB 1:1 ignored deuterocanonical verse',
    'WIS 1:1 ignored deuterocanonical verse',
    '3MA 1:1 ignored non-canonical verse',
  ]);
  return _vplZip(lines.join('\n'));
}

List<int> _vplZip(String text) {
  final bytes = utf8.encode(text);
  final archive = Archive()
    ..addFile(ArchiveFile('eng-kjv_vpl.txt', bytes.length, bytes));
  return ZipEncoder().encodeBytes(archive);
}

class _EmptyPlanRepository implements PlanRepository {
  @override
  Future<List<ReadingPlan>> loadPlans() async => <ReadingPlan>[];

  @override
  Future<void> savePlans(List<ReadingPlan> plans) async {}
}

class _EmptyVersionRepository extends BibleVersionRepository {
  @override
  Future<TranslationRepositoryState> loadTranslationState() async =>
      const TranslationRepositoryState(
        installations: <BibleTranslation, TranslationInstallationState>{},
        onlineEnabled: <BibleTranslation>{},
      );
}
