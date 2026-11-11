import '../../bible/domain/scripture_reference.dart';
import '../../translations/domain/bible_translation.dart';

class ScheduledReading {
  const ScheduledReading({
    required this.date,
    required this.references,
    this.completed = false,
    this.translationOverride,
    this.completedChapterKeys = const {},
  });

  final DateTime date;
  final List<ScriptureReference> references;
  final bool completed;
  final Set<String> completedChapterKeys;
  List<ScriptureReference> get chapters {
    final seen = <String>{};
    return [
      for (final ref in references)
        for (var c = ref.startChapter; c <= ref.resolvedEndChapter; c++)
          if (seen.add('${ref.book}:$c'))
            ScriptureReference(book: ref.book, startChapter: c),
    ];
  }

  static String chapterKey(ScriptureReference ref) =>
      '${ref.book}:${ref.startChapter}';
  bool isChapterCompleted(ScriptureReference ref) =>
      completed || completedChapterKeys.contains(chapterKey(ref));
  int get completedChapterCount => chapters.where(isChapterCompleted).length;
  ScheduledReading completeChapter(ScriptureReference ref) {
    if (!chapters.any((c) => chapterKey(c) == chapterKey(ref))) {
      throw ArgumentError('Chapter is not assigned to this day');
    }
    if (isChapterCompleted(ref)) return this;
    final keys = {...completedChapterKeys, chapterKey(ref)};
    return copyWith(
      completedChapterKeys: keys,
      completed: chapters.every((c) => keys.contains(chapterKey(c))),
    );
  }

  final BibleTranslation? translationOverride;

  BibleTranslation effectiveTranslation(BibleTranslation planDefault) =>
      translationOverride ?? planDefault;

  ScheduledReading copyWith({
    DateTime? date,
    List<ScriptureReference>? references,
    bool? completed,
    Set<String>? completedChapterKeys,
    BibleTranslation? translationOverride,
    bool clearTranslationOverride = false,
  }) {
    return ScheduledReading(
      date: date ?? this.date,
      references: references ?? this.references,
      completed: completed ?? this.completed,
      completedChapterKeys: completedChapterKeys ?? this.completedChapterKeys,
      translationOverride: clearTranslationOverride
          ? null
          : translationOverride ?? this.translationOverride,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'date': date.toIso8601String(),
    'references': references.map((reference) => reference.toJson()).toList(),
    'completed': completed,
    'completedChapterKeys': completedChapterKeys.toList()..sort(),
    'translationOverride': translationOverride?.name,
  };

  factory ScheduledReading.fromJson(Map<String, dynamic> json) {
    final translationName = json['translationOverride'] as String?;
    return ScheduledReading(
      date: DateTime.parse(json['date'] as String),
      references: (json['references'] as List<dynamic>)
          .map(
            (item) => ScriptureReference.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      completed: json['completed'] as bool? ?? false,
      completedChapterKeys: Set<String>.unmodifiable(
        (json['completedChapterKeys'] as List<dynamic>? ?? const [])
            .cast<String>(),
      ),
      translationOverride: translationName == null
          ? null
          : BibleTranslation.values.byName(translationName),
    );
  }
}

class ReadingPlan {
  const ReadingPlan({
    required this.id,
    required this.title,
    required this.defaultTranslation,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.readingWeekdays,
    required this.reminderTime,
    required this.sourceReferences,
    required this.assignments,
    this.templateId,
    this.lastReadLocation,
    this.lastReadAssignmentHint,
  });

  final String id;
  final String title;
  final BibleTranslation defaultTranslation;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime endDate;
  final Set<int> readingWeekdays;
  final String reminderTime;
  final List<ScriptureReference> sourceReferences;
  final List<ScheduledReading> assignments;
  final String? templateId;
  final ScriptureReference? lastReadLocation;
  final int? lastReadAssignmentHint;

  int? get lastReadAssignmentIndex {
    final location = lastReadLocation;
    if (location == null) return null;
    final hint = lastReadAssignmentHint;
    if (hint != null &&
        hint >= 0 &&
        hint < assignments.length &&
        assignments[hint].references.any(
          (ref) =>
              ref.book == location.book &&
              location.startChapter >= ref.startChapter &&
              location.startChapter <= ref.resolvedEndChapter,
        )) {
      return hint;
    }
    final index = assignments.indexWhere(
      (reading) => reading.references.any(
        (ref) =>
            ref.book == location.book &&
            location.startChapter >= ref.startChapter &&
            location.startChapter <= ref.resolvedEndChapter,
      ),
    );
    return index < 0 ? null : index;
  }

  int get progressAssignmentIndex {
    if (assignments.isEmpty) return 0;
    final lastPartial = assignments.lastIndexWhere(
      (item) => item.completed || item.completedChapterCount > 0,
    );
    if (lastPartial >= 0 && !assignments[lastPartial].completed) {
      return lastPartial;
    }
    final lastCompleted = assignments.lastIndexWhere((item) => item.completed);
    return (lastCompleted + 1).clamp(0, assignments.length - 1);
  }

  int readingStartChapterIndex(int day) {
    final reading = assignments[day];
    final chapters = reading.chapters;
    if (lastReadAssignmentIndex == day && lastReadLocation != null) {
      final index = chapters.indexWhere(
        (c) =>
            ScheduledReading.chapterKey(c) ==
            ScheduledReading.chapterKey(lastReadLocation!),
      );
      if (index >= 0) return index;
    }
    final next = chapters.indexWhere((c) => !reading.isChapterCompleted(c));
    return next < 0 ? 0 : next;
  }

  int get completedCount => assignments.where((item) => item.completed).length;

  int get totalChapterCount =>
      assignments.fold(0, (sum, day) => sum + day.chapters.length);
  int get completedChapterCount =>
      assignments.fold(0, (sum, day) => sum + day.completedChapterCount);
  double get progress =>
      totalChapterCount == 0 ? 0 : completedChapterCount / totalChapterCount;

  ReadingPlan copyWith({
    String? title,
    BibleTranslation? defaultTranslation,
    DateTime? startDate,
    DateTime? endDate,
    Set<int>? readingWeekdays,
    String? reminderTime,
    List<ScriptureReference>? sourceReferences,
    List<ScheduledReading>? assignments,
    String? templateId,
    ScriptureReference? lastReadLocation,
    int? lastReadAssignmentHint,
  }) {
    return ReadingPlan(
      id: id,
      title: title ?? this.title,
      defaultTranslation: defaultTranslation ?? this.defaultTranslation,
      createdAt: createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      readingWeekdays: readingWeekdays ?? this.readingWeekdays,
      reminderTime: reminderTime ?? this.reminderTime,
      sourceReferences: sourceReferences ?? this.sourceReferences,
      assignments: assignments ?? this.assignments,
      templateId: templateId ?? this.templateId,
      lastReadLocation: lastReadLocation ?? this.lastReadLocation,
      lastReadAssignmentHint:
          lastReadAssignmentHint ?? this.lastReadAssignmentHint,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'defaultTranslation': defaultTranslation.name,
    'createdAt': createdAt.toIso8601String(),
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'readingWeekdays': readingWeekdays.toList(),
    'reminderTime': reminderTime,
    'sourceReferences': sourceReferences.map((item) => item.toJson()).toList(),
    'assignments': assignments.map((item) => item.toJson()).toList(),
    'templateId': templateId,
    'lastReadLocation': lastReadLocation?.toJson(),
    'lastReadAssignmentHint': lastReadAssignmentHint,
  };

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    final assignments = (json['assignments'] as List<dynamic>)
        .map((item) => ScheduledReading.fromJson(item as Map<String, dynamic>))
        .toList();
    final legacyTranslation = json['translation'] as String?;
    final defaultTranslationName =
        json['defaultTranslation'] as String? ?? legacyTranslation ?? 'kjv';
    final sourceJson = json['sourceReferences'] as List<dynamic>?;
    final sourceReferences = sourceJson == null
        ? assignments.expand((item) => item.references).toList()
        : sourceJson
              .map(
                (item) =>
                    ScriptureReference.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    final parsedStart = DateTime.parse(json['startDate'] as String);
    final endValue = json['endDate'] as String?;
    final parsedEnd = endValue == null
        ? (assignments.isEmpty ? parsedStart : assignments.last.date)
        : DateTime.parse(endValue);

    return ReadingPlan(
      id: json['id'] as String,
      title: json['title'] as String,
      defaultTranslation: BibleTranslation.values.byName(
        defaultTranslationName,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDate: parsedStart,
      endDate: parsedEnd,
      readingWeekdays: (json['readingWeekdays'] as List<dynamic>)
          .cast<int>()
          .toSet(),
      reminderTime: json['reminderTime'] as String,
      sourceReferences: sourceReferences,
      assignments: assignments,
      templateId: json['templateId'] as String?,
      lastReadAssignmentHint: json['lastReadAssignmentHint'] as int?,
      lastReadLocation: json['lastReadLocation'] == null
          ? null
          : ScriptureReference.fromJson(
              json['lastReadLocation'] as Map<String, dynamic>,
            ),
    );
  }
}
