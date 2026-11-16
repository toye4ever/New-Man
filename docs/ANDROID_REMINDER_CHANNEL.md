# Dormant Android reminder method-channel protocol

This unit implements the Dart side of `com.newman.newmanapp/task_reminders_v1`.
There is no native handler, app wiring, UI toggle, manifest permission, channel
creation, alarm, receiver or device operation. Construction makes no platform
call. Missing/malformed native support reports unavailable and cannot authorize
delivery. Native compilation and all Android notification delivery remain
pending. This bridge complements ANDROID_REMINDER_BOUNDARY.md; it is not a
qualified native adapter.

All requests/replies carry integer `protocol: 1`. No request contains a raw task
identifier, task title, note, checklist or Scripture text. Upserts contain only
the boundary's opaque keys, generic title/body, UTC timing bounds, `inexact`
delivery mode, `generic` redaction and a consent revision guard. Native error
strings are not logged or forwarded; they may contain private diagnostics.

## State and explicit opt-in

`getState` is read-only and never prompts. Supported state must report Android
API 23+, `deliveryMode: inexact`, `redaction: generic`, an opaque installation
token (16–128 alphanumeric/underscore/hyphen characters), nonnegative revision,
boolean notification/consent/acknowledgement flags and a recognized permission
state (`notRequested`, `granted`, `denied`, `unavailable`). Unknown protocol,
capability, type or permission fails closed. Installation-local opt-in is Off
by default and must be persisted only by the eventual app-private native store.

Only `enableFromUserAction` can be sent as an enabling request, and only after
both explicit user intent and acknowledged approximate timing. It includes the
expected hashed installation scope and consent revision, never the raw token.
The native handler must atomically reject a stale scope/revision, request
POST_NOTIFICATIONS only from this explicit handler on API 33+, and persist
Enabled only after actual permission is granted. It must never request an
exact-alarm or Accessibility permission. Below API 33 there is no notification
runtime prompt; system/channel enablement still gates delivery.

Denial/dismissal returns disabled state only after confirmed pending/posted cleanup. A reply claiming Enabled without
permission/channel access triggers `disableAndCancelAll` cleanup and is not
accepted as authorization. A stale installation or backwards revision reply
cannot confirm enabling. No device permission is granted by tests or this unit.

## Reconciliation and cancellation

A future resume/task/permission reconciliation calls `reconcileAccess`. It reads
fresh state; if consent, acknowledgement, system notifications or permission is
blocked, `cancelAllPending` must confirm that all reminder jobs were cancelled
and posted reminders cleared. It does not silently change the user's stored
opt-in or request permission. An upsert repeats this access check and will not
schedule when blocked. OS settings and receiver-time access must still be
rechecked natively; a Dart snapshot is not authority to post later.

Upsert requires a future UTC start, later UTC expiry and full 64-character opaque
keys. Its reply must match key, installation scope and revision, and explicitly
confirm durable ledger commit, inexact timing and generic redaction. Native code
must atomically compare the expected revision before mutation. A changed scope
cannot upsert another installation's reminders.

`cancel` needs no permission but requires the exact key and confirmation of both
job cancellation and posted-reminder cleanup. Already-absent keys must return
that same confirmed idempotent result. Explicit Off uses `disableAndCancelAll`:
persist Off first, invalidate older revision-guarded work, cancel every future
job and posted reminder, then acknowledge all three results. Preserve delivered
receipts so re-enabling or clock rollback cannot replay an old occurrence.

Missing handlers, partial/wrong-key replies, platform errors and timeouts are not
successful cancellations or schedules. A late reply does not trigger automatic
retry or change state. After uncertain outcomes, reread the authoritative native
ledger before another plan; native idempotent full-key operations are mandatory.
The existing synchronizer orders cancellation before new upserts and suppresses
stale queued work. Future UI controllers must serialize explicit consent commands
and disregard stale revisions/results, rather than displaying an old enable reply
as current state. The future native handler must additionally guard in-flight
operations and receiver delivery against opt-out, permission revocation, task
changes, stale revisions and expiry.

## Remaining qualification

Implement app-private consent/revision storage, native ledger/receipt reads,
method-channel handlers, generic notification/channel setup, inexact alarms and
non-exported receiver lifecycle handling before connecting a user enable flow.
Then run native compilation and explicitly authorized device checks for opt-in,
denial/revocation, lock-screen redaction, reboot, DST/timezone changes, expiry,
battery restrictions and cancellation races. Mocked channel tests are portable
protocol evidence only and do not prove any Android OS operation succeeded.
