import 'package:intl/intl.dart';

import '../models/scripture_reference.dart';
import 'reference_parser.dart';
import 'reference_utils.dart';

class PlanAssistantResult {
  const PlanAssistantResult({
    required this.passagesText,
    required this.endDate,
    required this.readingWeekdays,
    required this.message,
    required this.changed,
  });

  final String passagesText;
  final DateTime endDate;
  final Set<int> readingWeekdays;
  final String message;
  final bool changed;
}

class PlanAssistantService {
  PlanAssistantService({ReferenceParser? parser})
    : _parser = parser ?? ReferenceParser();

  final ReferenceParser _parser;

  PlanAssistantResult apply({
    required String instruction,
    required String passagesText,
    required DateTime endDate,
    required Set<int> readingWeekdays,
  }) {
    var updatedText = passagesText;
    var updatedEndDate = endDate;
    var updatedWeekdays = readingWeekdays;
    var changed = false;
    final changes = <String>[];
    final lower = instruction.toLowerCase().trim();

    final wantsChaptersOnly =
        (lower.contains('only') && lower.contains('chapter')) ||
        lower.contains('remove verse') ||
        lower.contains('strip verse') ||
        lower.contains('chapter references');

    if (wantsChaptersOnly) {
      final parsed = _parser.parse(updatedText);
      if (parsed.references.isNotEmpty) {
        final chapters = ReferenceUtils.chapterOnly(parsed.references);
        updatedText = ReferenceUtils.formatForEditor(chapters);
        changed = true;
        changes.add(
          'Converted ${parsed.references.length} passage references into '
          '${chapters.length} chapter references.',
        );
      }
    }

    final parsedDate = _extractEndDate(instruction);
    if (parsedDate != null) {
      updatedEndDate = parsedDate;
      changed = true;
      changes.add(
        'Changed the end date to ${DateFormat.yMMMd().format(parsedDate)}.',
      );
    }

    final weekdaySelection = _extractWeekdays(lower);
    if (weekdaySelection.isNotEmpty &&
        (lower.contains('read on') ||
            lower.contains('reading days') ||
            lower.contains('only on') ||
            lower.contains('weekdays'))) {
      updatedWeekdays = weekdaySelection;
      changed = true;
      changes.add('Updated the selected reading days.');
    }

    if (lower.startsWith('add ')) {
      final addition = instruction.substring(4).trim();
      final parsed = _parser.parse(addition);
      if (parsed.references.isNotEmpty && parsed.issues.isEmpty) {
        final existing = _parser.parse(updatedText).references;
        final combined = ReferenceUtils.deduplicate(<ScriptureReference>[
          ...existing,
          ...parsed.references,
        ]);
        updatedText = ReferenceUtils.formatForEditor(combined);
        changed = true;
        changes.add('Added ${parsed.references.length} passage reference(s).');
      }
    }

    return PlanAssistantResult(
      passagesText: updatedText,
      endDate: updatedEndDate,
      readingWeekdays: updatedWeekdays,
      changed: changed,
      message: changed
          ? changes.join(' ')
          : 'I could not apply that instruction yet. Try “only include chapters,” '
                '“change the end date to August 30, 2026,” “read on Monday, '
                'Wednesday, and Friday,” or “add Romans 8.”',
    );
  }

  DateTime? _extractEndDate(String input) {
    final lower = input.toLowerCase();
    if (!lower.contains('end date') &&
        !lower.contains('finish') &&
        !lower.contains('complete by')) {
      return null;
    }

    final candidates = <RegExp>[
      RegExp(r'\b(20\d{2}-\d{1,2}-\d{1,2})\b'),
      RegExp(r'\b(\d{1,2}/\d{1,2}/20\d{2})\b'),
      RegExp(
        r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}(?:,?\s+20\d{2})?\b',
        caseSensitive: false,
      ),
    ];

    for (final expression in candidates) {
      final match = expression.firstMatch(input);
      if (match == null) continue;
      final text = match.group(0)!;
      final parsed = _tryParseDate(text);
      if (parsed != null) return parsed;
    }
    return null;
  }

  DateTime? _tryParseDate(String input) {
    final cleaned = input.replaceAll(',', '').trim();
    final formats = <DateFormat>[
      DateFormat('yyyy-M-d'),
      DateFormat('M/d/yyyy'),
      DateFormat('MMMM d yyyy'),
      DateFormat('MMM d yyyy'),
    ];

    for (final format in formats) {
      try {
        return format.parseStrict(cleaned);
      } on FormatException {
        // Try the next supported shape.
      }
    }

    final currentYear = DateTime.now().year;
    for (final format in <DateFormat>[
      DateFormat('MMMM d yyyy'),
      DateFormat('MMM d yyyy'),
    ]) {
      try {
        return format.parseStrict('$cleaned $currentYear');
      } on FormatException {
        // Try the next supported shape.
      }
    }
    return null;
  }

  Set<int> _extractWeekdays(String input) {
    const names = <String, int>{
      'monday': DateTime.monday,
      'mondays': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'tuesdays': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'wednesdays': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'thursdays': DateTime.thursday,
      'friday': DateTime.friday,
      'fridays': DateTime.friday,
      'saturday': DateTime.saturday,
      'saturdays': DateTime.saturday,
      'sunday': DateTime.sunday,
      'sundays': DateTime.sunday,
    };
    return <int>{
      for (final entry in names.entries)
        if (RegExp('\\b${entry.key}\\b').hasMatch(input)) entry.value,
    };
  }
}
