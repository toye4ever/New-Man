import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/tasks/domain/task_recurrence.dart';

void main() {
  group('daily recurrence', () {
    const rule = TaskRecurrence.daily();

    test('uses date fields only, without converting a UTC argument', () {
      expect(rule.isDaily, isTrue);
      expect(rule.weekdays, isEmpty);
      final next = rule.nextAfter(DateTime.utc(2026, 1, 31, 23, 59));
      expect(next, DateTime(2026, 2, 1));
      expect(next.isUtc, isFalse);
    });

    test('handles year-end, leap day, and a normal February', () {
      expect(rule.nextAfter(DateTime(2026, 12, 31)), DateTime(2027));
      expect(rule.nextAfter(DateTime(2024, 2, 28)), DateTime(2024, 2, 29));
      expect(rule.nextAfter(DateTime(2024, 2, 29)), DateTime(2024, 3, 1));
      expect(rule.nextAfter(DateTime(2026, 2, 28)), DateTime(2026, 3, 1));
    });

    test('advances one calendar date across spring and fall clock changes', () {
      // These are US clock-change dates. Also run this suite with
      // TZ=America/New_York to exercise its unequal-length local days.
      expect(rule.nextAfter(DateTime(2026, 3, 8, 23)), DateTime(2026, 3, 9));
      expect(rule.nextAfter(DateTime(2026, 11, 1, 23)), DateTime(2026, 11, 2));
    });
  });

  group('weekly recurrence', () {
    test('takes the nearest selected day strictly after the anchor', () {
      final rule = TaskRecurrence.weekly([DateTime.friday, DateTime.monday]);
      // Monday, Friday, Saturday and Sunday anchors in successive cases.
      expect(rule.nextAfter(DateTime(2026, 11, 16)), DateTime(2026, 11, 20));
      expect(rule.nextAfter(DateTime(2026, 11, 20)), DateTime(2026, 11, 23));
      expect(rule.nextAfter(DateTime(2026, 11, 21)), DateTime(2026, 11, 23));
      expect(rule.nextAfter(DateTime(2026, 11, 22)), DateTime(2026, 11, 23));
    });

    test('moves a single-day rule ahead a week if the anchor matches', () {
      final rule = TaskRecurrence.weekly([DateTime.wednesday]);
      expect(rule.nextAfter(DateTime(2026, 12, 30)), DateTime(2027, 1, 6));
    });

    test('copies, sorts, deduplicates and protects the supplied weekdays', () {
      final values = [DateTime.friday, DateTime.monday, DateTime.friday];
      final rule = TaskRecurrence.weekly(values);
      values.clear();
      expect(rule.isDaily, isFalse);
      expect(rule.weekdays, [DateTime.monday, DateTime.friday]);
      expect(() => rule.weekdays.add(DateTime.sunday), throwsUnsupportedError);
    });

    test('rejects empty, zero and out-of-range weekdays', () {
      expect(() => TaskRecurrence.weekly([]), throwsArgumentError);
      expect(() => TaskRecurrence.weekly([0, 1]), throwsArgumentError);
      expect(() => TaskRecurrence.weekly([7, 8]), throwsArgumentError);
    });
  });

  test('rejects out-of-range anchors and reports year overflow', () {
    const rule = TaskRecurrence.daily();
    expect(() => rule.nextAfter(DateTime.utc(0)), throwsArgumentError);
    expect(() => rule.nextAfter(DateTime.utc(10000)), throwsArgumentError);
    expect(rule.nextAfter(DateTime(9999, 12, 30)), DateTime(9999, 12, 31));
    expect(() => rule.nextAfter(DateTime(9999, 12, 31)), throwsStateError);
    expect(
      () => TaskRecurrence.weekly([
        DateTime.saturday,
      ]).nextAfter(DateTime(9999, 12, 30)),
      throwsStateError,
    );
  });
}
