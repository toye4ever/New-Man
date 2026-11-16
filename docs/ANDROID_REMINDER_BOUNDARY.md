# Android reminder delivery boundary — not connected or qualified

This unit provides a pure planner and a serialized mutation boundary. It adds no
Android adapter, manifest permission, receiver, database migration, UI opt-in,
notification channel, background job, network call, or OS operation. The app does
not call it. The default capability is unsupported and consent is disabled.
Existing foreground reminders keep their current behavior.

## Installation-local consent

The app currently has one local installation context. Consent will be
installation-local, Off by default; no user account or profile switching is
introduced. The boundary takes an opaque local installation token, never a name
or email address. The eventual adapter must persist that token and separate
explicit notification opt-in/inexact-timing acknowledgement in app-private local
storage. It must not infer background-notification consent from an existing
in-app reminder time. Migrations and resets must leave this Off. The native
adapter and permission UI remain unconnected and unqualified in this unit.

## Policy and privacy

Planning requires supported Android API 23+, installation-scoped opt-in, acknowledgement
of inexact timing, system notifications enabled, and runtime permission granted
on API 33+. The permission-request predicate returns true only for an explicit
acknowledged enable gesture in the not-requested state on API 33+. Reconciliation
never requests permission. Denial, unknown capability, empty owner, missing
acknowledgement or opt-out yields no desired schedules and cancels old ones.

Only future, incomplete, undismissed task reminders are proposed. Overdue tasks
remain in the existing in-app inbox instead of causing background catch-up
bursts. At most 64 earliest schedules are retained; the deferred count is
explicit. Later foreground reconciliation can fill the remaining capacity.

Payloads use a full SHA-256 opaque key and owner scope, UTC timing bounds, title
`New Man` and body `You have a task to review.` They contain no raw task/user ID,
name, title, checklist, note, Scripture text or account address. Everything is
intended for app-private local storage; there is no off-device transport.

Local times resolve on the device. A spring-forward gap moves to the first valid
minute after the gap; an entirely skipped local date is omitted. Repeated hours
resolve to one instant; durable delivered-key receipts prevent re-alerting after
clock rollback. A proposal expires at the end of its local due date. Native
inexact delivery can be late and is not guaranteed, particularly under battery
restrictions. It must never post before the proposed instant or after expiry.
Resume reconciliation cancels alarms that have become overdue, leaving them in
the inbox. No exact-alarm or Accessibility permission is part of this design.

## Native adapter contract and remaining acceptance gates

The eventual adapter must implement idempotent full-key upsert/cancel. Do not
truncate keys into collision-prone integer-only PendingIntent identities. Persist
a scheduled ledger and delivered-key receipts. A date/time edit changes the key;
a title-only edit changes no redacted payload. Delivered receipts suppress a
return to the same task/date/time, even after a clock or owner switch. Recurring
successors have different task identifiers and therefore different keys.

Reconcile after opt-in/out, permission/channel changes, owner changes, task
create/edit/complete/reopen/delete/dismiss, app resume, reboot, timezone or clock
changes. Compute each plan from a fresh authoritative task/consent/permission
snapshot and the latest durable ledger. Unknown data must not authorize posting.
A corrupt duplicate-key ledger produces cancellation-only cleanup.

Use one synchronizer per native scheduling store. It serializes mutations,
confirms cancellations before new upserts, reports stale requests as superseded,
and continues accepting retries after failures. Applied means only that the plan
was processed by the port; it is not proof of notification delivery. An uncertain upsert reply is resolved
by rereading the durable ledger, not blindly posting again. Persist revoked
consent/owner changes before reconciling. At every upsert and at delivery time,
recheck current consent, permission/channel state, active owner, task eligibility,
receipt and expiry. A receiver may not trust its original intent as authority.
A cancellation already in flight can finish after a newer request; the newer
plan is built only after that mutation finishes.

No device permission may be granted automatically. A real adapter needs Android
compilation plus explicit device opt-in, denial/revocation, redacted lock-screen
content, duplicate prevention, edit/delete races, restart/reboot, timezone/DST,
and battery-restriction checks. Until then, there is no Android notification
scheduling or delivery evidence and no user-facing enable control.
