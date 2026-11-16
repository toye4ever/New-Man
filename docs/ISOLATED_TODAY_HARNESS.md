# Isolated Today persistence harness

Run with pinned Flutter 3.44.8 and the existing lockfile:

```
flutter pub get --offline --enforce-lockfile
flutter test --no-pub test/isolated_today_reopen_test.dart
```

The [test entrypoint](../test/isolated_today_reopen_test.dart) uses Flutter's
existing widget-test runner, production TaskService/DriftTaskRepository/TodayScreen
and real file-backed SQLite in a uniquely created, owned system-temp directory.
It does not call app main/bootstrap, AppDatabase.open, a default storage provider,
Windows runner executable, online Bible or native notification adapter. No new
production routes, switches, dependencies, CI launches or settings are added.

This joins evidence previously covered separately by in-memory screen tests and
per-field SQLite reopen tests:

1. Seed synthetic tasks with a time block, daily priority, ordered subtask state,
   recurrence and an already-due foreground reminder through production services.
2. Render the meaningful Today screen, verify the scheduled/subtask presentation
   and perform reminder Dismiss through its actual UI.
3. Unmount all widget/controller state, dispose the service, close SQLite, create
   new database/repository/service instances and verify retained values and
   `PRAGMA quick_check`. Render a fresh Today screen; the dismissal stays absent.
4. Complete the recurring task through its UI, dispose/close/reopen again and
   verify exactly one natural successor with reset subtasks. Retry completion
   using the retained old object and confirm no duplicate. Render the next day.

Appearance preferences use the isolated in-memory test platform with fresh
appearance-repository instances on reopen; dark theme reaches the screen. This
is deliberate: preferences are not a real Windows plugin/file and this does not
claim preferences survive an OS process restart. The actual SQLite file does
survive complete connection/service/screen teardown within the test.

Profile-path provider methods fail closed, and HTTP-client creation in the
harness zone throws. Both attempt counters must remain zero. No contacts, real
notes/tasks/history or credentials are loaded. Synthetic strings only are used.
Finally, all widgets/services/database handles are disposed, only the directory
created by this test is removed, and test-global provider instances are restored,
including on failure. The test has a 45-second bound.

A passing headless widget test is not a real desktop app launch, Windows known-
folder resolution, compiled EXE startup, Galaxy, notification or full-MVP result.
The native SQLite library/file IO and screen persistence path are real; default
OS path selection and platform preferences are intentionally excluded. Windows
can run this same Flutter test later in an authorized environment, but no Windows
execution or runner-profile access was performed while preparing this unit.
