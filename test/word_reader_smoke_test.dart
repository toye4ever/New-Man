import 'dart:async';
import 'package:scripture_planner/src/features/word/audio/presentation/playback_speed_selector.dart';
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
import 'package:scripture_planner/src/screens/plan_details_screen.dart';
import 'package:scripture_planner/src/screens/plans_screen.dart';
import 'package:scripture_planner/src/features/word/bible/application/scripture_search.dart';
import 'package:scripture_planner/src/screens/create_plan_screen.dart';
import 'package:scripture_planner/src/models/plan_template.dart';
import 'package:scripture_planner/src/features/word/translations/presentation/translation_manager_screen.dart';
import 'package:scripture_planner/src/features/word/saved_scripture/presentation/saved_scripture_screen.dart';
import 'package:scripture_planner/src/features/word/bible/presentation/scripture_search_results_screen.dart';

void main() {
  testWidgets('mobile Reader top X returns to Bible books at app root', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(
      repository: _MemoryPlanRepository([]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();
    await tester.pumpWidget(NewManApp(controller: controller));
    await tester.pumpAndSettle();
    unawaited(
      Navigator.of(tester.element(find.byType(Scaffold).first)).push(
        MaterialPageRoute<void>(
          builder: (_) => ReaderScreen(
            controller: controller,
            request: BibleReaderRequest.manual(
              references: const [
                ScriptureReference(book: 'Matthew', startChapter: 5),
              ],
            ),
            audio: _FakeAudioService(),
            scriptureRepositoryFactory: (_) =>
                _TextScriptureRepository('1 Scripture text.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bible books'));
    await tester.pumpAndSettle();
    expect(find.byType(ReaderScreen), findsNothing);
    expect(controller.selectedWordDestination, 2);
    expect(find.text('Genesis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  ReadingPlan chapterPlan() {
    final date = DateTime(2026, 10, 5);
    return ReadingPlan(
      id: 'chapter-plan',
      title: 'Chapter plan',
      defaultTranslation: BibleTranslation.kjv,
      createdAt: date,
      startDate: date,
      endDate: date,
      readingWeekdays: {1, 2, 3, 4, 5, 6, 7},
      reminderTime: '07:00',
      sourceReferences: const [
        ScriptureReference(book: 'Genesis', startChapter: 1, endChapter: 3),
      ],
      assignments: [
        ScheduledReading(
          date: date,
          references: const [
            ScriptureReference(book: 'Genesis', startChapter: 1, endChapter: 3),
          ],
        ),
      ],
    );
  }

  testWidgets(
    'mobile scrolling keeps one dock; selection replaces it and long press opens options',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppController(
        repository: _MemoryPlanRepository([]),
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          home: ReaderScreen(
            controller: controller,
            request: BibleReaderRequest.manual(
              references: const [
                ScriptureReference(book: 'Matthew', startChapter: 5),
              ],
            ),
            audio: _QueuedAudioService(),
            scriptureRepositoryFactory: (_) => _TextScriptureRepository(
              List.generate(
                30,
                (i) => '${i + 1} A verse of Scripture for scrolling.',
              ).join('\n'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPress(find.byTooltip('Play narration'));
      await tester.pumpAndSettle();
      expect(find.text('Translation'), findsOneWidget);
      expect(find.byType(PlaybackSpeedSelector), findsOneWidget);
      Navigator.of(tester.element(find.text('Translation'))).pop();
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(find.byTooltip('Go to Scripture'), findsOneWidget);
      final list = tester.widget<ListView>(find.byType(ListView));
      list.controller!.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 A verse of Scripture for scrolling.'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Clear selection'), findsOneWidget);
      expect(find.byTooltip('Go to Scripture'), findsNothing);
      expect(find.text('Listen from here'), findsNothing);
      final second = find.text('2 A verse of Scripture for scrolling.');
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(of: second, matching: find.byType(Opacity)).first,
            )
            .opacity,
        .35,
      );
      await tester.tap(find.byTooltip('Clear selection'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Go to Scripture'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'queued last-read save cannot resurrect a deleted plan; failed deletion preserves data',
    () async {
      final repository = _DelayedPlanRepository([chapterPlan()]);
      final controller = AppController(
        repository: repository,
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      final reading = controller.recordPlanReading(
        'chapter-plan',
        0,
        const ScriptureReference(book: 'Genesis', startChapter: 1),
      );
      await repository.started.future;
      final deletion = controller.deletePlan('chapter-plan');
      expect(controller.plans, hasLength(1));
      repository.release.complete();
      await Future.wait([reading, deletion]);
      expect(controller.plans, isEmpty);
      expect(repository.plans, isEmpty);

      final failing = _FailingPlanRepository()..plans = [chapterPlan()];
      final retryController = AppController(
        repository: failing,
        versionRepository: _InstalledKjvRepository(),
      );
      await retryController.load();
      await expectLater(
        retryController.deletePlan('chapter-plan'),
        throwsStateError,
      );
      expect(retryController.plans, hasLength(1));
      failing.fail = false;
      await retryController.deletePlan('chapter-plan');
      expect(retryController.plans, isEmpty);
    },
  );

  testWidgets(
    'mobile options update pause, resume, repeat, verse and speed while open',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final audio = _QueuedAudioService();
      final controller = AppController(
        repository: _MemoryPlanRepository([]),
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          home: ReaderScreen(
            controller: controller,
            request: BibleReaderRequest.manual(
              references: const [
                ScriptureReference(book: 'Matthew', startChapter: 5),
              ],
            ),
            audio: audio,
            scriptureRepositoryFactory: (_) =>
                _TextScriptureRepository('1 First verse.\n2 Second verse.'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Play narration'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Reading options'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Pause at this verse'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Resume reading'), findsOneWidget);
      await tester.tap(find.byTooltip('Repeat chapter off'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Repeat chapter once'), findsOneWidget);
      await tester.tap(find.byTooltip('Next verse'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Verse 2 of 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Resume reading'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Pause at this verse'), findsOneWidget);
      final selector = tester.widget<PlaybackSpeedSelector>(
        find.byType(PlaybackSpeedSelector),
      );
      selector.onChanged(.9);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlaybackSpeedSelector>(find.byType(PlaybackSpeedSelector))
            .rate,
        .9,
      );
      expect(find.text('Translation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'chapter completion failure preserves state, serialized writes retain all chapters',
    () async {
      final repository = _FailingPlanRepository()..plans = [chapterPlan()];
      final controller = AppController(
        repository: repository,
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      const one = ScriptureReference(book: 'Genesis', startChapter: 1);
      const two = ScriptureReference(book: 'Genesis', startChapter: 2);
      await expectLater(
        controller.completePlanChapter('chapter-plan', 0, one),
        throwsStateError,
      );
      expect(controller.plans.single.completedChapterCount, 0);
      repository.fail = false;
      await Future.wait([
        controller.completePlanChapter('chapter-plan', 0, one),
        controller.recordPlanReading('chapter-plan', 0, two),
        controller.completePlanChapter('chapter-plan', 0, two),
      ]);
      expect(controller.plans.single.completedChapterCount, 2);
      expect(controller.plans.single.lastReadLocation, two);
      await controller.completePlanChapter('chapter-plan', 0, one);
      expect(repository.plans.single.completedChapterCount, 2);
      expect(repository.plans.single.assignments.single.completed, false);
      final preview = controller.previewCatchUpPlan(
        'chapter-plan',
        fromDate: DateTime(2026, 10, 5),
      );
      await controller.completePlanChapter(
        'chapter-plan',
        0,
        const ScriptureReference(book: 'Genesis', startChapter: 3),
      );
      await expectLater(
        controller.applyCatchUpPreview(preview),
        throwsStateError,
      );
      expect(controller.plans.single.completedChapterCount, 3);
    },
  );
  test(
    'Catch Me Up rejects reopened partial progress without another write',
    () async {
      final initial = chapterPlan();
      final repository = _MemoryPlanRepository([
        initial.copyWith(
          assignments: [
            initial.assignments.single.copyWith(
              completedChapterKeys: const {'Genesis:1'},
            ),
          ],
        ),
      ]);
      final controller = AppController(
        repository: repository,
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      final preview = controller.previewCatchUpPlan(
        'chapter-plan',
        fromDate: DateTime(2026, 10, 5),
      );
      final current = controller.plans.single;
      await controller.savePlan(
        current.copyWith(
          assignments: [
            current.assignments.single.copyWith(completedChapterKeys: const {}),
          ],
        ),
      );
      expect(repository.saveCalls, 1);

      await expectLater(
        controller.applyCatchUpPreview(preview),
        throwsStateError,
      );

      expect(repository.saveCalls, 1);
      expect(controller.plans.single.completedChapterCount, 0);
      expect(repository.plans.single.completedChapterCount, 0);
      expect(
        repository.plans.single.assignments.single.completedChapterKeys,
        isEmpty,
      );
    },
  );
  test(
    'Catch Me Up rejects a reopened completed day without another write',
    () async {
      final initial = chapterPlan();
      final repository = _MemoryPlanRepository([
        initial.copyWith(
          assignments: [initial.assignments.single.copyWith(completed: true)],
        ),
      ]);
      final controller = AppController(
        repository: repository,
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      final preview = controller.previewCatchUpPlan(
        'chapter-plan',
        fromDate: DateTime(2026, 10, 5),
      );
      await controller.toggleReading('chapter-plan', 0);
      expect(repository.saveCalls, 1);

      await expectLater(
        controller.applyCatchUpPreview(preview),
        throwsStateError,
      );

      expect(repository.saveCalls, 1);
      expect(controller.plans.single.assignments.single.completed, false);
      expect(repository.plans.single.assignments.single.completed, false);
      expect(repository.plans.single.completedChapterCount, 0);
    },
  );
  test('Catch Me Up applies a preview when progress is unchanged', () async {
    final repository = _MemoryPlanRepository([chapterPlan()]);
    final controller = AppController(
      repository: repository,
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();
    final preview = controller.previewCatchUpPlan(
      'chapter-plan',
      fromDate: DateTime(2026, 10, 5),
    );

    await controller.applyCatchUpPreview(preview);

    expect(repository.saveCalls, 1);
    expect(
      repository.plans.single.assignments.map((day) => day.toJson()),
      preview.assignments.map((day) => day.toJson()),
    );
  });
  testWidgets(
    'compact mobile chapter controls preserve progress and finish back at details',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _FailingPlanRepository()
        ..plans = [chapterPlan()]
        ..fail = false;
      final controller = AppController(
        repository: repository,
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Plan details'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ReaderScreen(
                      controller: controller,
                      request: BibleReaderRequest.fromPlanReading(
                        references: chapterPlan().assignments.single.references,
                        initialTranslation: BibleTranslation.kjv,
                        planId: 'chapter-plan',
                        assignmentIndex: 0,
                      ),
                      audio: _FakeAudioService(),
                      scriptureRepositoryFactory: (_) =>
                          _TextScriptureRepository(
                            '1 First verse.\n2 Second verse.',
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Plan details'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Back to plan'), findsOneWidget);
      expect(find.text('Listen'), findsNothing);
      repository.fail = true;
      await tester.tap(find.byTooltip('Complete chapter and continue'));
      await tester.pumpAndSettle();
      expect(controller.plans.single.completedChapterCount, 0);
      expect(find.text('Genesis 1'), findsWidgets);
      repository.fail = false;
      await tester.tap(find.byTooltip('Complete chapter and continue'));
      await tester.pumpAndSettle();
      expect(controller.plans.single.completedChapterCount, 1);
      await tester.tap(find.byTooltip('Previous chapter'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Complete chapter and continue'));
      await tester.pumpAndSettle();
      expect(controller.plans.single.completedChapterCount, 1);
      await tester.tap(find.byTooltip('Complete chapter and continue'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Complete chapter and finish day'), findsOneWidget);
      await tester.tap(find.byTooltip('Complete chapter and finish day'));
      await tester.pumpAndSettle();
      expect(find.text('Plan details'), findsOneWidget);
      expect(controller.plans.single.assignments.single.completed, true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'plan editing removes redundant control, returns to Plans and retains last read',
    (tester) async {
      final date = DateTime(2026, 10, 5);
      const reference = ScriptureReference(book: 'Genesis', startChapter: 1);
      final plan = ReadingPlan(
        id: 'edit-plan',
        title: 'Edit test',
        defaultTranslation: BibleTranslation.kjv,
        createdAt: date,
        startDate: date,
        endDate: date,
        readingWeekdays: {1, 2, 3, 4, 5, 6, 7},
        reminderTime: '07:00',
        sourceReferences: const [reference],
        lastReadLocation: reference,
        lastReadAssignmentHint: 0,
        assignments: [
          ScheduledReading(
            date: date,
            references: const [reference],
            completed: true,
          ),
        ],
      );
      final repository = _MemoryPlanRepository([plan]);
      final controller = AppController(
        repository: repository,
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Plans root'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlanDetailsScreen(
                      controller: controller,
                      planId: plan.id,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Plans root'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Edit entire plan'), findsNothing);
      expect(find.byTooltip('Delete plan'), findsOneWidget);
      expect(find.text('Edit plan'), findsOneWidget);
      await tester.tap(find.text('Edit plan'));
      await tester.pumpAndSettle();
      final title = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Plan name',
      );
      await tester.enterText(title, 'Renamed plan');
      await tester.ensureVisible(find.text('Preview plan changes'));
      await tester.tap(find.text('Preview plan changes'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanDetailsScreen), findsNothing);
      expect(find.byType(CreatePlanScreen), findsNothing);
      expect(find.text('Plans root'), findsOneWidget);
      expect(repository.plans.single.title, 'Renamed plan');
      expect(
        repository.plans.single.lastReadLocation?.display,
        reference.display,
      );
      expect(repository.plans.single.lastReadAssignmentHint, 0);
      expect(repository.plans.single.completedCount, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'schedule cancellation and failure preserve state; success returns to Plans',
    (tester) async {
      final repository = _FailingPlanRepository();
      final controller = AppController(
        repository: repository,
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      controller.selectWordDestination(2);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Plans root'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: CreatePlanScreen(
                        controller: controller,
                        planToEdit: null,
                        template: const PlanTemplate(
                          id: 'test',
                          title: 'Test schedule',
                          description: 'Test',
                          defaultDurationDays: 2,
                          iconName: 'book',
                          references: [
                            ScriptureReference(
                              book: 'Genesis',
                              startChapter: 1,
                              endChapter: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Plans root'));
      await tester.pumpAndSettle();
      Future<void> preview() async {
        await tester.ensureVisible(find.text('Preview schedule'));
        await tester.tap(find.text('Preview schedule'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      await preview();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.plans, isEmpty);
      expect(controller.selectedWordDestination, 2);
      expect(find.byType(CreatePlanScreen), findsOneWidget);
      await preview();
      await tester.tap(find.text('Apply schedule'));
      await tester.pumpAndSettle();
      expect(controller.plans, isEmpty);
      expect(repository.plans, isEmpty);
      expect(controller.selectedWordDestination, 2);
      expect(
        find.textContaining('The plan could not be saved'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      repository.fail = false;
      await preview();
      await tester.tap(find.text('Apply schedule'));
      await tester.pumpAndSettle();
      expect(find.byType(CreatePlanScreen), findsNothing);
      expect(find.text('Plans root'), findsOneWidget);
      expect(controller.plans.single.title, 'Test schedule');
      expect(controller.selectedDestination, 1);
      expect(controller.selectedWordDestination, 1);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [390.0, 1200.0]) {
    testWidgets(
      'Versions routes correctly and Saved remains separate at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = AppController(
          repository: _MemoryPlanRepository([]),
          versionRepository: _InstalledKjvRepository(),
        );
        await controller.load();
        controller.selectDestination(4);
        await tester.pumpWidget(NewManApp(controller: controller));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bible versions'));
        await tester.pumpAndSettle();
        expect(controller.selectedDestination, 1);
        expect(controller.selectedWordDestination, 3);
        expect(
          find.byType(TranslationManagerScreen).hitTestable(),
          findsOneWidget,
        );
        controller.selectWordDestination(4);
        await tester.pumpAndSettle();
        expect(
          find
              .descendant(
                of: find.byType(SavedScriptureScreen),
                matching: find.text('Bookmarks'),
              )
              .hitTestable(),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'compact Bible search appears after scroll, narrow helper is omitted',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppController(
        repository: _MemoryPlanRepository([]),
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleBookBrowserScreen(
              controller: controller,
              readerBuilder: (_, request) =>
                  _ManualRequestProbe(request: request),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Choose a book, then select a chapter.'), findsNothing);
      expect(find.byTooltip('Search Bible'), findsNothing);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -650),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Search Bible').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Search Bible'));
      await tester.pumpAndSettle();
      expect(find.text('Manual request: Matthew 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Bible chapter Back returns to books rather than Word Home', (
    tester,
  ) async {
    final controller = AppController(
      repository: _MemoryPlanRepository([]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BibleBookBrowserScreen(
            controller: controller,
            readerBuilder: (_, request) => Scaffold(
              appBar: AppBar(title: Text(request.references.single.display)),
              body: const Text('Reader probe'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Genesis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Old Testament'), findsOneWidget);
    expect(find.byType(BibleChapterSelectorScreen), findsNothing);
  });

  testWidgets(
    'search Enter keeps query on dedicated results and Back restores it',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppController(
        repository: _MemoryPlanRepository([]),
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          home: ReaderScreen(
            controller: controller,
            request: BibleReaderRequest.manual(
              references: const [
                ScriptureReference(book: 'Matthew', startChapter: 5),
              ],
            ),
            audio: _FakeAudioService(),
            search: ScriptureSearch(() async => const []),
            scriptureRepositoryFactory: (_) =>
                _TextScriptureRepository('1 One\n2 Two'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Go to Scripture'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'unlikely words');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
      expect(find.byType(ScriptureSearchResultsScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('search-query')), findsOneWidget);
      expect(find.textContaining('No Scripture matches.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'unlikely words',
      );
      await tester.enterText(find.byType(TextField), 'rom 4 3');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
      expect(find.byType(ScriptureSearchResultsScreen), findsNothing);
      expect(find.text('Romans 4'), findsWidgets);
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets('final Reader verse clears mobile system inset', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 36);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    final controller = AppController(
      repository: _MemoryPlanRepository([]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderScreen(
          controller: controller,
          request: BibleReaderRequest.manual(
            references: const [
              ScriptureReference(book: 'Matthew', startChapter: 5),
            ],
          ),
          audio: _FakeAudioService(),
          scriptureRepositoryFactory: (_) => _TextScriptureRepository(
            List.generate(
              25,
              (i) => '${i + 1} Verse text ${i + 1}.',
            ).join('\n'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scroll = tester.widget<ListView>(find.byType(ListView));
    scroll.controller!.jumpTo(scroll.controller!.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.text('25 Verse text 25.')).dy,
      lessThanOrEqualTo(664),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Saved plans precede common plans without a redesign', (
    tester,
  ) async {
    final controller = AppController(
      repository: _MemoryPlanRepository([]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlansScreen(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Saved plans')).dy,
      lessThan(tester.getTopLeft(find.text('Common plans')).dy),
    );
  });
  testWidgets(
    'whole plan scrolls to last read then jumps to furthest progress',
    (tester) async {
      final date = DateTime(2026, 10, 2);
      final plan = ReadingPlan(
        id: 'resume-plan',
        title: 'Resume plan',
        defaultTranslation: BibleTranslation.kjv,
        createdAt: date,
        startDate: date,
        endDate: date.add(const Duration(days: 99)),
        readingWeekdays: {1, 2, 3, 4, 5, 6, 7},
        reminderTime: '07:00',
        sourceReferences: const [],
        lastReadLocation: const ScriptureReference(
          book: 'Psalms',
          startChapter: 21,
        ),
        assignments: List.generate(
          100,
          (i) => ScheduledReading(
            date: date.add(Duration(days: i)),
            references: [
              ScriptureReference(book: 'Psalms', startChapter: i + 1),
            ],
            completed: i < 70,
          ),
        ),
      );
      final repository = _MemoryPlanRepository([plan]);
      final controller = AppController(
        repository: repository,
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          home: PlanDetailsScreen(
            controller: controller,
            planId: plan.id,
            initialAssignmentIndex: plan.lastReadAssignmentIndex,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('plan-day-20')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.text('Return to progress'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('plan-day-70')).hitTestable(),
        findsOneWidget,
      );
      await controller.recordPlanReading(
        plan.id,
        2,
        const ScriptureReference(book: 'Psalms', startChapter: 3),
      );
      final reopened = AppController(
        repository: repository,
        versionRepository: _InstalledKjvRepository(),
      );
      await reopened.load();
      expect(reopened.plans.single.lastReadAssignmentIndex, 2);
      expect(reopened.plans.single.progressAssignmentIndex, 70);
    },
  );

  testWidgets(
    'search result scrolls, flashes, and leaves saved highlights unchanged on mobile',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppController(
        repository: _MemoryPlanRepository([]),
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      final search = ScriptureSearch(
        () async => const [
          SearchVerse(
            ScriptureReference(
              book: 'Philippians',
              startChapter: 4,
              startVerse: 8,
            ),
            'Whatsoever things are pure',
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReaderScreen(
            controller: controller,
            request: BibleReaderRequest.manual(
              references: const [
                ScriptureReference(book: 'Matthew', startChapter: 5),
              ],
            ),
            audio: _FakeAudioService(),
            search: search,
            scriptureRepositoryFactory: (_) => _TextScriptureRepository(
              List.generate(
                20,
                (i) => '${i + 1} Verse ${i + 1} with surrounding text.',
              ).join('\n'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Go to Scripture'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Whatsoever things are pure',
      );
      await tester.tap(find.byTooltip('Go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Philippians 4:8'));
      await tester.pumpAndSettle();
      expect(find.text('Philippians 4'), findsWidgets);
      final verse = find.text('8 Verse 8 with surrounding text.');
      expect(verse.hitTestable(), findsOneWidget);
      Container target() => tester.widget<Container>(
        find.ancestor(of: verse, matching: find.byType(Container)).first,
      );
      expect((target().decoration! as BoxDecoration).border, isNotNull);
      await tester.pump(const Duration(seconds: 4));
      expect((target().decoration! as BoxDecoration).border, isNull);
      expect(
        await controller.savedScriptureRepository.loadHighlights(),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
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
    await tester.tap(find.text('Day 1'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();

    expect(find.text('Matthew 5'), findsAtLeastNWidgets(1));
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

  testWidgets(
    'Word Home orders continuity entries and routes to Saved and Bible',
    (tester) async {
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
    },
  );

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
    expect(find.text('Return to progress'), findsOneWidget);
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

  testWidgets('Listen from here starts at the earliest sparse selected verse', (
    tester,
  ) async {
    final controller = AppController(
      repository: _MemoryPlanRepository(<ReadingPlan>[]),
      versionRepository: _InstalledKjvRepository(),
    );
    await controller.load();
    final audio = _QueuedAudioService();
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
          scriptureRepositoryFactory: (_) =>
              _TextScriptureRepository('8 Eight\n9 Nine\n10 Ten'),
        ),
      ),
    );
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

  testWidgets(
    'Reader Search dismisses on Listen and Scripture selection, then reopens',
    (tester) async {
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
            scriptureRepositoryFactory: (_) =>
                _TextScriptureRepository('1 One\n2 Two'),
          ),
        ),
      );
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
    },
  );

  testWidgets(
    'voice picker exposes every platform voice returned by audio service',
    (tester) async {
      final controller = AppController(
        repository: _MemoryPlanRepository(<ReadingPlan>[]),
        versionRepository: _InstalledKjvRepository(),
      );
      await controller.load();
      final voices = <TtsVoiceOption>[
        const TtsVoiceOption(
          key: 'en',
          name: 'English',
          locale: 'en-US',
          settings: <String, String>{},
          networkRequired: false,
        ),
        const TtsVoiceOption(
          key: 'fr',
          name: 'French',
          locale: 'fr-FR',
          settings: <String, String>{},
          networkRequired: false,
        ),
      ];
      final audio = _QueuedAudioService(voices: voices);
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
      await tester.tap(find.text('Listen'));
      await tester.pump();
      await tester.tap(find.text('English (en-US)'));
      await tester.pumpAndSettle();
      expect(find.text('French (fr-FR)'), findsOneWidget);
    },
  );
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
  int saveCalls = 0;

  @override
  Future<List<ReadingPlan>> loadPlans() async => List<ReadingPlan>.from(plans);

  @override
  Future<void> savePlans(List<ReadingPlan> plans) async {
    saveCalls++;
    this.plans = List<ReadingPlan>.from(plans);
  }
}

class _FailingPlanRepository extends _MemoryPlanRepository {
  _FailingPlanRepository() : super([]);
  bool fail = true;
  @override
  Future<void> savePlans(List<ReadingPlan> plans) async {
    if (fail) throw StateError('Synthetic write failure');
    await super.savePlans(plans);
  }
}

class _DelayedPlanRepository extends _MemoryPlanRepository {
  _DelayedPlanRepository(super.plans);
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> savePlans(List<ReadingPlan> plans) async {
    if (!started.isCompleted) {
      started.complete();
      await release.future;
    }
    await super.savePlans(plans);
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
  Future<ScriptureTextResult> getPassage(ScriptureReference reference) async =>
      ScriptureTextResult(reference: reference.display, text: text);
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
