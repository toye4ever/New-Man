# Reading-plan calendar dates across DST

New schedules and Catch Me Up now enumerate local calendar components, rather
than adding elapsed 24-hour durations. A three-day inclusive range stays three
separate dates across spring-forward and fall-back. Selected weekdays remain
filters on those dates. Template inclusive end dates and the same screen's
3650-day picker bounds use the shared calendar helper too.

Synthetic Flutter regressions cover July 27–29, March 7–9 and October 31–November
2, 2026, with all weekdays and only the first/last weekday selected. They check
three chapters, exact assignment dates, Catch Me Up eligible counts, no preview
writes and unchanged UTC creation timestamps. Run with both the default zone
and `TZ=America/New_York`:

```sh
flutter test --no-pub test/plan_calendar_dst_test.dart test/local_calendar_test.dart test/plan_scheduler_test.dart
```

This changes future generation and explicit rescheduling only. No migration,
deduplication or automatic rewrite is performed. Existing schedules may already
contain same-date sessions or drifted times; multiple sessions on one date can
also be legitimate. Assess those separately before any recovery policy. Completed
history and persisted user data must not be silently rewritten.
