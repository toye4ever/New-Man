package com.newman.newmanapp;

/** Portable fake ports only; never a permission request, notification or device call. */
public final class TaskReminderQualificationSessionTest {
    private static final class Fake implements TaskReminderQualificationSession.Port {
        boolean granted, failCancel, failSchedule;
        int reads, requests, scheduled, cancelled;
        Runnable callback, duringSchedule;
        TaskReminderQualificationSession.Sample sample;
        public boolean permissionGranted() { reads++; return granted; }
        public void requestPermission(Runnable returned) { requests++; callback = returned; }
        public void scheduleSynthetic(TaskReminderQualificationSession.Sample value) throws Exception {
            if (failSchedule) throw new Exception("injected");
            scheduled++; sample = value;
            if (duringSchedule != null) duringSchedule.run();
        }
        public void cancelAllSynthetic() throws Exception {
            cancelled++;
            if (failCancel) throw new Exception("injected");
        }
    }
    private static TaskReminderQualificationSession session(Fake fake) {
        return new TaskReminderQualificationSession("com.newman.newmanapp.beta.dev", true, 33, fake, () -> 1000);
    }
    public static void main(String[] args) throws Exception {
        Fake fake = new Fake();
        var test = session(fake);
        assert test.state() == TaskReminderQualificationSession.State.OFF;
        assert fake.reads + fake.requests + fake.scheduled + fake.cancelled == 0;
        test.beginExplicitTest(false, true); test.beginExplicitTest(true, false);
        assert fake.requests + fake.reads + fake.scheduled + fake.cancelled == 0;
        test.beginExplicitTest(true, true);
        assert fake.requests == 1 && fake.scheduled == 0;
        test.beginExplicitTest(true, true);
        assert fake.requests == 1;
        var oldCallback = fake.callback;
        test.disable(); fake.granted = true; oldCallback.run();
        assert fake.scheduled == 0; // Off invalidates an in-flight permission callback.
        test.beginExplicitTest(true, true);
        assert fake.scheduled == 1 && fake.sample.notBeforeUtcMillis == 61_000;
        assert fake.sample.inexact && fake.sample.body.equals(TaskReminderNativePolicy.BODY);
        assert fake.sample.title.equals(TaskReminderNativePolicy.TITLE);
        oldCallback.run(); assert fake.scheduled == 1;
        test.onPermissionRevokedOrHostStopped();
        assert test.state() == TaskReminderQualificationSession.State.OFF;
        fake.granted = false; test.beginExplicitTest(true, true); fake.callback.run();
        assert fake.scheduled == 1 && test.state() == TaskReminderQualificationSession.State.OFF;
        fake.failCancel = true; test.beginExplicitTest(true, true);
        assert test.state() == TaskReminderQualificationSession.State.UNCONFIRMED;
        assert fake.scheduled == 1;
        fake.failCancel = false; fake.failSchedule = true; fake.granted = true;
        test.beginExplicitTest(true, true);
        assert test.state() == TaskReminderQualificationSession.State.UNCONFIRMED;
        for (String id : new String[] {"com.newman.newmanapp.beta", "other.dev"}) {
            Fake excluded = new Fake();
            new TaskReminderQualificationSession(id, true, 33, excluded, () -> 0).beginExplicitTest(true, true);
            assert excluded.reads + excluded.requests + excluded.scheduled + excluded.cancelled == 0;
        }
        Fake reentrant = new Fake(); reentrant.granted = true;
        var stopped = session(reentrant);
        reentrant.duringSchedule = stopped::onPermissionRevokedOrHostStopped;
        stopped.beginExplicitTest(true, true);
        assert stopped.state() == TaskReminderQualificationSession.State.OFF;
        assert reentrant.cancelled >= 3; // Cleanup before, during and after stale schedule.
        Fake revoked = new Fake(); revoked.granted = true;
        var revoking = session(revoked);
        revoked.duringSchedule = () -> revoked.granted = false;
        revoking.beginExplicitTest(true, true);
        assert revoking.state() == TaskReminderQualificationSession.State.OFF;
        Fake legacy = new Fake();
        var pre33 = new TaskReminderQualificationSession("com.newman.newmanapp.beta.dev", true, 32, legacy, () -> 0);
        pre33.beginExplicitTest(true, true);
        assert legacy.requests == 0 && legacy.scheduled == 1;
        Fake unsupported = new Fake();
        new TaskReminderQualificationSession("com.newman.newmanapp.beta.dev", true, 25, unsupported, () -> 0).beginExplicitTest(true, true);
        assert unsupported.reads + unsupported.requests + unsupported.scheduled + unsupported.cancelled == 0;
        Fake release = new Fake();
        new TaskReminderQualificationSession("com.newman.newmanapp.beta.dev", false, 33, release, () -> 0).beginExplicitTest(true, true);
        assert release.reads + release.requests + release.scheduled + release.cancelled == 0;
        System.out.println("TaskReminderQualificationSessionTest: all fake-port assertions passed");
    }
}
