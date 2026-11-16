# In-app task reminders

Task reminders are Off by default. In the task editor, enable In-app reminder,
set a due date and enter a local time from 00:00 to 23:59. The editor names the
scope explicitly: reminders appear in Today and Tasks while New Man is open.
This feature does not post Android notifications, request permissions, wake the
app, or claim background delivery.

The foreground inbox evaluates the current local calendar date and wall-clock
minute every 30 seconds while resumed, and refreshes on app resume and task
writes. It uses today's actual clock, independent of the planner's selected day.
A reminder becomes visible once its due date/time arrives. Missed reminders stay
visible as overdue; no catch-up popups or repeated modal prompts are generated.
There is one inbox entry per pending task occurrence.

Dismiss stores an acknowledgement for that occurrence's due date and selected
time. It survives restart and a repeated clock hour. Completion hides the entry;
reopening reveals it only if it was not dismissed. Deletion removes it. Editing
the due date or reminder time re-arms it; title/checklist edits preserve a prior
acknowledgement. Off clears the reminder and acknowledgement. Removing the due
date also clears both. A stale Dismiss cannot acknowledge a newly edited task;
a failed acknowledgement write leaves the reminder visible and retryable.

Daily/weekday automatic successors inherit the opted-in local time with a fresh
acknowledgement. Manual Schedule next occurrence creates an independent task
with reminder Off, unless an already-existing successor is returned unchanged.

Times follow the device's current local clock, not a fixed time zone or UTC
instant. A nonexistent spring-forward time becomes due at the first foreground
evaluation after the clock passes that wall time. The autumn repeated hour does
not re-arm a dismissed reminder. Clock rollback or travel to another time zone
does not clear acknowledgement for the same saved due date/time. A task remains
one occurrence; an overdue task does not create one reminder for every missed day.

Schema v13 adds a nullable local-minute field and nullable acknowledgement key.
All v12 tasks migrate with reminder Off; recurrence, completion history, subtasks,
Word rows, and older schema snapshots are preserved. Actual Android runtime
notification delivery and device qualification remain separate gates.
