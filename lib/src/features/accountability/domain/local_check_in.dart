/// A calendar date, not an instant or a duration from another day.
class CheckInDay {
  CheckInDay(this.year, this.month, this.day) {
    final checked = DateTime.utc(year, month, day);
    if (year < 1 ||
        year > 9999 ||
        checked.year != year ||
        checked.month != month ||
        checked.day != day) {
      throw ArgumentError('Invalid check-in calendar date');
    }
  }

  factory CheckInDay.fromLocal(DateTime local) =>
      CheckInDay(local.year, local.month, local.day);

  factory CheckInDay.parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Invalid check-in calendar date');
    }
    return CheckInDay(
      int.parse(value.substring(0, 4)),
      int.parse(value.substring(5, 7)),
      int.parse(value.substring(8, 10)),
    );
  }

  final int year;
  final int month;
  final int day;
  String get key =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) => other is CheckInDay && key == other.key;
  @override
  int get hashCode => key.hashCode;
}

/// Approved evening outcomes with explicit, stable persistence keys.
enum EveningOutcome {
  met('met'),
  partlyMet('partly_met'),
  notMet('not_met');

  const EveningOutcome(this.storageKey);
  final String storageKey;

  static EveningOutcome fromStorageKey(String key) => switch (key) {
    'met' => EveningOutcome.met,
    'partly_met' => EveningOutcome.partlyMet,
    'not_met' => EveningOutcome.notMet,
    _ => throw const FormatException('Invalid evening outcome'),
  };
}

/// Manually entered fields only. No task, Scripture, contact or partner links.
class LocalCheckIn {
  LocalCheckIn({
    required this.day,
    List<String>? morningCommitments,
    this.eveningOutcome,
    this.eveningNotes,
  }) : morningCommitments = morningCommitments == null
           ? null
           : List.unmodifiable(morningCommitments) {
    if (this.morningCommitments?.any((text) => text.trim().isEmpty) ?? false) {
      throw ArgumentError('Commitments must not be blank');
    }
    if (eveningNotes != null && eveningOutcome == null) {
      throw ArgumentError('Evening notes require an explicit outcome');
    }
  }

  final CheckInDay day;

  /// Null means no morning write; empty means explicitly saved without items.
  final List<String>? morningCommitments;

  /// Null means no evening check-in has been recorded.
  final EveningOutcome? eveningOutcome;
  final String? eveningNotes;
}

abstract interface class LocalCheckInRepository {
  LocalCheckIn? read(CheckInDay day);
  List<LocalCheckIn> history({int limit = 30, int offset = 0});
  void writeMorning(CheckInDay day, List<String> commitments);
  void writeEvening(
    CheckInDay day, {
    required EveningOutcome outcome,
    String? notes,
  });
  void close();
}
