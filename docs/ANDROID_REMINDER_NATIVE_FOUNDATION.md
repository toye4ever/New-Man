# Dormant native Android reminder foundation

This source adds an AlarmManager backend, alarm/system receiver classes, a
method-channel handler and portable Java policy. It is deliberately gated by
`qualified() == false`, not registered in MainActivity, and absent from all
manifests. No permission, receiver declaration or live toggle is added. No OS
operation or permission prompt was performed during development. Native Android
type/link compilation and device qualification are pending; Kotlin syntax parsing
and portable Java assertions are narrower evidence.

## Native contract

The handler matches the Dart protocol's required state, enable, upsert, cancel,
access-revocation cleanup and Off acknowledgements. Installation metadata is in
app-private SharedPreferences, initialized with opt-in Off. Metadata write failure
or invalid installation state cannot authorize scheduling. Consent revision and
hashed installation scope guard every upsert and enabling attempt. An optional
future Activity permission callback is reached only for explicit acknowledged
enabling on a qualified API 33+ path with permission missing. The default callback
is absent; this unit implements no Activity permission dialog. Fresh OS permission
and notification/channel access are required after callback return.

Only `setAndAllowWhileIdle` is used: delivery is inexact and can be delayed or
lost. No exact-alarm, alarm-clock, Accessibility or foreground-service API is
used. The native foundation conservatively requires API 26+ for channels and
java.time; older builds remain unsupported for native delivery and keep the
existing foreground inbox.

Alarms use immutable explicit PendingIntents with a full opaque key in their
package-scoped data URI. Posted notifications use the full key as a tag, avoiding
integer-only collisions. Content is always `New Man` / `You have a task to review.`
with secret lock-screen visibility and a generic app-launch intent. No private
task title, checklist, note or Scripture text enters a notification or log.

## Private authority and ledger

Before scheduling and immediately before attempting delivery, the backend checks
qualification, consent, acknowledgement, system/channel access, permission,
installation scope, revision, timing, receipts and the current task. It reads
`files/database/new_man.sqlite` read-only; the qualification run must confirm this
matches path_provider's Android support-directory path. Queries read only task
IDs and reminder/date/state metadata, never private task titles. A work bound of
1,000 eligible rows means a missing/unreadable or unlocated task fails closed.
Native JSON key generation has portable vectors matching Dart's encoding.

Pending records are persisted unarmed before OS scheduling, then marked armed
only after success. An unarmed record cannot post. Cancellation durably disarms records before OS
cleanup and removes them only after cleanup; failed cleanup/commit is unconfirmed.
Bulk cancellation disarms the whole known queue first and attempts every key even
when individual cleanup fails. Disarmed records cannot deliver despite a queued
broadcast or lost OS cancellation.
An unreadable ledger cannot truthfully acknowledge that every old job was
cancelled. Explicit Off is committed first and invalidates revisions before
cleanup. The receiver rechecks current Off/permission state independently of its
original intent.

At delivery, a durable receipt and pending-record removal precede notify. This
is an at-most-once **attempt**, not proof of delivery: a crash or rejected post
after receipt commit loses the alert rather than replaying it. Receipts are
preserved across Off and bounded at 2,048; exhaustion fails closed. Pending jobs
are capped at 64. The foreground inbox remains the fallback.

## Reboot, clock changes and races

The undeclared system receiver's implementation cancels known pending and posted
reminders on reboot, manual clock change or timezone change. It does not re-arm
or request permission. After future wiring, foreground Dart reconciliation must
rebuild only future eligible jobs from the task database and durable ledger.
DST resolution uses the first valid minute after a gap, omits skipped local dates
and chooses one repeated-hour instant. A stale timezone-dependent instant is
rejected by current task authority until fresh reconciliation.

Task edits/completion/delete/dismiss must trigger the existing Dart cancellation
plan. Native task checks reduce the write-to-cancel race, but SQLite state and an
OS notify operation are not one atomic transaction: a task change immediately
after the last read could produce a brief generic notification until cancellation.
Do not claim race-free or timely delivery. Hardware tests must check this window,
revocation/Off during permission callbacks, process death, corrupt storage, reboot,
Doze, channel blocking and expiry. Receiver IO/latency also needs real Android
qualification before manifest registration or any user-facing enable flow.

## Verified evidence

`TaskReminderNativePolicyTest` runs with JDK assertions and no Android runtime.
It checks Off/permission gates, stale revisions, receipt/expiry limits, authoritative
task rejection, full-key/hash vectors, DST and dormant manifest/activity status.
Kotlin PSI parsing uses the existing cached Kotlin compiler and catches syntax
errors only. Neither check proves Android APIs link or that an APK delivers.

## Reproducible validation gates

1. At an exact clean candidate commit, use JDK 21:
   `JAVA_HOME=/path/to/jdk-21 bash tools/check_native_reminder_policy.sh`.
   This includes injected disarm persistence failure, first-job OS cleanup failure,
   continued cleanup of later jobs, queue-cap replacement and disarmed delivery.
   It proves portable coordinator/policy behavior, not SharedPreferences durability.
2. Run `python3 -m unittest discover -s tools -p 'test_*.py'` and
   `git diff --check`. With pinned Flutter 3.44.8 and the lockfile, run
   `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`.
   The preceding transport checkpoint passed 374 Flutter tests; no Dart changes
   are introduced by this native review.
3. After parent review/publication, the existing feature-only Android workflow
   must build the exact commit with preinstalled SDK/NDK, pinned host CMake and
   debug ARM64. This is the first Android type/link compilation gate for this
   foundation. Do not interpret portable tests or Kotlin parsing as compilation.
   Run the existing compiled-manifest checker; verify receiver/notification
   permission absence and development package suffix. No separate upload or
   device workflow is authorized here.
4. Before any future wiring, use an authorized isolated development install and
   synthetic tasks. Verify support-directory path/schema; complete/edit/delete/
   dismiss cancellation; Off during callback; permission/channel revocation;
   failed metadata writes and each OS cleanup call; 64 pending/2,048 receipts;
   process death before/after arm and receipt commits; clock/zone changes/reboot;
   spring gap/fall overlap/skipped day; Doze, overdue expiry and no replay.
   Confirm private titles never appear in notification, lock screen, intents or
   logs. Device permissions and receiver wiring require a separately reviewed
   unit and explicit owner-controlled opt-in; this checklist grants neither.

Review limits: revocation is checked at scheduling and delivery, not monitored
while the process is absent. A revoke-and-restore interval between checks cannot
be detected; no guarantee that historic permission revocation permanently cancels
all OS jobs is made. Receipt exhaustion intentionally stops native scheduling;
there is no receipt reset/pruning UI. Off does not discard receipts. Both choices
must remain explicit in qualification and future enable-flow design.
