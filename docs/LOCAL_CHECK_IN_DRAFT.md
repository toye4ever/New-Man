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

## Unexposed local persistence foundation

The shipped screen above is unchanged: its in-memory draft still clears on
cancel/navigation and is not stored. It does not import or open the new
`ExplicitLocalCheckInStore`. There is no new UI, default path, startup hook,
shared-preferences entry, existing-profile migration, network, export, backup,
partner or sharing integration.

The separate Dart repository can only be opened explicitly with persistence
opt-in and an absolute, caller-owned private file. It recognizes its own SQLite
application ID/schema or initializes an empty file; it rejects foreign/nonmatching
stores. Morning commitments, typed evening outcomes (met / partly met / not met) and
separate optional manual notes are keyed by a validated calendar date. Outcomes
use stable stored keys `met`, `partly_met`, `not_met`, enforced by SQLite CHECK
and strict decode; a missing evening check-in remains unrecorded. This private
store schema is version 2; the earlier untyped prototype is rejected without
migration or file changes. No existing app-profile schema is changed. No task, Scripture, contact or
other opaque links are accepted at this stage. Writes target one date and one
section, preserving the other section; repeating identical writes produces one
entry. History reads are paginated, with no automatic pruning or retention rule.
No deletion policy is inferred or implemented.

Synthetic host tests use disposable files and close/new connection/reopen,
section preservation, idempotency, date boundaries, rollback of an injected
cross-day trigger effect, sanitized failures and byte-preservation of a rejected
foreign database. They do not qualify Android filesystem durability, encryption,
backup exclusion, process death or a consent/revocation UI. Before any UI wiring,
resolve retention/deletion and storage/backup/privacy behavior explicitly; qualify
those separately. This foundation does not change the existing draft promise or
establish Today wrap-up integration.
