import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/app/new_man_app.dart';
import 'package:scripture_planner/src/controllers/app_controller.dart';
import 'package:scripture_planner/src/features/word/bible/application/bible_reader_request.dart';
import 'package:scripture_planner/src/features/word/bible/presentation/bible_book_browser_screen.dart';
import 'package:scripture_planner/src/features/word/bible/presentation/open_bible_screen.dart';
import 'package:scripture_planner/src/features/word/audio/application/bible_audio_service.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/models/scripture_reference.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';
import 'package:scripture_planner/src/services/plan_repository.dart';
import 'package:scripture_planner/src/services/scripture_service.dart';
import 'package:scripture_planner/src/screens/reader_screen.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => call.method == 'getApplicationSupportDirectory'
              ? Directory.systemTemp.path
              : null,
        );
  });

  testWidgets('opens a saved plan, Scripture, and translation selector', (
    tester,
  ) async {
    final loadedPassage = await tester.runAsync(
      () => KjvScriptureService().getPassage(
        const ScriptureReference(
          book: 'Matthew',
          startChapter: 5,
          startVerse: 1,
          endVerse: 2,
        ),
      ),
    );
    expect(loadedPassage?.text, contains('And seeing the multitudes'));
    final plan = ReadingPlan(
      id: 'smoke-plan',
      title: 'Smoke plan',
      defaultTranslation: BibleTranslation.kjv,
      createdAt: DateTime(2026, 8, 14),
      startDate: DateTime(2026, 8, 14),
      endDate: DateTime(2026, 8, 14),
      readingWeekdays: <int>{DateTime.friday},
      reminderTime: '07:00',
      sourceReferences: const <ScriptureReference>[
        ScriptureReference(
          book: 'Matthew',
          startChapter: 5,
          startVerse: 1,
          endVerse: 2,
        ),
      ],
      assignments: <ScheduledReading>[
        ScheduledReading(
          date: DateTime(2026, 8, 14),
          references: const <ScriptureReference>[
            ScriptureReference(
              book: 'Matthew',
              startChapter: 5,
              startVerse: 1,
              endVerse: 2,
            ),
          ],
        ),
      ],
    );
    final controller = AppController(
      repository: _MemoryPlanRepository(<ReadingPlan>[plan]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();

    await tester.pumpWidget(NewManApp(controller: controller));
    await tester.tap(find.text('Word'));
    await tester.pumpAndSettle();
    final savedPlan = find.text('Smoke plan').last;
    await tester.ensureVisible(savedPlan);
    await tester.pumpAndSettle();
    await tester.tap(savedPlan);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matthew 5:1-2'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();

    expect(find.text('Matthew 5:1-2'), findsAtLeastNWidgets(1));
    expect(find.text('Listen'), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsNothing);

    await tester.tap(find.text('KJV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('NLT — Setup required'), findsOneWidget);
  });

  testWidgets('opens Scripture manually without a Bible Plan', (tester) async {
    final controller = AppController(
      repository: _MemoryPlanRepository(<ReadingPlan>[]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: OpenBibleScreen(
          controller: controller,
          readerBuilder: (_, request) => _ManualRequestProbe(request: request),
        ),
      ),
    );

    expect(
      find.textContaining('A reading plan is not required.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Matthew 5:1-2');
    await tester.tap(find.widgetWithText(FilledButton, 'Open Bible'));
    await tester.pumpAndSettle();

    expect(find.text('Manual request: Matthew 5:1-2'), findsOneWidget);
    expect(find.text('Plan progress: none'), findsOneWidget);
  });

  testWidgets('browses books and valid chapters into the common request', (
    tester,
  ) async {
    final controller = AppController(
      repository: _MemoryPlanRepository(<ReadingPlan>[]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: BibleBookBrowserScreen(
          controller: controller,
          readerBuilder: (_, request) => _ManualRequestProbe(request: request),
        ),
      ),
    );

    expect(find.text('Old Testament'), findsOneWidget);
    expect(find.text('New Testament'), findsOneWidget);
    await tester.tap(find.text('Genesis'));
    await tester.pumpAndSettle();
    expect(find.text('50'), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('Manual request: Genesis 1'), findsOneWidget);
  });

  testWidgets('Word shows persisted Continue Reading state', (tester) async {
    final controller = AppController(
      repository: _MemoryPlanRepository(<ReadingPlan>[]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();
    await controller.saveReaderPosition(
      book: 'Romans',
      chapter: 8,
      translation: BibleTranslation.kjv,
    );

    await tester.pumpWidget(NewManApp(controller: controller));
    await tester.tap(find.text('Word'));
    await tester.pumpAndSettle();
    expect(find.text('CONTINUE READING'), findsOneWidget);
    expect(find.text('Romans 8'), findsOneWidget);
    expect(find.text('Browse Bible'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ReaderScreen), findsOneWidget);
  });

  testWidgets('Word Home orders continuity entries and routes to Saved and Bible', (
    tester,
  ) async {
    final controller = AppController(
      repository: _MemoryPlanRepository(<ReadingPlan>[]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();
    await controller.saveReaderPosition(
      book: 'Romans',
      chapter: 8,
      translation: BibleTranslation.kjv,
    );

    await tester.pumpWidget(NewManApp(controller: controller));
    await tester.tap(find.text('Word'));
    await tester.pumpAndSettle();

    final labels = <String>[
      'CONTINUE READING',
      'PLAN CONTINUITY',
      'SAVED SCRIPTURE',
      'BIBLE',
    ];
    final positions = labels
        .map((label) => tester.getTopLeft(find.text(label)).dy)
        .toList();
    expect(positions[0], lessThan(positions[1]));
    expect(positions[1], lessThan(positions[2]));
    expect(positions[2], lessThan(positions[3]));
    expect(find.text('Browse Bible'), findsOneWidget);
    expect(
      find.text('A plan can help guide your Scripture reading.'),
      findsOneWidget,
    );

    final savedScripture = find.text('Saved Scripture');
    await tester.ensureVisible(savedScripture);
    await tester.tap(
      find.ancestor(of: savedScripture, matching: find.byType(ListTile)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bookmarks'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<int>),
        matching: find.text('Word'),
      ),
    );
    await tester.pumpAndSettle();
    final browseBible = find.text('Browse Bible');
    await tester.ensureVisible(browseBible);
    await tester.tap(
      find.ancestor(of: browseBible, matching: find.byType(ListTile)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Old Testament'), findsOneWidget);
  });

  testWidgets('Word Home omits Continue Reading and continues today’s Plan', (
    tester,
  ) async {
    final today = DateTime.now();
    final plan = ReadingPlan(
      id: 'today-plan',
      title: 'Today plan',
      defaultTranslation: BibleTranslation.kjv,
      createdAt: today,
      startDate: today,
      endDate: today,
      readingWeekdays: <int>{today.weekday},
      reminderTime: '07:00',
      sourceReferences: const <ScriptureReference>[
        ScriptureReference(book: 'Romans', startChapter: 8),
      ],
      assignments: <ScheduledReading>[
        ScheduledReading(
          date: today,
          references: const <ScriptureReference>[
            ScriptureReference(book: 'Romans', startChapter: 8),
          ],
        ),
      ],
    );
    final controller = AppController(
      repository: _MemoryPlanRepository(<ReadingPlan>[plan]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();

    await tester.pumpWidget(NewManApp(controller: controller));
    await tester.tap(find.text('Word'));
    await tester.pumpAndSettle();
    expect(find.text('CONTINUE READING'), findsNothing);
    expect(find.text('Today plan'), findsOneWidget);

    await tester.tap(find.text('Continue Plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ReaderScreen), findsOneWidget);
  });

  testWidgets('chapter navigation stops stale audio and persists position', (
    tester,
  ) async {
    final controller = AppController(
      repository: _MemoryPlanRepository(<ReadingPlan>[]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();
    final audio = _FakeAudioService();
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderScreen(
          controller: controller,
          request: BibleReaderRequest.manual(
            references: const <ScriptureReference>[
              ScriptureReference(book: 'Matthew', startChapter: 5),
            ],
          ),
          audio: audio,
          scriptureRepositoryFactory: (_) => _FakeScriptureRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matthew 6'));
    await tester.pumpAndSettle();

    expect(find.text('Matthew 6'), findsAtLeastNWidgets(1));
    expect(controller.lastReaderPosition?.chapter, 6);
    expect(audio.stopCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('Reader selection bookmarks Scripture and Saved reopens it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController(
      repository: _MemoryPlanRepository(<ReadingPlan>[]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderScreen(
          controller: controller,
          request: BibleReaderRequest.manual(
            references: const <ScriptureReference>[
              ScriptureReference(book: 'Matthew', startChapter: 5),
            ],
          ),
          audio: _FakeAudioService(),
          scriptureRepositoryFactory: (_) => _FakeScriptureRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 Synthetic text'), findsOneWidget);
    await tester.tap(find.text('1 Synthetic text'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bookmark'));
    await tester.pumpAndSettle();

    final bookmarks = await controller.savedScriptureRepository.loadBookmarks();
    expect(bookmarks.single.anchor.display, 'Matthew 5:1');

    await tester.pumpWidget(NewManApp(controller: controller));
    await tester.tap(find.text('Word'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    final savedBookmark = find.text('Matthew 5:1');
    expect(savedBookmark, findsOneWidget);
    await tester.tap(savedBookmark);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('Matthew 5:1'), findsAtLeastNWidgets(1));
  });

  testWidgets('translation switching preserves Plan Scripture', (tester) async {
    final plan = ReadingPlan(
      id: 'translation-plan',
      title: 'Translation plan',
      defaultTranslation: BibleTranslation.kjv,
      createdAt: DateTime(2026, 8, 15),
      startDate: DateTime(2026, 8, 15),
      endDate: DateTime(2026, 8, 15),
      readingWeekdays: <int>{DateTime.saturday},
      reminderTime: '07:00',
      sourceReferences: const <ScriptureReference>[
        ScriptureReference(book: 'Matthew', startChapter: 5),
      ],
      assignments: <ScheduledReading>[
        ScheduledReading(
          date: DateTime(2026, 8, 15),
          references: const <ScriptureReference>[
            ScriptureReference(book: 'Matthew', startChapter: 5),
          ],
        ),
      ],
    );
    final controller = AppController(
      repository: _MemoryPlanRepository(<ReadingPlan>[plan]),
      versionRepository: _InstalledTranslationsRepository(),
      nltOnlineConfigured: true,
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderScreen(
          controller: controller,
          request: BibleReaderRequest.fromPlanReading(
            references: plan.assignments.single.references,
            initialTranslation: BibleTranslation.kjv,
            planId: plan.id,
            assignmentIndex: 0,
          ),
          audio: _FakeAudioService(),
          scriptureRepositoryFactory: (_) => _FakeScriptureRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('KJV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NLT — Online').last);
    await tester.pumpAndSettle();

    expect(find.text('Matthew 5'), findsAtLeastNWidgets(1));
    expect(
      controller.plans.single.assignments.single.references.single.display,
      'Matthew 5',
    );
    expect(
      controller.plans.single.assignments.single.translationOverride,
      BibleTranslation.nlt,
    );
  });

  testWidgets(
    'online-only translation without provider setup stays selected and explains the failure',
    (tester) async {
      final controller = AppController(
        repository: _MemoryPlanRepository(<ReadingPlan>[]),
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      await controller.saveReaderPosition(
        book: 'Romans',
        chapter: 8,
        translation: BibleTranslation.nlt,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ReaderScreen(
            controller: controller,
            request: BibleReaderRequest.manual(
              references: const <ScriptureReference>[
                ScriptureReference(book: 'Romans', startChapter: 8),
              ],
              initialTranslation: BibleTranslation.nlt,
            ),
            audio: _FakeAudioService(),
            scriptureRepositoryFactory: (_) => _FakeScriptureRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('online-only'), findsOneWidget);
      expect(find.byIcon(Icons.download_outlined), findsNothing);
      expect(controller.lastReaderPosition?.translation, BibleTranslation.nlt);
      expect(controller.lastReaderPosition?.chapter, 8);
    },
  );

  testWidgets('Listen from here starts at the earliest sparse selected verse', (tester) async {
    final controller = AppController(repository: _MemoryPlanRepository(<ReadingPlan>[]), versionRepository: _InstalledKjvRepository());
    await controller.load();
    final audio = _QueuedAudioService();
    await tester.pumpWidget(MaterialApp(home: ReaderScreen(
      controller: controller,
      request: BibleReaderRequest.manual(references: const <ScriptureReference>[ScriptureReference(book: 'Matthew', startChapter: 5)]),
      audio: audio,
      scriptureRepositoryFactory: (_) => _TextScriptureRepository('8 Eight\n9 Nine\n10 Ten'),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8 Eight'));
    await tester.tap(find.text('10 Ten'));
    await tester.pump();
    await tester.tap(find.text('Listen from here'));
    await tester.pump();
    expect(audio.stopCalls, 1);
    expect(audio.spoken, <String>['8. Eight']);
    audio.finishCurrent();
    await tester.pump();
    expect(audio.spoken, <String>['8. Eight', '9. Nine']);
    audio.finishCurrent();
    await tester.pump();
    audio.finishCurrent();
    await tester.pump();
  });

  testWidgets('Reader Search dismisses on Listen and Scripture selection, then reopens', (tester) async {
    final controller = AppController(repository: _MemoryPlanRepository(<ReadingPlan>[]), versionRepository: _InstalledKjvRepository());
    await controller.load();
    await tester.pumpWidget(MaterialApp(home: ReaderScreen(
      controller: controller,
      request: BibleReaderRequest.manual(references: const <ScriptureReference>[ScriptureReference(book: 'Matthew', startChapter: 5)]),
      audio: _FakeAudioService(),
      scriptureRepositoryFactory: (_) => _TextScriptureRepository('1 One\n2 Two'),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Go to Scripture'));
    await tester.pumpAndSettle();
    expect(find.text('Go to Scripture'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

    await tester.tap(find.text('Listen'));
    await tester.pumpAndSettle();
    expect(find.text('Go to Scripture'), findsNothing);

    await tester.tap(find.byTooltip('Go to Scripture'));
    await tester.pumpAndSettle();
    expect(find.text('Go to Scripture'), findsOneWidget);
    await tester.tap(find.text('1 One'));
    await tester.pumpAndSettle();
    expect(find.text('Go to Scripture'), findsNothing);

    await tester.tap(find.byTooltip('Go to Scripture'));
    await tester.pumpAndSettle();
    expect(find.text('Go to Scripture'), findsOneWidget);
  });

  testWidgets('voice picker exposes every platform voice returned by audio service', (tester) async {
    final controller = AppController(repository: _MemoryPlanRepository(<ReadingPlan>[]), versionRepository: _InstalledKjvRepository());
    await controller.load();
    final voices = <TtsVoiceOption>[const TtsVoiceOption(key: 'en', name: 'English', locale: 'en-US', settings: <String, String>{}, networkRequired: false), const TtsVoiceOption(key: 'fr', name: 'French', locale: 'fr-FR', settings: <String, String>{}, networkRequired: false)];
    final audio = _QueuedAudioService(voices: voices);
    await tester.pumpWidget(MaterialApp(home: ReaderScreen(controller: controller, request: BibleReaderRequest.manual(references: const <ScriptureReference>[ScriptureReference(book: 'Matthew', startChapter: 5)]), audio: audio, scriptureRepositoryFactory: (_) => _FakeScriptureRepository())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listen'));
    await tester.pump();
    await tester.tap(find.text('English (en-US)'));
    await tester.pumpAndSettle();
    expect(find.text('French (fr-FR)'), findsOneWidget);
  });
}

class _ManualRequestProbe extends StatelessWidget {
  const _ManualRequestProbe({required this.request});

  final BibleReaderRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Text('Manual request: ${request.references.single.display}'),
          Text(
            'Plan progress: ${request.planProgress == null ? 'none' : 'linked'}',
          ),
        ],
      ),
    );
  }
}

class _MemoryPlanRepository implements PlanRepository {
  _MemoryPlanRepository(this.plans);

  List<ReadingPlan> plans;

  @override
  Future<List<ReadingPlan>> loadPlans() async => List<ReadingPlan>.from(plans);

  @override
  Future<void> savePlans(List<ReadingPlan> plans) async {
    this.plans = List<ReadingPlan>.from(plans);
  }
}

class _InstalledKjvRepository extends BibleVersionRepository {
  @override
  Future<Set<BibleTranslation>> loadInstalled() async => <BibleTranslation>{
    BibleTranslation.kjv,
  };
}

class _InstalledTranslationsRepository extends BibleVersionRepository {
  @override
  Future<Set<BibleTranslation>> loadInstalled() async =>
      BibleTranslation.values.toSet();
}

class _FakeScriptureRepository implements ScriptureRepository {
  @override
  Future<ScriptureTextResult> getPassage(ScriptureReference reference) async =>
      ScriptureTextResult(reference: reference.display, text: 'Synthetic text');
}

class _TextScriptureRepository implements ScriptureRepository {
  _TextScriptureRepository(this.text);
  final String text;
  @override
  Future<ScriptureTextResult> getPassage(ScriptureReference reference) async => ScriptureTextResult(reference: reference.display, text: text);
}

class _FakeAudioService implements BibleAudioService {
  _FakeAudioService({this.voices = const <TtsVoiceOption>[]});
  int stopCalls = 0;
  final List<TtsVoiceOption> voices;
  final AudioPlaybackSnapshot _playback = const AudioPlaybackSnapshot(
    AudioPlaybackState.idle,
  );

  @override
  AudioPlaybackSnapshot get playback => _playback;

  @override
  bool get supportsPause => false;

  @override
  void addPlaybackListener(void Function() listener) {}

  @override
  void removePlaybackListener(void Function() listener) {}

  @override
  Future<List<TtsVoiceOption>> getVoices() async => voices;

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> setVoice(TtsVoiceOption voice) async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

class _QueuedAudioService extends _FakeAudioService {
  _QueuedAudioService({super.voices});
  final List<String> spoken = <String>[];
  Completer<void>? _current;

  @override
  Future<void> speak(String text) {
    spoken.add(text);
    _current = Completer<void>();
    return _current!.future;
  }

  void finishCurrent() => _current?.complete();
}
