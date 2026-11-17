import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/word/plans/domain/local_calendar.dart';

void main() {
  for (final start in [
    DateTime(2026, 3, 7),
    DateTime(2026, 10, 31),
    DateTime(2026, 12, 31),
  ]) {
    test('inclusive template duration and picker bounds from $start', () {
      final end = addLocalCalendarDays(start, 2);
      expect(end, DateTime(start.year, start.month, start.day + 2));
      expect(localCalendarDates(start, end).toList(), [
        start,
        DateTime(start.year, start.month, start.day + 1),
        end,
      ]);
      expect(addLocalCalendarDays(end, -2), start);
      expect(addLocalCalendarDays(start, 0), start);
      expect(
        addLocalCalendarDays(start, 3650),
        DateTime(start.year, start.month, start.day + 3650),
      );
      expect(localCalendarDates(end, start), isEmpty);
    });
  }
}
