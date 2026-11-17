import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:scripture_planner/src/app/bootstrap/local_data_bootstrap.dart';
import 'package:scripture_planner/src/app/new_man_app.dart';
import 'package:scripture_planner/src/data/bible_books.dart';
import 'package:scripture_planner/src/features/word/bible/application/bible_reader_request.dart';
import 'package:scripture_planner/src/features/word/audio/application/bible_audio_service.dart';
import 'package:scripture_planner/src/features/word/translations/data/drift_bible_version_repository.dart';
import 'package:scripture_planner/src/features/word/translations/data/local/word_translation_state_dao.dart';
import 'package:scripture_planner/src/features/word/translations/domain/translation_state.dart';
import 'package:scripture_planner/src/features/word/translations/presentation/translation_manager_screen.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/models/scripture_reference.dart';
import 'package:scripture_planner/src/screens/reader_screen.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';

void main() {
  testWidgets(
    'installed synthetic KJV reopens through real bootstrap and offline Reader',
    (tester) async {
      final originalPaths = PathProviderPlatform.instance;
      final originalAsync = SharedPreferencesAsyncPlatform.instance;
      final originalLegacy = SharedPreferencesStorePlatform.instance;
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('synthetic-kjv-bootstrap-'),
      ))!;
      final network = _DenyNetwork();
      LocalDataBootstrapResult? session;
      PathProviderPlatform.instance = _OwnedPaths(directory.path);
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      Future<void> closeSession() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        final current = session;
        session = null;
        if (current != null) {
          await tester.runAsync(() async {
            current.taskService.dispose();
            current.controller.versionRepository.dispose();
            current.controller.dispose();
            await current.database.close();
          });
        }
      }

      Future<void> showVersions() async {
        session!.controller.selectDestination(1);
        session!.controller.selectWordDestination(3);
        await tester.pumpWidget(
          NewManApp(
            controller: session!.controller,
            taskService: session!.taskService,
          ),
        );
        // IndexedStack siblings also query real SQLite. Yield host I/O before
        // asking the fake frame clock to settle their loading indicators.
        for (var tries = 0; tries < 200; tries++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump(const Duration(milliseconds: 16));
          if (!tester.binding.hasScheduledFrame) break;
        }
        await tester.pumpAndSettle();
      }

      try {
        await HttpOverrides.runWithHttpOverrides(() async {
          await tester.runAsync(() async {
            for (final path in ['support', 'documents', 'cache', 'temp']) {
              await Directory('${directory.path}/$path').create();
            }
            session = await bootstrapLocalData();
          });
          expect(session!.driftIsAuthoritative, isTrue);
          expect(
            session!.controller
                .translationAvailability(BibleTranslation.kjv)
                .kind,
            TranslationAvailabilityKind.downloadAvailable,
          );
          await showVersions();
          expect(find.text('AVAILABLE TO DOWNLOAD'), findsOneWidget);
          expect(find.text('INSTALLED'), findsNothing);
          var syntheticRequests = 0;
          final client = MockClient((request) async {
            syntheticRequests++;
            return http.Response.bytes(_syntheticArchive(), 200);
          });
          await tester.runAsync(() async {
            final installer = DriftBibleVersionRepository(
              WordTranslationStateDao(session!.database),
              httpClient: client,
            );
            try {
              await installer.install(BibleTranslation.kjv);
              expect(await installer.isKjvInstalled(), isTrue);
              final state = await WordTranslationStateDao(
                session!.database,
              ).loadInstallationStates();
              expect(
                state[BibleTranslation.kjv]?.status,
                TranslationInstallationStatus.installed,
              );
            } finally {
              installer.dispose();
              client.close();
            }
          });
          expect(syntheticRequests, 1);
          final oldController = session!.controller;
          await closeSession();
          // No installed-source client/converter or injected Scripture repository
          // survives this point. Bootstrap and Reader must discover disk content.
          await tester.runAsync(
            () async => session = await bootstrapLocalData(),
          );
          expect(identical(session!.controller, oldController), isFalse);
          expect(session!.driftIsAuthoritative, isTrue);
          expect(
            session!.controller
                .translationAvailability(BibleTranslation.kjv)
                .kind,
            TranslationAvailabilityKind.installedOffline,
          );
          await showVersions();
          expect(find.text('INSTALLED'), findsOneWidget);
          expect(find.text('AVAILABLE TO DOWNLOAD'), findsNothing);
          final bundled =
              jsonDecode(await rootBundle.loadString('assets/data/kjv.json'))
                  as Map<String, dynamic>;
          expect((bundled['metadata'] as Map)['complete'], isFalse);
          final bundledBooks = bundled['books'] as Map;
          for (final reference in const [
            ScriptureReference(book: 'Genesis', startChapter: 1),
            ScriptureReference(book: 'Revelation', startChapter: 22),
          ]) {
            expect(
              (bundledBooks[reference.book] as Map?)?[reference.startChapter
                  .toString()],
              isNull,
            );
            final expectedVerse =
                'generated ${reference.book} ${reference.startChapter} verse 1';
            final navigator = Navigator.of(
              tester.element(find.byType(TranslationManagerScreen)),
            );
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => ReaderScreen(
                  controller: session!.controller,
                  request: BibleReaderRequest.manual(references: [reference]),
                  audio:
                      _NoNarration(), // Text acceptance does not exercise a native TTS plugin.
                ),
              ),
            );
            await tester.pump();
            for (
              var tries = 0;
              tries < 200 &&
                  find.textContaining(expectedVerse).evaluate().isEmpty;
              tries++
            ) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 5)),
              );
              await tester.pump();
            }
            await tester.pumpAndSettle();
            expect(find.textContaining(expectedVerse), findsWidgets);
            expect(find.textContaining('demo KJV'), findsNothing);
            expect(find.textContaining('bundled'), findsNothing);
            expect(find.textContaining('could not'), findsNothing);
            navigator.pop();
            await tester.pumpAndSettle();
          }
          // Prove both bootstrap clients were created under the deny override,
          // rather than treating an unused network counter as evidence.
          expect(network.clients.length, greaterThanOrEqualTo(2));
          expect(network.attempts, 0);
          await tester.runAsync(() async {
            final file = await BibleVersionRepository.kjvDataFile();
            expect(file.path, '${directory.path}/support/bibles/kjv.json');
            expect(
              await File(
                '${directory.path}/support/database/new_man.sqlite',
              ).exists(),
              isTrue,
            );
            expect(await file.exists(), isTrue);
          });
        }, network);
      } finally {
        await closeSession();
        for (final client in network.clients) {
          client.close(force: true);
        }
        PathProviderPlatform.instance = originalPaths;
        SharedPreferencesAsyncPlatform.instance = originalAsync;
        SharedPreferencesStorePlatform.instance = originalLegacy;
        await tester.runAsync(() => directory.delete(recursive: true));
      }
      expect(tester.takeException(), isNull);
    },
  );
}

class _OwnedPaths extends PathProviderPlatform {
  _OwnedPaths(this.root);
  final String root;
  @override
  Future<String?> getApplicationSupportPath() async => '$root/support';
  @override
  Future<String?> getApplicationDocumentsPath() async => '$root/documents';
  @override
  Future<String?> getApplicationCachePath() async => '$root/cache';
  @override
  Future<String?> getTemporaryPath() async => '$root/temp';
}

class _DenyNetwork extends HttpOverrides {
  int attempts = 0;
  final clients = <HttpClient>[];
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    clients.add(client);
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      attempts++;
      throw StateError('Network forbidden in synthetic offline acceptance');
    };
    return client;
  }
}

class _NoNarration implements BibleAudioService {
  @override
  AudioPlaybackSnapshot get playback =>
      const AudioPlaybackSnapshot(AudioPlaybackState.idle);
  @override
  bool get supportsPause => false;
  @override
  void addPlaybackListener(void Function() listener) {}
  @override
  void removePlaybackListener(void Function() listener) {}
  @override
  Future<List<TtsVoiceOption>> getVoices() async => [];
  @override
  Future<void> setRate(double rate) async {}
  @override
  Future<void> setVoice(TtsVoiceOption voice) async {}
  @override
  Future<void> speak(String text) async =>
      throw StateError('No audio in text acceptance');
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async {}
}

// Generated canonical-shaped fixture: invented text only, not a distributed edition.
List<int> _syntheticArchive() {
  const verseCounts = <int>[
    1533,
    1213,
    859,
    1288,
    959,
    658,
    618,
    85,
    810,
    695,
    816,
    719,
    942,
    822,
    280,
    406,
    167,
    1070,
    2461,
    915,
    222,
    117,
    1292,
    1364,
    154,
    1273,
    357,
    197,
    73,
    146,
    21,
    48,
    105,
    47,
    56,
    53,
    38,
    211,
    55,
    1071,
    678,
    1151,
    879,
    1007,
    433,
    437,
    257,
    149,
    155,
    104,
    95,
    89,
    47,
    113,
    83,
    46,
    25,
    303,
    108,
    105,
    61,
    105,
    13,
    14,
    25,
    404,
  ];
  const alternateCodes = <String, String>{
    'SNG': 'SOL',
    'JOL': 'JOE',
    'MRK': 'MAR',
    'JHN': 'JOH',
    'PHP': 'PHI',
    '1JN': '1JO',
    '2JN': '2JO',
    '3JN': '3JO',
  };
  final lines = <String>[];
  var bookIndex = 0;
  for (final entry in eBibleVplBookNames.entries) {
    final code = alternateCodes[entry.key] ?? entry.key;
    final book = bibleBooks[bookIndex];
    expect(book.name, entry.value);
    const firstChapter = 1;
    final chapterCount = book.chapterCount - firstChapter + 1;
    var remaining = verseCounts[bookIndex];
    for (var chapter = firstChapter; chapter <= book.chapterCount; chapter++) {
      final denominator = chapterCount - (chapter - firstChapter);
      final count = remaining ~/ denominator;
      remaining -= count;
      const firstVerse = 1;
      for (var verse = firstVerse; verse < firstVerse + count; verse++) {
        lines.add(
          '$code $chapter:$verse generated ${entry.value} $chapter verse $verse',
        );
      }
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
