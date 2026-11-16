# Task recurrence

Repeat on completion is Off by default in the task editor. An open task can opt
in to Daily or Selected weekdays (at least one day). The selected rule is saved
on that occurrence and inherited by its successor. Saving or editing a rule
alone creates no task. Completing an open occurrence creates at most one next
open occurrence in the same transaction as its completion and ordered checklist.
A failed child insert or parent update rolls back everything, leaving the source
incomplete and safe to retry.

Set Repeat on completion to Off on the next open occurrence to stop. Changing
its title, date, checklist or weekdays affects that occurrence and the future
successor created from it; it does not rewrite completed history or any existing
successor. Completed or previously handled occurrences do not offer rule edits;
edit the next open occurrence instead. A completed ordinary task can be reopened
to opt in before completion if it has not already handled a recurring completion.

A persisted handled flag and stable successor ID prevent duplicates across
retries and restarts. A repeated completion request does not change the original
completion timestamp. Reopening does not remove a successor, and completing an
already handled occurrence again does not create another—even if its successor
was deleted. Deleting an occurrence never deletes other occurrences; deleting
the pending successor stops that chain. No tasks appear merely as time passes.

The next due date is strictly after the later of the source due date and today's
local calendar date. Undated tasks use today. Missed dates are skipped rather
than creating a backlog. Calendar arithmetic uses the recurrence engine rather
than elapsed 24-hour intervals and skips nonexistent local dates. If no valid
future date remains through year 9999, completion fails without changing the
source; turn its repeat rule Off to complete without a successor.

Successors copy the source's current title and ordered subtask titles, with every
subtask unchecked. They have no time block or priority. The completed occurrence
keeps its checklist, completion time, time block and priorities. This workflow
requests no background execution or notification permissions. An opted-in in-app reminder time is inherited with a fresh acknowledgement; see TASK_REMINDERS.md.

## Manual next occurrence

The repeat icon on completed Tasks rows still opens Schedule next occurrence.
It previews Daily or Selected weekdays and creates one independent task with
Repeat on completion Off. Cancel changes nothing. It shares the automatic
workflow's successor ID: if either workflow already created that next task, the
other returns it unchanged, preserving its rule and edits. Enabling automatic
repeating on an ancestor does not change a manually scheduled successor; enable
the rule on that open successor instead. The result message shows its actual
saved date. After explicitly deleting a successor, manual scheduling can create
a replacement, which starts with automatic repeating Off.

Schema v12 adds a nullable weekday mask and a handled flag to tasks. Existing
v11 tasks default to Off and not handled; subtasks, Word data and older schema
snapshots remain intact. Daily uses mask 0; selected ISO weekdays use bits 0–6.
