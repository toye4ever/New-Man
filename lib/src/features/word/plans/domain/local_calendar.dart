/// Date-only arithmetic using local calendar components, not elapsed 24-hour days.
/// This deliberately does not convert UTC instants or preserve a time of day.
DateTime addLocalCalendarDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

Iterable<DateTime> localCalendarDates(DateTime start, DateTime end) sync* {
  final last = addLocalCalendarDays(end, 0);
  for (
    var day = addLocalCalendarDays(start, 0);
    !day.isAfter(last);
    day = addLocalCalendarDays(day, 1)
  ) {
    yield day;
  }
}
