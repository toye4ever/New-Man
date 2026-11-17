import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/controllers/app_controller.dart';
import 'package:scripture_planner/src/models/scripture_reference.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';
import 'package:scripture_planner/src/services/plan_repository.dart';
import 'package:scripture_planner/src/features/word/translations/domain/translation_state.dart';
import 'package:scripture_planner/src/services/plan_scheduler.dart';

void main() {
  // Run also with TZ=America/New_York: these ranges cross both DST changes.
  for (final start in [
    DateTime(2026, 7, 27),
    DateTime(2026, 3, 7),
    DateTime(2026, 10, 31),
  ]) {
    final dates = [
      for (var i = 0; i < 3; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
    for (final weekdays in [
      <int>{1, 2, 3, 4, 5, 6, 7},
      <int>{dates.first.weekday, dates.last.weekday},
    ]) {
      test(
        'calendar scheduling and catch-up $start weekdays $weekdays',
        () async {
          const refs = <ScriptureReference>[
            ScriptureReference(book: 'John', startChapter: 1, endChapter: 3),
          ];
          final expected = dates
              .where((d) => weekdays.contains(d.weekday))
              .toList();
          final scheduled = PlanScheduler().generate(
            references: refs,
            startDate: start,
            endDate: dates.last,
            readingWeekdays: weekdays,
          );
          expect(scheduled.map((a) => a.date), expected);
          expect(
            scheduled.expand((a) => a.references).map((r) => r.startChapter),
            [1, 2, 3],
          );
          final original = ScheduledReading(date: start, references: refs);
          final plan = ReadingPlan(
            id: 'synthetic-dst',
            title: 'Synthetic',
            defaultTranslation: BibleTranslation.kjv,
            createdAt: DateTime.utc(2026),
            startDate: start,
            endDate: dates.last,
            readingWeekdays: weekdays,
            reminderTime: '07:00',
            sourceReferences: refs,
            assignments: [original],
          );
          final repository = _MemoryPlanRepository([plan]);
          final controller = AppController(
            repository: repository,
            versionRepository: _VersionRepository(),
          );
          addTearDown(controller.dispose);
          await controller.load();
          final preview = controller.previewCatchUpPlan(
            plan.id,
            fromDate: start,
          );
          expect(preview.eligibleDayCount, expected.length);
          expect(preview.assignments.map((a) => a.date), expected);
          expect(repository.saveCalls, 0);
          expect(controller.plans.single.assignments.single, same(original));
          expect(controller.plans.single.createdAt, DateTime.utc(2026));
        },
      );
    }
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

class _VersionRepository extends BibleVersionRepository {
  @override
  Future<TranslationRepositoryState> loadTranslationState() async =>
      const TranslationRepositoryState(
        installations: <BibleTranslation, TranslationInstallationState>{},
        onlineEnabled: <BibleTranslation>{},
      );
}
