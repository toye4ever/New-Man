# Owner-run Galaxy smoke — 5–10 minutes

**Current hardware status: NOT RUN.** This page was prepared from source, not a
handset session. It checks one exact candidate with synthetic data, not production
Guard, Android notification delivery, offline audio, editions or partner sharing.

## Prerequisites — otherwise BLOCKED

- Use a separately authorized, already obtained and verified debug APK. This
  page grants no artifact upload/download, sideload setting or install approval.
  Candidate availability/installation remains a separate gate.
- Record Git SHA, APK SHA-256, exact CI result, Galaxy model, Android version,
  local date/time/timezone and owner initials. Require compiled debug manifest
  checks for that exact candidate, not a previous head.
- Require **`com.newman.newmanapp.beta.dev`**, backups off and debug Guard
  containment. Never install the unsigned release APK. Preserve the existing
  **`.beta`** install: no replacement, uninstall, Clear storage or migration.
- Clean means a separately authorized fresh `.beta.dev` install with no personal
  data. If `.beta.dev` already has useful data, stop; do not clear it for this test.
- This candidate must show **New Man Dev**; public beta stays **New Man Beta**.
  Older candidates may share the Beta label. Confirm package identity using
  trusted installation/package evidence before launching; label/icon alone is
  insufficient. Unknown identity or personal data means STOP.
- No sign-in, contacts, import, sharing, Accessibility, usage access, overlay or
  notification permission is needed. Do not enable Guard developer tools or the
  dormant synthetic native reminder route. Stop on an unexpected prompt and do
  not approve it to continue.

Use only the strings below. Evidence stays local and must show only synthetic
app data; crop system notifications/identifiers. No logs/database upload is part
of this checklist. Download time is unpredictable: mark PENDING if it exceeds
the budget, then resume later. A started download is not an offline pass.

## Timed checks and evidence

| Time | Owner action | PASS / evidence | FAIL or stop |
| --- | --- | --- | --- |
| 0:00–1:00 | Launch verified `.beta.dev`, open Today. | Record package/hash; clean tasks and normal shell, no prompts. | Wrong/unknown package, personal records or prompt: STOP. |
| 1:00–3:00 | **Add task**: `SMOKE A`, due today. **Add subtask** twice: `Step A`, `Step B`. Set **Repeat on completion → Daily**. Enable **In-app reminder**, time `00:00`, **Save task**. Reopen/edit, check only Step A, save. | One open task, exact two titles, only Step A checked; Daily and local time persist. Record editor/result. | Duplicate/missing row or field, save error, unexpected OS prompt. In-app copy must say no background notifications. |
| 3:00–4:00 | Today → **In-app reminders**. Dismiss using **Dismiss reminder for SMOKE A**. Navigate away/back. | Exactly one entry before; none after; task still open. Record counts. 00:00 is due already; no clock changes needed. | Duplicate/reappearing entry, Dismiss completing the task, OS notification/prompt. |
| 4:00–5:30 | Complete SMOKE A once. **Next day** or **Manage tasks**: inspect tomorrow. Return to original, reopen/re-complete once; inspect tomorrow again. Edit successor repeat to **Off**, save/reopen. | One completed original and exactly one open successor due tomorrow; same subtasks reset unchecked. Still one successor after retry; Off persists. Record dates/counts/Off. | Missing/duplicate successor, stale subtask checks or lost rule. Do not complete successor for cleanup. This does not qualify weekdays/DST. |
| 5:30–7:00 | Word → **Versions**. If needed, owner explicitly selects existing KJV **Download** once while online; wait for processing and ready-offline state. No NLT/provider setup. | Record verified installed state. Previously downloaded KJV may be used within this isolated candidate. | Failure or slow download: PENDING; do not delete files/force an update. Bundled sample is not a complete installation. |
| 7:00–8:30 | If owner chooses, temporarily enable airplane mode with Wi-Fi/mobile data off. Exit Reader to Word home, then reopen Bible → KJV: **Genesis 1**, **Revelation 22**. Do not press Listen. Restore original connectivity. | Both chapters load in a newly opened Reader while offline. Record references/connectivity and restoration. | Network/provider error or missing chapter: FAIL. Airplane step declined: NOT RUN. This tests neither audio nor every verse. |
| 8:30–9:30 | Accountability → **Start private draft**. Select only **Include Reflection**, type `SMOKE private draft`, **Review draft**. **Edit draft**, **Cancel draft**. Start/type again, leave for Today, return. | Review has only manual Reflection, no Next step/send action. Cancel clears it. Tab departure discards second draft; return shows Start private draft. Record review/empty return. | Retained draft, extra app data, contact/share/send action or prompt. |
| 9:30–10:00 | Close/reopen test app once; inspect Manage tasks and Accountability. | Synthetic task/subtask state and repeat Off persist; old dismissed reminder absent; no retained check-in. Record relaunch result; do not assume OS process death. | Lost/duplicated data or retained draft. Silence is not Android background-delivery evidence. |

Keep synthetic rows for review. Later optional UI cleanup may delete only the
explicitly named synthetic rows in the verified `.beta.dev` install. Never use
bulk delete, Clear storage, uninstall, restore or filesystem edits against either
installation. No phone clock/timezone or Guard/notification settings change is
part of this smoke.

Leaving Reader and reopening it avoids treating an unchanged visible page as
newly read evidence. Returning from Recents alone is not proof of process death;
this quick smoke does not qualify cold-process/power-loss recovery. Do not use
ADB, force-stop/settings, storage edits or a device reboot to expand its scope.
Record any actual restart behavior separately without claiming an unobserved
process exit.

## Failure and recovery

Stop the affected row and record FAIL (observed defect) or BLOCKED/PENDING (missing
prerequisite/delay). Continue only independent safe rows. Unrun never means PASS.
Report candidate SHA, step and synthetic result; no private databases/global logs.

For crash/save error, close/reopen the same test package once and record survival;
do not repeatedly reinstall, clear storage or grant permissions. Wrong identity,
personal data or unexpected prompt means close without approving/changing it.
For duplicate successors, stop toggling and preserve dates/counts as evidence.

For KJV failure, leave content intact and reopen the existing installed edition.
An ordinary retry may be chosen later by the owner; never manipulate `.previous`
or stages on the phone. [File recovery](KJV_FILE_RECOVERY.md) is separately tested
with temporary synthetic fixtures, not proven by this smoke. Restore original
connectivity if the optional airplane-mode step was used.

## Result record

`SHA / APK hash / CI: ____`  `Galaxy / Android / local zone / elapsed: ____`

`Identity __ Planner/subtasks __ In-app reminder __ Recurrence/Off __`

`KJV install __ Fresh airplane reading __ Draft discard __ Restart __`

Use PASS / FAIL / BLOCKED / NOT RUN per item. Overall PASS requires every row
passed on the recorded candidate; declined offline testing leaves that gate open.
All hardware items currently remain **NOT RUN**.
