# Undated time-block carryover

An open task with no due date/priority and only a past-day block previously
matched no Today section after that block day ended. The provided Nov 16 → Nov 17
projection reproduction failed with an empty combined projection before this fix.

Unscheduled now includes open, undated tasks whose block date is strictly before
the selected local day. It returns the original task/block metadata; it neither
moves the block to today nor clears its date/times. Current-day blocks remain
Scheduled. Future blocks and completed tasks do not enter this carryover group.
Tasks with due dates retain their existing Due/Overdue/other placement, avoiding
new Unscheduled duplicates. Existing unblocked-task behavior remains unchanged.

Projection regressions cover the supplied boundary, multiple days, date/time
normalization, current/future/completed blocks, due/overdue separation and exact
metadata retention. The widget regression opens the carried task from Unscheduled,
verifies its old block date, saves it and checks retained date/times through the
real task service/SQLite repository. Fixtures are synthetic and in-memory; no
real device, calendar, network, migration or automatic rescheduling is involved.
The preceding KJV search commit is preserved unchanged as a separate unit.
