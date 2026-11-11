import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/word/plans/data/local/word_plan_dao.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/models/scripture_reference.dart';
import 'package:scripture_planner/src/services/plan_scheduler.dart';
import 'generated_migrations/schema.dart';

const one = ScriptureReference(book: 'Genesis', startChapter: 1);
const two = ScriptureReference(book: 'Genesis', startChapter: 2);
const three = ScriptureReference(book: 'Genesis', startChapter: 3);
ReadingPlan fixture() {
  final date = DateTime(2026, 10, 5);
  return ReadingPlan(
    id: '123e4567-e89b-42d3-a456-426614174000',
    title: 'Chapters',
    defaultTranslation: BibleTranslation.kjv,
    createdAt: date,
    startDate: date,
    endDate: date.add(const Duration(days: 3)),
    readingWeekdays: {1, 2, 3, 4, 5, 6, 7},
    reminderTime: '07:00',
    sourceReferences: const [one, two, three],
    assignments: [
      ScheduledReading(date: date, references: const [one, two, three]),
    ],
  );
}

void main() {
  test(
    'idempotent chapter progress preserves skipped chapters and completed legacy days',
    () {
      var day = fixture().assignments.single.completeChapter(three);
      expect(day.completed, false);
      expect(day.completedChapterCount, 1);
      expect(day.completeChapter(three).completedChapterCount, 1);
      expect(day.isChapterCompleted(one), false);
      day = day.completeChapter(one).completeChapter(two);
      expect(day.completed, true);
      expect(day.completedChapterCount, 3);
      expect(
        fixture().assignments.single
            .copyWith(completed: true)
            .completedChapterCount,
        3,
      );
      expect(
        () => day.completeChapter(
          const ScriptureReference(book: 'John', startChapter: 1),
        ),
        throwsArgumentError,
      );
      expect(ScheduledReading.fromJson(day.toJson()).completedChapterCount, 3);
    },
  );
  test(
    'partial chapter progress survives reopen and failed replacement rolls back',
    () async {
      final dir = await Directory.systemTemp.createTemp('newman-chapters-');
      final file = File('${dir.path}/test.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      try {
        final plan = fixture().copyWith(
          assignments: [fixture().assignments.single.completeChapter(two)],
          lastReadLocation: one,
          lastReadAssignmentHint: 0,
        );
        await WordPlanDao(db).replacePlans([plan]);
        await db.close();
        db = AppDatabase(NativeDatabase(file));
        final restored = (await WordPlanDao(db).loadPlans()).single;
        expect(restored.assignments.single.completedChapterCount, 1);
        expect(restored.progress, closeTo(1 / 3, .0001));
        expect(restored.lastReadLocation?.display, one.display);
        await db.customStatement(
          "CREATE TRIGGER reject_test BEFORE INSERT ON bible_plan_schedule_entries BEGIN SELECT RAISE(ABORT, 'test failure'); END",
        );
        await expectLater(
          WordPlanDao(
            db,
          ).replacePlans([restored.copyWith(title: 'Must roll back')]),
          throwsA(anything),
        );
        expect((await WordPlanDao(db).loadPlans()).single.title, 'Chapters');
        expect(
          (await WordPlanDao(
            db,
          ).loadPlans()).single.assignments.single.completedChapterCount,
          1,
        );
        await db.customStatement('DROP TRIGGER reject_test');
        await WordPlanDao(db).replacePlans([restored.copyWith(title: 'Retry')]);
        expect(
          (await WordPlanDao(
            db,
          ).loadPlans()).single.assignments.single.completedChapterCount,
          1,
        );
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
  test(
    'rescheduling preserves partial chapters instead of resetting progress',
    () {
      final original = fixture();
      final plan = original.copyWith(
        assignments: [original.assignments.single.completeChapter(two)],
      );
      final changed = PlanScheduler().rescheduleUnfinished(
        plan: plan,
        startDate: plan.startDate,
        endDate: plan.endDate,
        readingWeekdays: plan.readingWeekdays,
      );
      expect(
        changed.fold<int>(0, (sum, day) => sum + day.completedChapterCount),
        1,
      );
      expect(
        changed
            .expand((day) => day.chapters.where(day.isChapterCompleted))
            .single
            .display,
        two.display,
      );
    },
  );
  for (var version = 1; version <= 8; version++) {
    test('v$version upgrade preserves completed and unfinished day rows', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(version);
      schema.rawDatabase.execute(
        "INSERT INTO bible_plans (id, position, title, default_translation_id, created_at_utc_micros, start_date, end_date, reading_weekdays_mask, reminder_minutes_local) VALUES ('123e4567-e89b-42d3-a456-426614174000', 0, 'Legacy', 'kjv', 1, '2026-10-05', '2026-10-06', 127, 420)",
      );
      for (var i = 0; i < 2; i++) {
        schema.rawDatabase.execute(
          "INSERT INTO bible_plan_schedule_entries (id, plan_id, position, scheduled_date, is_completed) VALUES ('day$i', '123e4567-e89b-42d3-a456-426614174000', $i, '2026-10-05', ${i == 0 ? 1 : 0})",
        );
        schema.rawDatabase.execute(
          "INSERT INTO bible_plan_schedule_items (id, schedule_entry_id, position, book, start_chapter, end_chapter) VALUES ('item$i', 'day$i', 0, 'Genesis', 1, 3)",
        );
      }
      final db = AppDatabase(schema.newConnection());
      try {
        await verifier.migrateAndValidate(db, 10);
        final plan = (await WordPlanDao(db).loadPlans()).single;
        expect(plan.assignments.map((day) => day.completedChapterCount), [
          3,
          0,
        ]);
        expect(
          plan.assignments.map((day) => day.completedChapterKeys),
          everyElement(isEmpty),
        );
        expect(plan.title, 'Legacy');
      } finally {
        await db.close();
      }
    });
  }
}
