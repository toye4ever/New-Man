# Explicit task repeats

In Tasks, complete a task and choose its repeat icon, then choose Daily or
Selected weekdays. The dialog previews the next date. Schedule task saves one
independent open task; Cancel changes nothing. This is a manual next-occurrence
workflow, not an automatically persisted recurring series. Completing either
task does not create further tasks or schedule platform notifications.

The next due date is strictly after the later of the source due date and today's
local calendar date. Undated tasks use today. Missed occurrences are skipped;
there is no catch-up backlog. Calendar arithmetic uses the existing recurrence
engine, not elapsed 24-hour intervals, and skips nonexistent local dates. The
save recalculates using the current clock if the dialog spans midnight.

The completed source, its completion time, checklist, time block and priorities
remain intact. The new task copies its current title and ordered subtask titles,
with every subtask unchecked; it has no time block or priority. Saves are atomic,
including children. A failed save leaves no partial successor. Open, deleted or
changed source tasks cannot create a successor from a stale dialog.

Each source has a stable successor identifier. Repeating the action, including
after restarting, returns that successor unchanged, even if a different date
rule is selected. Editing its title, date or checklist is preserved. The result
message shows its actual saved date. Deleting the source does not delete its
successor; deleting the successor does not reopen the source. After explicitly
deleting a successor, the source can create a replacement through this action.
Reopening and completing the source does not create anything automatically.
To advance again, complete the successor and explicitly schedule its next task.

Schema v11 and its subtask records are unchanged by this workflow. Automatic
series rules, exceptions, and reminder delivery remain separate work.
