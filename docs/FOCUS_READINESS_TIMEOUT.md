# Bounded Focus readiness read

DefaultGuardReadinessService now bounds the probe Future to five seconds and
maps timeout to the existing probeFailed report. Focus leaves its checking state
and enables the existing Try again action. Successful, failed and unsupported
reads retain their existing evaluator/error behavior.

Only the read is bounded. Future.timeout does not cancel the underlying native
request, alter permission state or stop a native operation. Native channels,
selectors, tracking, qualification actions and permissions are unchanged.
A late completed first read cannot replace the later Retry report.

The widget regression uses the real service and Focus UI with a hung fake first
probe, fake-clock checks immediately before/at five seconds, an enabled Retry,
a successful second probe and a late failed first snapshot. No OS/device call is
performed. A successful read is not protection qualification; the fixture does
not claim any target is protected. Actual device behavior remains a separate
gate. This unit is separate from the approved artifact-only delivery commit.
