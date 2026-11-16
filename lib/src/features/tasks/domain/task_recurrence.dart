/// A calendar rule for the next dated occurrence of a task.
class TaskRecurrence {
  const TaskRecurrence.daily() : weekdays = const [];

  /// Repeats on the supplied ISO weekdays (Monday=1 through Sunday=7).
  /// Duplicate days are collapsed.
  TaskRecurrence.weekly(Iterable<int> weekdays)
    : weekdays = _validateWeekdays(weekdays);

  /// Selected ISO weekdays, sorted and immutable; empty for a daily rule.
  final List<int> weekdays;

  bool get isDaily => weekdays.isEmpty;

  /// Returns the first matching local calendar date strictly after [date].
  ///
  /// Only the supplied year, month and day are used, without converting time
  /// zones. The caller chooses the anchor; this rule never completes tasks or
  /// creates occurrences. Years outside 1–9999 are not supported.
  DateTime nextAfter(DateTime date) {
    if (date.year < 1 || date.year > 9999) {
      throw ArgumentError.value(date, 'date', 'Year must be in 1–9999.');
    }
    // Advance a calendar label in UTC rather than adding 24 hours to a local
    // instant, which could repeat or miss dates during a clock change.
    var day = DateTime.utc(date.year, date.month, date.day + 1);
    while (day.year <= 9999) {
      if (isDaily || weekdays.contains(day.weekday)) {
        final localDate = DateTime(day.year, day.month, day.day);
        // Some time-zone transitions delete an entire local calendar day.
        // Do not return its normalized replacement under the wrong rule.
        if (localDate.year == day.year &&
            localDate.month == day.month &&
            localDate.day == day.day) {
          return localDate;
        }
      }
      day = day.add(const Duration(days: 1));
    }
    throw StateError('No matching task date remains through year 9999.');
  }

  static List<int> _validateWeekdays(Iterable<int> values) {
    final days = values.toSet().toList()..sort();
    if (days.isEmpty ||
        days.first < DateTime.monday ||
        days.last > DateTime.sunday) {
      throw ArgumentError.value(values, 'weekdays', 'Choose weekdays 1–7.');
    }
    return List<int>.unmodifiable(days);
  }
}

/// Skips missed dates rather than materializing an overdue backlog.
DateTime nextTaskOccurrence(
  TaskRecurrence rule,
  DateTime? dueDate,
  DateTime today,
) {
  final day = DateTime(today.year, today.month, today.day);
  final due = dueDate == null
      ? day
      : DateTime(dueDate.year, dueDate.month, dueDate.day);
  return rule.nextAfter(due.isAfter(day) ? due : day);
}
