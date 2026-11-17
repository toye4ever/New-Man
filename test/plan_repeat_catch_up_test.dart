import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scripture_planner/src/models/plan_template.dart';
import 'package:scripture_planner/src/screens/create_plan_screen.dart';
import 'package:scripture_planner/src/screens/plan_details_screen.dart';
import 'package:scripture_planner/src/screens/reader_screen.dart';
import 'package:scripture_planner/src/features/word/bible/application/bible_reader_request.dart';
import 'package:scripture_planner/src/services/scripture_service.dart';
import 'package:scripture_planner/src/services/plan_scheduler.dart';
import 'package:scripture_planner/src/features/word/audio/application/bible_audio_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/controllers/app_controller.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/word/plans/data/drift_plan_repository.dart';
import 'package:scripture_planner/src/features/word/plans/data/local/word_plan_dao.dart';
import 'package:scripture_planner/src/features/word/translations/domain/translation_state.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/models/scripture_reference.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';

const one = ScriptureReference(book: 'Genesis', startChapter: 1);
const two = ScriptureReference(book: 'Genesis', startChapter: 2);
final firstDay = DateTime(2026, 11, 16);
final lastDay = DateTime(2026, 11, 17);
ReadingPlan repeatedPlan({String id = 'synthetic-repeat'}) => ReadingPlan(
  id: id,
  title: 'Synthetic repeated readings',
  defaultTranslation: BibleTranslation.kjv,
  createdAt: DateTime.utc(2026),
  startDate: firstDay,
  endDate: lastDay,
  readingWeekdays: {1, 2, 3, 4, 5, 6, 7},
  reminderTime: '07:00',
  sourceReferences: [one, two, one],
  assignments: [
    ScheduledReading(
      date: firstDay,
      references: [one, two],
      completedChapterKeys: {'Genesis:1'},
    ),
    ScheduledReading(date: lastDay, references: [one]),
  ],
);
List<bool> firstChapterProgress(Iterable<ScheduledReading> days) => [
  for (final day in days)
    for (final chapter in day.chapters)
      if (chapter.startChapter == 1) day.isChapterCompleted(chapter),
];

class _Versions extends BibleVersionRepository {
  @override
  Future<TranslationRepositoryState> loadTranslationState() async =>
      const TranslationRepositoryState(
        installations: {
          BibleTranslation.kjv: TranslationInstallationState(
            status: TranslationInstallationStatus.installed,
          ),
        },
        onlineEnabled: {},
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late AppDatabase db;
  late AppController controller;
  Future<void> open() async {
    db = AppDatabase(
      NativeDatabase(File('${directory.path}/synthetic.sqlite')),
    );
    controller = AppController(
      repository: DriftPlanRepository(WordPlanDao(db)),
      versionRepository: _Versions(),
    );
    await controller.load();
  }

  Future<void> close() async {
    controller.versionRepository.dispose();
    controller.dispose();
    await db.close();
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'synthetic-plan-occurrences-',
    );
    await open();
    await controller.savePlan(repeatedPlan());
  });
  tearDown(() async {
    await close();
    await directory.delete(recursive: true);
  });
  testWidgets(
    'actual one-date creation displays and persists independently readable repeats',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> waitFor(bool Function() ready) async {
        for (var i = 0; i < 200; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump(const Duration(milliseconds: 16));
          if (ready() && !tester.binding.hasScheduledFrame) break;
        }
        expect(ready(), isTrue);
        await tester.pumpAndSettle();
      }

      var saved = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreatePlanScreen(
              controller: controller,
              planToEdit: null,
              template: const PlanTemplate(
                id: 'synthetic-short-repeat',
                title: 'Synthetic new repeated plan',
                description: 'Synthetic',
                defaultDurationDays: 1,
                references: [one, two, one],
                iconName: 'book',
              ),
              onSaved: () => saved = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Preview schedule'));
      await tester.tap(find.text('Preview schedule'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Apply schedule'));
      await waitFor(() => saved);
      final created = controller.plans.singleWhere(
        (p) => p.title == 'Synthetic new repeated plan',
      );
      final id = created.id;
      expect(created.startDate, created.endDate);
      expect(created.totalChapterCount, 3);
      expect(
        [
          for (final ref in created.sourceReferences)
            for (var c = ref.startChapter; c <= ref.resolvedEndChapter; c++) c,
        ],
        [1, 2, 1],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanDetailsScreen(controller: controller, planId: id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0/3 chapters'), findsOneWidget);
      expect(created.assignments, hasLength(2));
      expect(created.assignments.map((r) => r.date).toSet(), {
        created.startDate,
      });
      expect(
        created.assignments
            .expand((r) => r.references)
            .map((r) => r.startChapter),
        [1, 2, 1],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReaderScreen(
            controller: controller,
            request: BibleReaderRequest.fromPlanReading(
              references: created.assignments.first.references,
              initialTranslation: BibleTranslation.kjv,
              planId: id,
              assignmentIndex: 0,
            ),
            audio: _SilentAudio(),
            scriptureRepositoryFactory: (_) => _SyntheticScripture(),
          ),
        ),
      );
      await waitFor(
        () => find.text('1 Synthetic chapter 1').evaluate().isNotEmpty,
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Genesis 2'));
      await waitFor(
        () => find.text('1 Synthetic chapter 2').evaluate().isNotEmpty,
      );
      final progressed = controller.plans.singleWhere((p) => p.id == id);
      expect(firstChapterProgress(progressed.assignments), [true, false]);
      expect(progressed.assignments.first.isChapterCompleted(two), isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await close();
        await open();
      });
      final reloaded = controller.plans.singleWhere((p) => p.id == id);
      expect(firstChapterProgress(reloaded.assignments), [true, false]);
      await tester.runAsync(() async {
        final preview = controller.previewCatchUpPlan(
          id,
          fromDate: reloaded.startDate,
        );
        expect(firstChapterProgress(preview.assignments), [true, false]);
        await controller.applyCatchUpPreview(preview);
        await close();
        await open();
      });
      expect(
        firstChapterProgress(
          controller.plans.singleWhere((p) => p.id == id).assignments,
        ),
        [true, false],
      );
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'one-date ordinary grouping and intentional chapter fragments remain grouped',
    () {
      final scheduler = PlanScheduler();
      final normal = scheduler.generate(
        references: [one, two],
        startDate: firstDay,
        endDate: firstDay,
        readingWeekdays: {1, 2, 3, 4, 5, 6, 7},
      );
      expect(normal, hasLength(1));
      final fragments = scheduler.generate(
        references: const [
          ScriptureReference(book: 'Matthew', startChapter: 5, startVerse: 1),
          ScriptureReference(book: 'Matthew', startChapter: 5, startVerse: 3),
        ],
        startDate: firstDay,
        endDate: firstDay,
        readingWeekdays: {1, 2, 3, 4, 5, 6, 7},
      );
      expect(fragments, hasLength(1));
      expect(fragments.single.references, hasLength(2));
      expect(fragments.single.chapters, hasLength(1));
    },
  );

  for (final remainingDays in [2, 1]) {
    test(
      'Catch Me Up preserves repeated chapter occurrence through apply and SQLite reopen days=$remainingDays',
      () async {
        final preview = controller.previewCatchUpPlan(
          'synthetic-repeat',
          fromDate: remainingDays == 2 ? firstDay : lastDay,
        );
        expect(firstChapterProgress(preview.assignments), [true, false]);
        expect(firstChapterProgress(controller.plans.single.assignments), [
          true,
          false,
        ]);
        expect(
          preview.assignments
              .expand((r) => r.references)
              .map((r) => r.startChapter),
          [1, 2, 1],
        );
        if (remainingDays == 1) expect(preview.assignments, hasLength(2));
        await controller.applyCatchUpPreview(preview);
        await close();
        await open();
        expect(firstChapterProgress(controller.plans.single.assignments), [
          true,
          false,
        ]);
        expect(controller.plans.single.completedChapterCount, 1);
      },
    );
  }
  test(
    'completed reading stays separate from an unfinished identical chapter',
    () async {
      final plan = repeatedPlan().copyWith(
        assignments: [
          ScheduledReading(date: firstDay, references: [one], completed: true),
          ScheduledReading(date: lastDay, references: [one, two]),
        ],
      );
      await controller.savePlan(plan);
      final preview = controller.previewCatchUpPlan(plan.id, fromDate: lastDay);
      expect(firstChapterProgress(preview.assignments), [true, false]);
      await controller.applyCatchUpPreview(preview);
      await close();
      await open();
      expect(firstChapterProgress(controller.plans.single.assignments), [
        true,
        false,
      ]);
    },
  );
  for (final swap in [false, true]) {
    test(
      'stale preview rejects progress on a different repeat with unchanged global keys swap=$swap',
      () async {
        final preview = controller.previewCatchUpPlan(
          'synthetic-repeat',
          fromDate: firstDay,
        );
        if (swap) {
          final plan = controller.plans.single;
          await controller.savePlan(
            plan.copyWith(
              assignments: [
                plan.assignments.first.copyWith(completedChapterKeys: {}),
                plan.assignments.last.copyWith(completed: true),
              ],
            ),
          );
        } else {
          await controller.completePlanChapter('synthetic-repeat', 1, one);
        }
        final before = firstChapterProgress(
          controller.plans.single.assignments,
        );
        await expectLater(
          controller.applyCatchUpPreview(preview),
          throwsStateError,
        );
        expect(
          firstChapterProgress(controller.plans.single.assignments),
          before,
        );
        await close();
        await open();
        expect(
          firstChapterProgress(controller.plans.single.assignments),
          before,
        );
      },
    );
  }
  test(
    'later completed assignment keeps its own occurrence during regrouping',
    () async {
      final original = repeatedPlan();
      final history = ScheduledReading(
        date: lastDay,
        references: [one],
        completed: true,
      );
      await controller.savePlan(
        original.copyWith(
          assignments: [
            ScheduledReading(
              date: firstDay,
              references: [one, two],
              completedChapterKeys: {'Genesis:2'},
            ),
            history,
          ],
        ),
      );
      final preview = controller.previewCatchUpPlan(
        original.id,
        fromDate: lastDay,
      );
      expect(preview.assignments.first, same(history));
      expect(firstChapterProgress(preview.assignments), [true, false]);
      expect(preview.assignments.last.isChapterCompleted(two), isTrue);
      await controller.applyCatchUpPreview(preview);
      await close();
      await open();
      expect(firstChapterProgress(controller.plans.single.assignments), [
        true,
        false,
      ]);
      expect(
        controller.plans.single.assignments.last.isChapterCompleted(two),
        isTrue,
      );
    },
  );
  test(
    'canonical UUID plan retains repeat progress through SQLite reopen',
    () async {
      const id = '11111111-1111-4111-8111-111111111111';
      await controller.savePlan(repeatedPlan(id: id));
      final preview = controller.previewCatchUpPlan(id, fromDate: lastDay);
      await controller.applyCatchUpPreview(preview);
      await close();
      await open();
      expect(
        firstChapterProgress(
          controller.plans.singleWhere((p) => p.id == id).assignments,
        ),
        [true, false],
      );
    },
  );
  test(
    'apply rejects an altered preview that inflates only a repeat',
    () async {
      final preview = controller.previewCatchUpPlan(
        'synthetic-repeat',
        fromDate: firstDay,
      );
      preview.assignments[1] = preview.assignments[1].copyWith(
        completed: true,
        completedChapterKeys: {'Genesis:1'},
      );
      await expectLater(
        controller.applyCatchUpPreview(preview),
        throwsStateError,
      );
      expect(firstChapterProgress(controller.plans.single.assignments), [
        true,
        false,
      ]);
    },
  );

  test(
    'ambiguous legacy repeated chapter within one partial reading is not guessed',
    () async {
      final plan = repeatedPlan().copyWith(
        assignments: [
          ScheduledReading(
            date: firstDay,
            references: [one, two, one],
            completedChapterKeys: {'Genesis:1'},
          ),
        ],
      );
      await controller.savePlan(plan);
      expect(
        () => controller.previewCatchUpPlan(plan.id, fromDate: firstDay),
        throwsArgumentError,
      );
      expect(
        controller.plans.single.assignments.single.references,
        hasLength(3),
      );
    },
  );
}

class _SyntheticScripture implements ScriptureRepository {
  @override
  Future<ScriptureTextResult> getPassage(ScriptureReference ref) async =>
      ScriptureTextResult(
        reference: ref.display,
        text: '1 Synthetic chapter ${ref.startChapter}',
      );
}

class _SilentAudio implements BibleAudioService {
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
  Future<void> speak(String text) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async {}
}
