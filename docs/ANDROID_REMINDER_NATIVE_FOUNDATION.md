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
only after success. An unarmed record cannot post. Cancellation performs OS
cleanup before removing its ledger record; failed cleanup/commit is unconfirmed.
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
