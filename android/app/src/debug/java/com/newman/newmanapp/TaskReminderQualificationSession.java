package com.newman.newmanapp;

/** Debug-source-only acceptance coordinator. No Android adapter or entry point exists. */
public final class TaskReminderQualificationSession {
    public interface Port {
        boolean permissionGranted();
        void requestPermission(Runnable returned) throws Exception;
        void scheduleSynthetic(Sample sample) throws Exception;
        void cancelAllSynthetic() throws Exception;
    }
    public static final class Sample {
        public final String key = "newman-debug-synthetic-reminder-v1";
        public final String title = "New Man";
        public final String body = "You have a task to review.";
        public final long notBeforeUtcMillis;
        public final boolean inexact = true;
        private Sample(long now) { notBeforeUtcMillis = Math.addExact(now, 60_000); }
    }
    public enum State { OFF, WAITING_FOR_PERMISSION, SCHEDULED, UNCONFIRMED }
    private final Port port;
    private final java.util.function.LongSupplier clock;
    private final boolean allowedBuild;
    private final int api;
    private long generation;
    private boolean consent;
    private State state = State.OFF;

    public TaskReminderQualificationSession(String applicationId, boolean debuggable,
            int api, Port port, java.util.function.LongSupplier clock) {
        this.allowedBuild = debuggable && "com.newman.newmanapp.beta.dev".equals(applicationId) && api >= 26;
        this.api = api;
        this.port = java.util.Objects.requireNonNull(port);
        this.clock = java.util.Objects.requireNonNull(clock);
        // Construction never reads permission, requests it, or touches an OS job.
    }
    public synchronized State state() { return state; }

    /** A future host may call only from a labelled, explicit synthetic-test action. */
    public synchronized void beginExplicitTest(boolean userInitiated, boolean acceptedInexact) {
        if (!allowedBuild || !userInitiated || !acceptedInexact || consent) return;
        disable();
        if (state != State.OFF) return; // Cleanup must be confirmed before reuse.
        consent = true;
        long requestedGeneration = generation;
        try {
            if (api >= 33 && !port.permissionGranted()) {
                state = State.WAITING_FOR_PERMISSION;
                port.requestPermission(() -> afterPermission(requestedGeneration));
            } else {
                afterPermission(requestedGeneration);
            }
        } catch (Exception failure) { failClosed(); }
    }

    private synchronized void afterPermission(long expectedGeneration) {
        if (!allowedBuild || !consent || generation != expectedGeneration || state == State.SCHEDULED) return;
        try {
            // Callback success is not authority: inspect current permission again.
            if (api >= 33 && !port.permissionGranted()) { disable(); return; }
            port.scheduleSynthetic(new Sample(clock.getAsLong()));
            // A host callback/revocation can occur reentrantly inside the port.
            if (!consent || generation != expectedGeneration || (api >= 33 && !port.permissionGranted())) {
                disable();
                return;
            }
            state = State.SCHEDULED;
        } catch (Exception failure) { failClosed(); }
    }
    public synchronized void disable() {
        consent = false;
        generation++;
        if (!allowedBuild) { state = State.OFF; return; }
        try { port.cancelAllSynthetic(); state = State.OFF; }
        catch (Exception failure) { state = State.UNCONFIRMED; }
    }
    public synchronized void onPermissionRevokedOrHostStopped() { disable(); }
    private void failClosed() { disable(); state = State.UNCONFIRMED; }
}
