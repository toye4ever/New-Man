import '../../bible/domain/scripture_reference.dart';
import '../../translations/domain/bible_translation.dart';

class ScheduledReading {
  const ScheduledReading({
    required this.date,
    required this.references,
    this.completed = false,
    this.translationOverride,
  });

  final DateTime date;
  final List<ScriptureReference> references;
  final bool completed;
  final BibleTranslation? translationOverride;

  BibleTranslation effectiveTranslation(BibleTranslation planDefault) =>
      translationOverride ?? planDefault;

  ScheduledReading copyWith({
    DateTime? date,
    List<ScriptureReference>? references,
    bool? completed,
    BibleTranslation? translationOverride,
    bool clearTranslationOverride = false,
  }) {
    return ScheduledReading(
      date: date ?? this.date,
      references: references ?? this.references,
      completed: completed ?? this.completed,
      translationOverride: clearTranslationOverride
          ? null
          : translationOverride ?? this.translationOverride,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'date': date.toIso8601String(),
    'references': references.map((reference) => reference.toJson()).toList(),
    'completed': completed,
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

  int get completedCount => assignments.where((item) => item.completed).length;

  double get progress =>
      assignments.isEmpty ? 0 : completedCount / assignments.length;

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
    );
  }
}
