import 'dart:collection';
import 'local_calendar.dart';
import '../../bible/domain/scripture_reference.dart';
import 'reading_plan.dart';

class PlanScheduler {
  /// Builds a schedule without changing a plan or persistence.
  List<ScheduledReading> preview({
    required List<ScriptureReference> references,
    required DateTime startDate,
    required DateTime endDate,
    required Set<int> readingWeekdays,
  }) => generate(
    references: references,
    startDate: startDate,
    endDate: endDate,
    readingWeekdays: readingWeekdays,
  );

  List<ScheduledReading> generate({
    required List<ScriptureReference> references,
    required DateTime startDate,
    required DateTime endDate,
    required Set<int> readingWeekdays,
  }) {
    if (references.isEmpty) {
      throw ArgumentError('At least one Scripture reference is required.');
    }

    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    if (normalizedEnd.isBefore(normalizedStart)) {
      throw ArgumentError('The end date cannot be before the start date.');
    }

    final weekdays = readingWeekdays.isEmpty
        ? <int>{
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday,
          }
        : readingWeekdays;

    final units = references.expand(_expandChapterRange).toList();
    final eligibleDates = _eligibleDates(
      startDate: normalizedStart,
      endDate: normalizedEnd,
      weekdays: weekdays,
    );

    if (eligibleDates.isEmpty) {
      throw ArgumentError(
        'There are no selected reading days between the start and end dates.',
      );
    }

    final sessionCount = units.length.clamp(1, eligibleDates.length).toInt();
    final dates = _spreadDates(eligibleDates, sessionCount);
    final baseSize = units.length ~/ sessionCount;
    final remainder = units.length % sessionCount;
    var cursor = 0;
    final assignments = <ScheduledReading>[];

    for (var index = 0; index < sessionCount; index++) {
      final size = baseSize + (index < remainder ? 1 : 0);
      final sessionReferences = units.sublist(cursor, cursor + size);
      cursor += size;
      assignments.add(
        ScheduledReading(date: dates[index], references: sessionReferences),
      );
    }

    return assignments;
  }

  List<ScheduledReading> redistributeRemaining({
    required ReadingPlan plan,
    required DateTime fromDate,
  }) {
    final completed = plan.assignments.where((item) => item.completed).toList();
    final remainingReferences = plan.assignments
        .where((item) => !item.completed)
        .expand((item) => item.references)
        .toList();

    if (remainingReferences.isEmpty) return plan.assignments;

    final today = DateTime(fromDate.year, fromDate.month, fromDate.day);
    if (today.isAfter(plan.endDate)) {
      throw ArgumentError(
        'The plan end date has passed. Edit the plan and choose a later end date first.',
      );
    }

    final rescheduled = generate(
      references: remainingReferences,
      startDate: today,
      endDate: plan.endDate,
      readingWeekdays: plan.readingWeekdays,
    );

    return _inDateOrder(<ScheduledReading>[
      ...completed,
      ...preserveCompletion(
        generated: rescheduled,
        previous: plan.assignments.where((day) => !day.completed).toList(),
      ),
    ]);
  }

  /// Regenerates only unfinished assignments. Completed assignments are kept
  /// intact as historical records, including their date and translation choice.
  List<ScheduledReading> rescheduleUnfinished({
    required ReadingPlan plan,
    required DateTime startDate,
    required DateTime endDate,
    required Set<int> readingWeekdays,
  }) {
    final completed = plan.assignments.where((item) => item.completed).toList();
    final unfinished = plan.assignments
        .where((item) => !item.completed)
        .expand((item) => item.references)
        .toList();
    if (unfinished.isEmpty) {
      return List<ScheduledReading>.from(plan.assignments);
    }

    final generated = generate(
      references: unfinished,
      startDate: startDate,
      endDate: endDate,
      readingWeekdays: readingWeekdays,
    );
    return _inDateOrder(<ScheduledReading>[
      ...completed,
      ...preserveCompletion(
        generated: generated,
        previous: plan.assignments.where((day) => !day.completed).toList(),
      ),
    ]);
  }

  List<ScheduledReading> preserveCompletion({
    required List<ScheduledReading> generated,
    required List<ScheduledReading> previous,
  }) {
    final progress = <String, Queue<bool>>{};
    final orderedKeys = <String>[];
    for (final reading in previous) {
      final fullChapters = <String>{};
      for (final ref in reading.references) {
        if (ref.startVerse != null || ref.endVerse != null) continue;
        for (final chapter in _expandChapterRange(ref)) {
          if (!fullChapters.add(ScheduledReading.chapterKey(chapter))) {
            throw ArgumentError(
              'Repeated chapters within one reading have ambiguous progress. Review the plan before rescheduling.',
            );
          }
        }
      }
      for (final chapter in reading.chapters) {
        final key = ScheduledReading.chapterKey(chapter);
        orderedKeys.add(key);
        progress
            .putIfAbsent(key, Queue<bool>.new)
            .add(reading.isChapterCompleted(chapter));
      }
    }
    final counts = {
      for (final entry in progress.entries) entry.key: entry.value.length,
    };
    // The persisted format has one completion flag per chapter per reading.
    // Keep repeated occurrences in separate same-date readings when regrouping.
    final separated = <ScheduledReading>[];
    for (final reading in generated) {
      var references = <ScriptureReference>[];
      final keys = <String>{};
      void flush() {
        if (references.isEmpty) return;
        separated.add(
          reading.copyWith(
            references: references,
            completed: false,
            completedChapterKeys: {},
          ),
        );
        references = <ScriptureReference>[];
        keys.clear();
      }

      for (final ref in reading.references) {
        final nextKeys = ScheduledReading(
          date: reading.date,
          references: [ref],
        ).chapters.map(ScheduledReading.chapterKey).toSet();
        if (nextKeys.any((key) => keys.contains(key) && (counts[key] ?? 0) > 1)) {
          flush();
        }
        references.add(ref);
        keys.addAll(nextKeys);
      }
      flush();
    }
    var cursor = 0;
    final result = <ScheduledReading>[];
    for (final reading in separated) {
      final completed = <String>{};
      for (final chapter in reading.chapters) {
        final key = ScheduledReading.chapterKey(chapter);
        if (cursor >= orderedKeys.length ||
            orderedKeys[cursor++] != key ||
            progress[key]!.isEmpty) {
          throw ArgumentError(
            'Reading occurrences cannot be matched in order. Review the plan before rescheduling.',
          );
        }
        if (progress[key]!.removeFirst()) completed.add(key);
      }
      result.add(
        reading.copyWith(
          completedChapterKeys: completed,
          completed:
              reading.chapters.isNotEmpty &&
              completed.length == reading.chapters.length,
        ),
      );
    }
    if (cursor != orderedKeys.length) {
      throw ArgumentError(
        'Reading occurrences cannot be matched in order. Review the plan before rescheduling.',
      );
    }
    return result;
  }

  List<ScheduledReading> _inDateOrder(List<ScheduledReading> readings) {
    final indexed = readings.indexed.toList()
      ..sort((a, b) {
        final byDate = a.$2.date.compareTo(b.$2.date);
        return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
      });
    return indexed.map((entry) => entry.$2).toList();
  }

  List<ScriptureReference> _expandChapterRange(ScriptureReference reference) {
    if (reference.startVerse != null || reference.endVerse != null) {
      return <ScriptureReference>[reference];
    }

    final endChapter = reference.endChapter ?? reference.startChapter;
    if (endChapter == reference.startChapter) {
      return <ScriptureReference>[reference];
    }

    return <ScriptureReference>[
      for (
        var chapter = reference.startChapter;
        chapter <= endChapter;
        chapter++
      )
        ScriptureReference(book: reference.book, startChapter: chapter),
    ];
  }

  List<DateTime> _eligibleDates({
    required DateTime startDate,
    required DateTime endDate,
    required Set<int> weekdays,
  }) {
    return localCalendarDates(
      startDate,
      endDate,
    ).where((date) => weekdays.contains(date.weekday)).toList();
  }

  List<DateTime> _spreadDates(List<DateTime> dates, int count) {
    if (count == 1) return <DateTime>[dates.first];
    if (count == dates.length) return dates;

    return <DateTime>[
      for (var index = 0; index < count; index++)
        dates[((index * (dates.length - 1)) / (count - 1)).round()],
    ];
  }

  int estimateMinutes(Iterable<ScriptureReference> references) {
    var minutes = 0.0;
    for (final reference in references) {
      if (reference.startVerse != null) {
        final endVerse = reference.endVerse ?? reference.startVerse!;
        final estimatedVerses = (endVerse - reference.startVerse! + 1)
            .clamp(1, 80)
            .toInt();
        minutes += estimatedVerses * 0.22;
      } else {
        minutes += 3.5;
      }
    }
    return minutes.ceil();
  }
}
