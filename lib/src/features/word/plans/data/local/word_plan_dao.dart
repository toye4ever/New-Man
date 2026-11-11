import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../../core/database/app_database.dart';
import '../../../bible/domain/scripture_reference.dart';
import '../../../translations/domain/bible_translation.dart';
import '../migration/legacy_word_migration_projection.dart';
import '../../domain/reading_plan.dart';

class WordPlanDao {
  const WordPlanDao(this.database);

  final AppDatabase database;

  Future<List<ReadingPlan>> loadPlans() async {
    final planRows = await (database.select(
      database.biblePlans,
    )..orderBy([(row) => OrderingTerm.asc(row.position)])).get();
    final plans = <ReadingPlan>[];
    for (final plan in planRows) {
      final sourceRows =
          await (database.select(database.biblePlanSourceItems)
                ..where((row) => row.planId.equals(plan.id))
                ..orderBy([(row) => OrderingTerm.asc(row.position)]))
              .get();
      final entryRows =
          await (database.select(database.biblePlanScheduleEntries)
                ..where((row) => row.planId.equals(plan.id))
                ..orderBy([(row) => OrderingTerm.asc(row.position)]))
              .get();
      final assignments = <ScheduledReading>[];
      for (final entry in entryRows) {
        final items =
            await (database.select(database.biblePlanScheduleItems)
                  ..where((row) => row.scheduleEntryId.equals(entry.id))
                  ..orderBy([(row) => OrderingTerm.asc(row.position)]))
                .get();
        assignments.add(
          ScheduledReading(
            date: _parseDate(entry.scheduledDate),
            references: items.map(_scheduleReference).toList(),
            completed: entry.isCompleted,
            completedChapterKeys: Set<String>.unmodifiable(
              entry.completedChapterKeysJson == null
                  ? const <String>[]
                  : (jsonDecode(entry.completedChapterKeysJson!)
                            as List<dynamic>)
                        .cast<String>(),
            ),
            translationOverride: entry.translationOverrideId == null
                ? null
                : BibleTranslation.values.byName(entry.translationOverrideId!),
          ),
        );
      }
      plans.add(
        ReadingPlan(
          id: plan.id,
          title: plan.title,
          defaultTranslation: BibleTranslation.values.byName(
            plan.defaultTranslationId,
          ),
          createdAt: DateTime.fromMicrosecondsSinceEpoch(
            plan.createdAtUtcMicros,
            isUtc: true,
          ),
          startDate: _parseDate(plan.startDate),
          endDate: _parseDate(plan.endDate),
          readingWeekdays: _weekdays(plan.readingWeekdaysMask),
          reminderTime: _reminder(plan.reminderMinutesLocal),
          sourceReferences: sourceRows.map(_sourceReference).toList(),
          assignments: assignments,
          templateId: plan.templateId,
          lastReadAssignmentHint: plan.lastReadLocationJson == null
              ? null
              : (jsonDecode(plan.lastReadLocationJson!)
                        as Map<String, dynamic>)['assignmentIndex']
                    as int?,
          lastReadLocation: plan.lastReadLocationJson == null
              ? null
              : ScriptureReference.fromJson(
                  jsonDecode(plan.lastReadLocationJson!)
                      as Map<String, dynamic>,
                ),
        ),
      );
    }
    return plans;
  }

  Future<void> replacePlans(List<ReadingPlan> plans) async {
    final projection = LegacyWordMigrationProjection().projectPlans(plans);
    await database.transaction(() async {
      final legacyIds = {
        for (final row in await database.select(database.biblePlans).get())
          row.id: row.legacyId,
      };
      await _clearPlans();
      await insertProjected(
        projection,
        retainedLegacyIds: legacyIds,
        resumeLocations: {
          for (final plan in plans) plan.id: plan.lastReadLocation,
        },
        resumeAssignmentHints: {
          for (final plan in plans) plan.id: plan.lastReadAssignmentHint,
        },
        chapterProgress: {
          for (final plan in plans)
            plan.id: plan.assignments
                .map((day) => day.completedChapterKeys.toList()..sort())
                .toList(),
        },
      );
    });
  }

  Future<void> insertProjected(
    ProjectedWordData data, {
    Map<String, String?> retainedLegacyIds = const {},
    Map<String, ScriptureReference?> resumeLocations = const {},
    Map<String, int?> resumeAssignmentHints = const {},
    Map<String, List<List<String>>> chapterProgress = const {},
  }) async {
    for (var position = 0; position < data.plans.length; position++) {
      final row = data.plans[position];
      await database
          .into(database.biblePlans)
          .insert(
            BiblePlansCompanion.insert(
              id: row.id,
              legacyId: Value(row.legacyId ?? retainedLegacyIds[row.id]),
              position: position,
              title: row.title,
              defaultTranslationId: row.defaultTranslationId,
              createdAtUtcMicros: row.createdAtUtcMicros,
              startDate: row.startDate,
              endDate: row.endDate,
              readingWeekdaysMask: row.readingWeekdaysMask,
              reminderMinutesLocal: row.reminderMinutesLocal,
              templateId: Value(row.templateId),
              lastReadLocationJson: Value(
                resumeLocations[row.id] == null
                    ? null
                    : jsonEncode({
                        ...resumeLocations[row.id]!.toJson(),
                        'assignmentIndex': resumeAssignmentHints[row.id],
                      }),
              ),
            ),
          );
    }
    for (final row in data.sourceItems) {
      await database
          .into(database.biblePlanSourceItems)
          .insert(
            BiblePlanSourceItemsCompanion.insert(
              id: row.id,
              planId: row.ownerId,
              position: row.position,
              book: row.book,
              startChapter: row.startChapter,
              startVerse: Value(row.startVerse),
              endChapter: Value(row.endChapter),
              endVerse: Value(row.endVerse),
            ),
          );
    }
    for (final row in data.scheduleEntries) {
      await database
          .into(database.biblePlanScheduleEntries)
          .insert(
            BiblePlanScheduleEntriesCompanion.insert(
              id: row.id,
              planId: row.planId,
              position: row.position,
              scheduledDate: row.scheduledDate,
              isCompleted: row.isCompleted,
              completedChapterKeysJson: Value(
                chapterProgress[row.planId] == null
                    ? null
                    : jsonEncode(chapterProgress[row.planId]![row.position]),
              ),
              completedAtUtcMicros: Value(row.completedAtUtcMicros),
              translationOverrideId: Value(row.translationOverrideId),
            ),
          );
    }
    for (final row in data.scheduleItems) {
      await database
          .into(database.biblePlanScheduleItems)
          .insert(
            BiblePlanScheduleItemsCompanion.insert(
              id: row.id,
              scheduleEntryId: row.ownerId,
              position: row.position,
              book: row.book,
              startChapter: row.startChapter,
              startVerse: Value(row.startVerse),
              endChapter: Value(row.endChapter),
              endVerse: Value(row.endVerse),
            ),
          );
    }
  }

  Future<void> clearPlans() => _clearPlans();

  Future<void> _clearPlans() => database.delete(database.biblePlans).go();

  ScriptureReference _sourceReference(BiblePlanSourceItemRecord row) =>
      ScriptureReference(
        book: row.book,
        startChapter: row.startChapter,
        startVerse: row.startVerse,
        endChapter: row.endChapter,
        endVerse: row.endVerse,
      );

  ScriptureReference _scheduleReference(BiblePlanScheduleItemRecord row) =>
      ScriptureReference(
        book: row.book,
        startChapter: row.startChapter,
        startVerse: row.startVerse,
        endChapter: row.endChapter,
        endVerse: row.endVerse,
      );

  static DateTime _parseDate(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  static Set<int> _weekdays(int mask) => {
    for (var day = 1; day <= 7; day++)
      if ((mask & (1 << (day - 1))) != 0) day,
  };

  static String _reminder(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';
}
