# Synthetic reminder qualification — inactive debug acceptance boundary

`TaskReminderQualificationSession` exists only in `src/debug/java`; its tests
are in `src/testDebug/java`, so release tests do not depend on debug-only types.
There is no caller, host screen, method channel registration, Android Port
implementation, receiver declaration, permission declaration or live toggle in
this unit. The production backend still returns `qualified() == false`.
This coordinator is a tested acceptance boundary, not a working delivery route.

It admits only an explicitly debuggable `com.newman.newmanapp.beta.dev` context,
API 26+, user-initiated action and acknowledgement of inexact delivery. Default
Off construction makes no port calls. It confirms synthetic cleanup before
reuse. A future API 33+ port may request POST_NOTIFICATIONS only after that action;
a callback is not proof of permission and is checked against fresh state and a
generation token. Off, observed revocation or host stop invalidates pending
callbacks and cancels synthetic jobs. Failed cleanup/scheduling is unconfirmed,
never reported as Off/scheduled success. Duplicate callbacks/actions do not
schedule another example. Fixed synthetic content and a fixed replacement key
keep this session to one example, no task/title/contact inputs. Timestamp is one
minute after the injected clock; actual inexact delivery can be delayed or lost.

The Port contract is deliberately separate from the current task backend: that
backend validates real task database authority and must not be repurposed by
inserting fake rows or bypassing authority. A future debug adapter must own only
a separate synthetic ledger, alarm action, notification tag and channel; it must
recheck debug identity, current consent and permission at delivery. Receiver and
permission entries, if later reviewed, belong exclusively to debug source sets.
Never change the main/release manifest or enable production qualification to run
this test. No adapter or UI is authorized implicitly by these acceptance notes.

## Reproduce without a device

With JDK 21, run `JAVA_HOME=/path/to/jdk-21 bash tools/check_native_reminder_policy.sh`.
The fourth suite uses only fakes and injected time. It covers default Off, rejected
consent, repeated action/callback, denied permission, Off during callback, observed
revocation/host stop, fixed redacted content, cancellation/scheduling failures,
wrong package and release exclusion. These are portable Java assertions; they do
not prove Android manifest merging, Android API linking or notification delivery.
The published e99ee2a baseline built ARM64 debug in run 43962308608; it did not
contain these private classes. Exact-head native CI/device evidence is pending.

## Future owner-driven Galaxy acceptance — not executable in this unit

Do not perform these steps until a separately reviewed debug adapter/host exists
and the exact candidate's native compile and compiled-manifest checks pass.
No device action or permission grant was performed while preparing this unit.

1. Record exact candidate Git SHA, APK hash, Galaxy model/Android version and
   package. Use an authorized isolated beta.dev debug install; preserve existing
   beta data. Verify production/profile APKs contain no synthetic route, receiver
   or notification permission from the test. Do not use a signing key or release.
2. Before selecting any test action, observe no permission prompt or scheduled
   job. Show the fixed example and inexact timing notice; no real task, note,
   Scripture, history or contact content may be selectable or loaded.
3. Owner explicitly chooses the synthetic test and acknowledges inexact timing.
   On Android 13+, deny the OS prompt first: no job or notification. Try again
   only through another explicit action; never jump automatically to settings.
4. Owner may explicitly allow the test. Observe at most one generic example,
   recording requested/actual times without promising minute-exact delivery.
   Repeat action/callback, foreground/background and process restart must not
   duplicate it. Inspect lock-screen text and intents for synthetic/generic data.
5. Disable while waiting for permission, after scheduling and during delivery;
   return an old callback after disabling. Observe no re-enable or new job.
   Inject cancellation failure: report unconfirmed; a disarmed ledger must reject
   a queued delivery even if the OS job survives cleanup failure.
6. Owner-driven notification revocation/channel blocking, clock/timezone change,
   reboot, expiry and Doze require separate observations. Recheck consent and
   permission at delivery; cancel on observed revocation/host stop. A revoke-and-
   restore interval while absent is not observable and must not be represented
   as permanently disabling the app's installation consent.
7. Finish with Disable and confirmed synthetic-only cleanup. Record failures and
   leave production reminders off; success qualifies only this exact synthetic
   debug adapter/device combination, not real-task reminder delivery.
