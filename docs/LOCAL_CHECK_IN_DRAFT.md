# Local check-in draft acceptance

This optional surface replaces the empty Accountability tab placeholder. It is
not partner accountability, messaging or completion of the approved production
milestone. Users explicitly start, choose Reflection and/or Next step, type up to
280 characters per field and review only selected nonempty text. Neither field
is initially selected. Deselecting erases that field; Cancel/Clear erase all
controllers and selections. Editing review preserves the current manual draft.

The screen imports only Flutter material widgets: no controller, repository,
account/contact identifier, history, Scripture note, task source, clipboard,
share sheet or network API is accessed. Nothing is logged or written to storage.
The app shell unmounts this tab on departure instead of retaining it in the
IndexedStack. Disposal drops the in-memory controllers. This is not a promise of
forensic memory erasure or control over device keyboards, screenshots or OS
snapshots. Suggestions, autocorrect and IME personalized learning are disabled
for these fields; third-party keyboard behavior is outside the app's guarantee.

Reproduce with pinned Flutter 3.44.8 and the unchanged lockfile:

```
flutter pub get --offline --enforce-lockfile
flutter test --no-pub test/local_check_in_test.dart test/private_beta_scope_test.dart
flutter analyze --no-pub
```

Widget coverage: explicit selection and trimmed review, unchecked field
exclusion, edit preservation, deselection erasure, Cancel and Clear, actual tab
navigation discard, labeled checkbox semantics/touch targets, and small viewport
with doubled text scaling. Tests enter synthetic strings only. Device screen
reader/keyboard testing is still a separate acceptance gate. No sharing or native
permission configuration follows from this unit.
