import 'dart:io';
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
      const TranslationRepositoryState(installations: {}, onlineEnabled: {});
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
