import 'package:uuid/uuid.dart';

import '../../../bible/domain/scripture_reference.dart';
import '../../../translations/domain/bible_translation.dart';
import '../../domain/reading_plan.dart';

/// Side-effect-free legacy-to-schema projection. NM0.4 owns database IO.
class LegacyWordMigrationProjection {
  LegacyWordMigrationProjection({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static final _namespace = Namespace.url.value;
  final Uuid _uuid;

  ProjectedWordData projectPlans(List<ReadingPlan> plans) {
    final seenLegacyIds = <String>{};
    final planRows = <BiblePlanRow>[];
    final sourceRows = <BiblePlanReferenceRow>[];
    final entryRows = <BiblePlanScheduleEntryRow>[];
    final itemRows = <BiblePlanReferenceRow>[];
    for (final plan in plans) {
      if (!seenLegacyIds.add(plan.id)) {
        throw FormatException('Duplicate legacy plan id: ${plan.id}');
      }
      final validUuid = _isUuid(plan.id);
      final planId = validUuid
          ? plan.id.toLowerCase()
          : _uuid.v5(_namespace, 'new-man/legacy-plan/${plan.id}');
      planRows.add(
        BiblePlanRow(
          id: planId,
          legacyId: validUuid ? null : plan.id,
          title: plan.title,
          defaultTranslationId: plan.defaultTranslation.name,
          createdAtUtcMicros: plan.createdAt.toUtc().microsecondsSinceEpoch,
          startDate: _dateOnly(plan.startDate),
          endDate: _dateOnly(plan.endDate),
          readingWeekdaysMask: _weekdayMask(plan.readingWeekdays),
          reminderMinutesLocal: _reminderMinutes(plan.reminderTime),
          templateId: plan.templateId,
        ),
      );
      for (var index = 0; index < plan.sourceReferences.length; index++) {
        sourceRows.add(
          _referenceRow(
            id: _uuid.v5(_namespace, '$planId/source/$index'),
            ownerId: planId,
            position: index,
            reference: plan.sourceReferences[index],
          ),
        );
      }
      for (var index = 0; index < plan.assignments.length; index++) {
        final assignment = plan.assignments[index];
        final entryId = _uuid.v5(_namespace, '$planId/schedule/$index');
        entryRows.add(
          BiblePlanScheduleEntryRow(
            id: entryId,
            planId: planId,
            position: index,
            scheduledDate: _dateOnly(assignment.date),
            isCompleted: assignment.completed,
            completedAtUtcMicros: null,
            translationOverrideId: assignment.translationOverride?.name,
          ),
        );
        for (var item = 0; item < assignment.references.length; item++) {
          itemRows.add(
            _referenceRow(
              id: _uuid.v5(_namespace, '$entryId/item/$item'),
              ownerId: entryId,
              position: item,
              reference: assignment.references[item],
            ),
          );
        }
      }
    }
    return ProjectedWordData(
      plans: planRows,
      sourceItems: sourceRows,
      scheduleEntries: entryRows,
      scheduleItems: itemRows,
    );
  }

  List<WordTranslationStateRow> projectTranslationStates(
    List<String> storedNames, {
    required bool verifiedCompleteKjvFile,
  }) {
    final translations = storedNames
        .map(BibleTranslation.values.byName)
        .toSet();
    return [
      if (verifiedCompleteKjvFile)
        const WordTranslationStateRow('kjv', 'offline', 'installed'),
      if (translations.contains(BibleTranslation.nlt))
        const WordTranslationStateRow('nlt', 'online', 'enabled'),
    ];
  }

  BiblePlanReferenceRow _referenceRow({
    required String id,
    required String ownerId,
    required int position,
    required ScriptureReference reference,
  }) => BiblePlanReferenceRow(
    id: id,
    ownerId: ownerId,
    position: position,
    book: reference.book,
    startChapter: reference.startChapter,
    startVerse: reference.startVerse,
    endChapter: reference.endChapter,
    endVerse: reference.endVerse,
  );

  static bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  static int _weekdayMask(Set<int> weekdays) {
    if (weekdays.any((day) => day < 1 || day > 7)) {
      throw const FormatException('Reading weekdays must be between 1 and 7.');
    }
    return weekdays.fold(0, (mask, day) => mask | (1 << (day - 1)));
  }

  static int _reminderMinutes(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    final hour = match == null ? -1 : int.parse(match.group(1)!);
    final minute = match == null ? -1 : int.parse(match.group(2)!);
    if (hour > 23 || minute > 59 || hour < 0 || minute < 0) {
      throw FormatException('Invalid local reminder time: $value');
    }
    return hour * 60 + minute;
  }
}

class ProjectedWordData {
  const ProjectedWordData({
    required this.plans,
    required this.sourceItems,
    required this.scheduleEntries,
    required this.scheduleItems,
  });
  final List<BiblePlanRow> plans;
  final List<BiblePlanReferenceRow> sourceItems;
  final List<BiblePlanScheduleEntryRow> scheduleEntries;
  final List<BiblePlanReferenceRow> scheduleItems;
}

class BiblePlanRow {
  const BiblePlanRow({
    required this.id,
    required this.legacyId,
    required this.title,
    required this.defaultTranslationId,
    required this.createdAtUtcMicros,
    required this.startDate,
    required this.endDate,
    required this.readingWeekdaysMask,
    required this.reminderMinutesLocal,
    required this.templateId,
  });
  final String id;
  final String? legacyId;
  final String title;
  final String defaultTranslationId;
  final int createdAtUtcMicros;
  final String startDate;
  final String endDate;
  final int readingWeekdaysMask;
  final int reminderMinutesLocal;
  final String? templateId;
}

class BiblePlanReferenceRow {
  const BiblePlanReferenceRow({
    required this.id,
    required this.ownerId,
    required this.position,
    required this.book,
    required this.startChapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
  });
  final String id;
  final String ownerId;
  final int position;
  final String book;
  final int startChapter;
  final int? startVerse;
  final int? endChapter;
  final int? endVerse;
}

class BiblePlanScheduleEntryRow {
  const BiblePlanScheduleEntryRow({
    required this.id,
    required this.planId,
    required this.position,
    required this.scheduledDate,
    required this.isCompleted,
    required this.completedAtUtcMicros,
    required this.translationOverrideId,
  });
  final String id;
  final String planId;
  final int position;
  final String scheduledDate;
  final bool isCompleted;
  final int? completedAtUtcMicros;
  final String? translationOverrideId;
}

class WordTranslationStateRow {
  const WordTranslationStateRow(
    this.translationId,
    this.accessMode,
    this.state,
  );
  final String translationId;
  final String accessMode;
  final String state;
}
