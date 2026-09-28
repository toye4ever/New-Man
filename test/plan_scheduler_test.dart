import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/controllers/app_controller.dart';
import 'package:scripture_planner/src/models/scripture_reference.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';
import 'package:scripture_planner/src/services/plan_repository.dart';
import 'package:scripture_planner/src/features/word/translations/domain/translation_state.dart';
import 'package:scripture_planner/src/services/plan_scheduler.dart';

void main() {
  test('schedules only selected weekdays through an end date', () {
    final scheduler = PlanScheduler();
    final assignments = scheduler.generate(
      references: const <ScriptureReference>[
        ScriptureReference(book: 'Matthew', startChapter: 5),
        ScriptureReference(book: 'Matthew', startChapter: 15),
        ScriptureReference(book: 'Matthew', startChapter: 18),
      ],
      startDate: DateTime(2026, 7, 27), // Monday
      endDate: DateTime(2026, 7, 31), // Friday
      readingWeekdays: <int>{
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      },
    );

    expect(assignments.map((item) => item.date.weekday), <int>[
      DateTime.monday,
      DateTime.wednesday,
      DateTime.friday,
    ]);
    expect(assignments.expand((item) => item.references), hasLength(3));
  });

  test('expands chapter ranges before balancing', () {
    final scheduler = PlanScheduler();
    final assignments = scheduler.generate(
      references: const <ScriptureReference>[
        ScriptureReference(book: 'John', startChapter: 1, endChapter: 3),
      ],
      startDate: DateTime(2026, 7, 27),
      endDate: DateTime(2026, 7, 29),
      readingWeekdays: <int>{
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
      },
    );

    expect(assignments, hasLength(3));
    expect(assignments[0].references.single.display, 'John 1');
    expect(assignments[2].references.single.display, 'John 3');
  });

  test('spreads a short plan across the full date range', () {
    final scheduler = PlanScheduler();
    final assignments = scheduler.generate(
      references: const <ScriptureReference>[
        ScriptureReference(book: 'Matthew', startChapter: 5),
        ScriptureReference(book: 'Matthew', startChapter: 15),
        ScriptureReference(book: 'Matthew', startChapter: 18),
      ],
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
      readingWeekdays: <int>{
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      },
    );

    expect(assignments.first.date, DateTime(2026, 8, 1));
    expect(assignments.last.date, DateTime(2026, 8, 31));
  });

  test('rescheduling preserves completed history and redistributes only unfinished readings', () {
    final scheduler = PlanScheduler();
    final completed = ScheduledReading(
      date: DateTime(2026, 8, 3),
      completed: true,
      references: const <ScriptureReference>[
        ScriptureReference(book: 'John', startChapter: 1),
      ],
    );
    final plan = ReadingPlan(
      id: 'plan',
      title: 'Plan',
      defaultTranslation: BibleTranslation.kjv,
      createdAt: DateTime(2026, 8, 1),
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 14),
      readingWeekdays: <int>{DateTime.monday, DateTime.friday},
      reminderTime: '07:00',
      sourceReferences: const <ScriptureReference>[
        ScriptureReference(book: 'John', startChapter: 1),
        ScriptureReference(book: 'John', startChapter: 2),
        ScriptureReference(book: 'John', startChapter: 3),
      ],
      assignments: <ScheduledReading>[
        completed,
        ScheduledReading(
          date: DateTime(2026, 8, 5),
          references: const <ScriptureReference>[
            ScriptureReference(book: 'John', startChapter: 2),
          ],
        ),
        ScheduledReading(
          date: DateTime(2026, 8, 7),
          references: const <ScriptureReference>[
            ScriptureReference(book: 'John', startChapter: 3),
          ],
        ),
      ],
    );

    final preview = scheduler.rescheduleUnfinished(
      plan: plan,
      startDate: DateTime(2026, 8, 7),
      endDate: plan.endDate,
      readingWeekdays: plan.readingWeekdays,
    );

    expect(preview.where((item) => item.completed).single.date, completed.date);
    expect(
      preview.expand((item) => item.references).map((item) => item.display),
      <String>['John 1', 'John 2', 'John 3'],
    );
    expect(
      preview.where((item) => !item.completed).map((item) => item.date.weekday),
      everyElement(anyOf(DateTime.monday, DateTime.friday)),
    );
  });

  test('Catch Me Up preview is non-mutating until explicitly applied', () async {
    final plan = ReadingPlan(
      id: 'catch-up',
      title: 'Catch up',
      defaultTranslation: BibleTranslation.kjv,
      createdAt: DateTime(2026, 8, 1),
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 14),
      readingWeekdays: <int>{DateTime.monday, DateTime.friday},
      reminderTime: '07:00',
      sourceReferences: const <ScriptureReference>[
        ScriptureReference(book: 'Romans', startChapter: 1),
        ScriptureReference(book: 'Romans', startChapter: 2),
      ],
      assignments: <ScheduledReading>[
        ScheduledReading(
          date: DateTime(2026, 8, 3),
          completed: true,
          references: const <ScriptureReference>[
            ScriptureReference(book: 'Romans', startChapter: 1),
          ],
        ),
        ScheduledReading(
          date: DateTime(2026, 8, 5),
          references: const <ScriptureReference>[
            ScriptureReference(book: 'Romans', startChapter: 2),
          ],
        ),
      ],
    );
    final repository = _MemoryPlanRepository(<ReadingPlan>[plan]);
    final controller = AppController(
      repository: repository,
      versionRepository: _VersionRepository(),
    );
    await controller.load();

    final preview = controller.previewCatchUpPlan(
      plan.id,
      fromDate: DateTime(2026, 8, 7),
    );

    expect(controller.plans.single.assignments[1].date, DateTime(2026, 8, 5));
    expect(repository.saveCalls, 0);
    expect(preview.targetEndDate, plan.endDate);
    expect(preview.assignments.where((item) => item.completed).single.date,
        DateTime(2026, 8, 3));

    await controller.applyCatchUpPreview(preview);
    expect(repository.saveCalls, 1);
    expect(controller.plans.single.endDate, plan.endDate);
    expect(
      controller.plans.single.assignments
          .where((item) => !item.completed)
          .single
          .date,
      DateTime(2026, 8, 7),
    );
  });
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

class _VersionRepository extends BibleVersionRepository {
  @override
  Future<TranslationRepositoryState> loadTranslationState() async =>
      const TranslationRepositoryState(
        installations: <BibleTranslation, TranslationInstallationState>{},
        onlineEnabled: <BibleTranslation>{},
      );
}
