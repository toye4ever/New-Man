package com.newman.newmanapp;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Set;

/**
 * Android-independent, process-local lease for the bounded Guard qualification test.
 *
 * <p>The caller supplies a monotonic elapsed-time clock and live consent/service facts.
 * No state from this class is persisted.</p>
 */
public final class GuardQualificationLease {
    public static final long MIN_DURATION_MINUTES = 15L;
    public static final long MAX_DURATION_MINUTES = 240L;
    public static final long WINDOW_ENTRY_SETTLE_MILLIS = 100L;
    public static final long MAX_WINDOW_EVENT_AGE_MILLIS = 1_000L;
    private static final long MILLIS_PER_MINUTE = 60_000L;

    public interface Clock {
        long elapsedRealtimeMillis();
    }

    /** Applies Android's active or restrictive-idle event subscription. */
    @FunctionalInterface
    public interface EventDeliveryUpdater {
        boolean update(boolean active);
    }

    /**
     * Tracks only event-delivery state that an external update has confirmed.
     *
     * <p>Every external apply first makes the state unknown because Android may
     * change {@code serviceInfo} before the updater returns false or throws. A
     * failed active apply therefore performs a real restrictive-idle update;
     * it never trusts an older confirmed-idle value. Only a successful updater
     * call establishes a known state.</p>
     */
    public static final class EventDeliveryTransaction {
        private enum AppliedState {
            UNKNOWN,
            IDLE,
            ACTIVE
        }

        private final GuardQualificationLease lease;
        private AppliedState appliedState = AppliedState.UNKNOWN;

        public EventDeliveryTransaction(GuardQualificationLease lease) {
            if (lease == null) {
                throw new IllegalArgumentException("A qualification lease is required.");
            }
            this.lease = lease;
        }

        /** Invalidates knowledge when Android creates or rebinds the service. */
        public synchronized void invalidate() {
            appliedState = AppliedState.UNKNOWN;
        }

        public synchronized boolean isKnownActive() {
            return appliedState == AppliedState.ACTIVE;
        }

        public synchronized boolean isKnownIdle() {
            return appliedState == AppliedState.IDLE;
        }

        public synchronized boolean isUnknown() {
            return appliedState == AppliedState.UNKNOWN;
        }

        /**
         * Applies the requested subscription and fails the real lease when the
         * request cannot be confirmed. A failed active request includes its
         * restrictive rollback attempt before this method returns.
         *
         * @return the failure snapshot, or {@code null} when the requested
         *     subscription is confirmed or an inactive no-updater request is
         *     safely skipped without changing the known platform state.
         */
        public synchronized Snapshot applyOrFailLease(
                boolean active,
                EventDeliveryUpdater updater) {
            if (updater == null) {
                // A process can report its initial inactive lease before Android
                // creates the service. That is not an attempted platform update,
                // so it must not invent an error or a confirmed idle OS state.
                // An active request (or loss of the only known-active updater)
                // cannot be treated as safe, however.
                if (!active && appliedState != AppliedState.ACTIVE) {
                    return null;
                }
                appliedState = AppliedState.UNKNOWN;
                return lease.fail("event_delivery_unavailable");
            }
            if (apply(active, updater)) {
                return null;
            }
            return lease.fail("event_delivery_unavailable");
        }

        private boolean apply(boolean active, EventDeliveryUpdater updater) {
            AppliedState requested = active ? AppliedState.ACTIVE : AppliedState.IDLE;
            if (appliedState == requested) {
                return true;
            }

            appliedState = AppliedState.UNKNOWN;
            if (invoke(updater, active)) {
                appliedState = requested;
                return true;
            }

            if (active && invoke(updater, false)) {
                appliedState = AppliedState.IDLE;
            }
            return false;
        }

        private static boolean invoke(EventDeliveryUpdater updater, boolean active) {
            try {
                return updater.update(active);
            } catch (RuntimeException error) {
                return false;
            }
        }
    }

    public enum State {
        IDLE,
        RUNNING,
        PAUSED,
        COMPLETED,
        ENDED,
        INTERRUPTED,
        ERROR
    }

    public static final class Snapshot {
        private final State state;
        private final long remainingMillis;
        private final Set<String> selectedTargetIds;
        private final long wakeupToken;
        private final String detailCode;

        private Snapshot(
                State state,
                long remainingMillis,
                Set<String> selectedTargetIds,
                long wakeupToken,
                String detailCode) {
            this.state = state;
            this.remainingMillis = remainingMillis;
            this.selectedTargetIds = Collections.unmodifiableSet(
                    new LinkedHashSet<>(selectedTargetIds));
            this.wakeupToken = wakeupToken;
            this.detailCode = detailCode;
        }

        public State getState() {
            return state;
        }

        public long getRemainingMillis() {
            return remainingMillis;
        }

        public Set<String> getSelectedTargetIds() {
            return selectedTargetIds;
        }

        public long getWakeupToken() {
            return wakeupToken;
        }

        public String getDetailCode() {
            return detailCode;
        }
    }

    /** A decision about whether a real window transition should replace pending work. */
    public static final class WindowEntryDecision {
        private static final WindowEntryDecision IGNORE =
                new WindowEntryDecision(false, false, 0L);
        private static final WindowEntryDecision DEPARTURE =
                new WindowEntryDecision(true, false, 0L);

        private final boolean acceptedTransition;
        private final boolean shouldScheduleAction;
        private final long actionToken;

        private WindowEntryDecision(
                boolean acceptedTransition,
                boolean shouldScheduleAction,
                long actionToken) {
            this.acceptedTransition = acceptedTransition;
            this.shouldScheduleAction = shouldScheduleAction;
            this.actionToken = actionToken;
        }

        public boolean acceptedTransition() {
            return acceptedTransition;
        }

        public boolean shouldScheduleAction() {
            return shouldScheduleAction;
        }

        public long getActionToken() {
            return actionToken;
        }
    }

    private final Clock elapsedRealtimeClock;
    private final Clock uptimeClock;
    private State state = State.IDLE;
    private Set<String> selectedTargetIds = Collections.emptySet();
    private long remainingWhenPausedMillis;
    private long deadlineElapsedMillis;
    private long lastObservedElapsedMillis = -1L;
    private long lastObservedUptimeMillis = -1L;
    private long activationUptimeMillis = -1L;
    private long eventWatermarkUptimeMillis = -1L;
    private long actionToken;
    private long pendingActionToken;
    private long pendingEntryUptimeMillis = -1L;
    private String pendingTargetId;
    private long inFlightActionToken;
    private long wakeupToken;
    private String detailCode;

    public GuardQualificationLease(Clock clock) {
        this(clock, clock);
    }

    public GuardQualificationLease(Clock elapsedRealtimeClock, Clock uptimeClock) {
        if (elapsedRealtimeClock == null || uptimeClock == null) {
            throw new IllegalArgumentException("Both monotonic clocks are required.");
        }
        this.elapsedRealtimeClock = elapsedRealtimeClock;
        this.uptimeClock = uptimeClock;
    }

    public synchronized Snapshot start(
            Set<String> targetIds,
            long durationMinutes,
            boolean disclosureAccepted,
            boolean serviceAvailable) {
        if (isActiveState()) {
            throw new IllegalStateException("A qualification lease is already active.");
        }
        Set<String> selection = validateSelection(targetIds);
        if (!disclosureAccepted) {
            throw new IllegalArgumentException("Disclosure consent is required.");
        }
        if (!serviceAvailable) {
            throw new IllegalStateException("The accessibility service is unavailable.");
        }
        if (durationMinutes < MIN_DURATION_MINUTES || durationMinutes > MAX_DURATION_MINUTES) {
            throw new IllegalArgumentException("Duration is outside the allowed bounds.");
        }

        long now = readClockForStart();
        final long durationMillis;
        final long deadline;
        try {
            durationMillis = Math.multiplyExact(durationMinutes, MILLIS_PER_MINUTE);
            deadline = Math.addExact(now, durationMillis);
        } catch (ArithmeticException error) {
            release(State.ERROR, "clock_invalid");
            throw new IllegalStateException("The elapsed-time deadline is invalid.", error);
        }

        state = State.RUNNING;
        selectedTargetIds = selection;
        remainingWhenPausedMillis = 0L;
        deadlineElapsedMillis = deadline;
        detailCode = null;
        wakeupToken = nextToken(wakeupToken);
        if (!armEventGate()) {
            throw new IllegalStateException("The event clock is invalid.");
        }
        return snapshotWithoutClock();
    }

    public synchronized Snapshot snapshot(
            boolean disclosureAccepted,
            boolean serviceAvailable) {
        refresh(disclosureAccepted, serviceAvailable);
        return snapshotWithoutClock();
    }

    public synchronized Snapshot pause(
            boolean disclosureAccepted,
            boolean serviceAvailable) {
        refresh(disclosureAccepted, serviceAvailable);
        if (state != State.RUNNING) {
            throw new IllegalStateException("Only a running lease can be paused.");
        }
        long now = readClockForActiveState();
        if (state != State.RUNNING) {
            return snapshotWithoutClock();
        }
        long remaining = deadlineElapsedMillis - now;
        if (remaining <= 0L) {
            release(State.COMPLETED, "expired");
            return snapshotWithoutClock();
        }
        remainingWhenPausedMillis = remaining;
        deadlineElapsedMillis = 0L;
        state = State.PAUSED;
        wakeupToken = nextToken(wakeupToken);
        disarmEventGate();
        return snapshotWithoutClock();
    }

    public synchronized Snapshot resume(
            boolean disclosureAccepted,
            boolean serviceAvailable) {
        refresh(disclosureAccepted, serviceAvailable);
        if (state != State.PAUSED) {
            throw new IllegalStateException("Only a paused lease can be resumed.");
        }
        if (!disclosureAccepted || !serviceAvailable) {
            release(State.INTERRUPTED, "prerequisite_lost");
            return snapshotWithoutClock();
        }
        long now = readClockForActiveState();
        if (state != State.PAUSED) {
            return snapshotWithoutClock();
        }
        try {
            deadlineElapsedMillis = Math.addExact(now, remainingWhenPausedMillis);
        } catch (ArithmeticException error) {
            release(State.ERROR, "clock_invalid");
            return snapshotWithoutClock();
        }
        remainingWhenPausedMillis = 0L;
        state = State.RUNNING;
        wakeupToken = nextToken(wakeupToken);
        if (!armEventGate()) {
            return snapshotWithoutClock();
        }
        return snapshotWithoutClock();
    }

    public synchronized Snapshot end() {
        if (state != State.ENDED) {
            release(State.ENDED, "ended_by_user");
        }
        return snapshotWithoutClock();
    }

    public synchronized Snapshot interrupt(String reason) {
        release(State.INTERRUPTED, safeDetail(reason, "interrupted"));
        return snapshotWithoutClock();
    }

    public synchronized Snapshot fail(String reason) {
        release(State.ERROR, safeDetail(reason, "error"));
        return snapshotWithoutClock();
    }

    /**
     * Invalidates an active lease whenever Android creates or rebinds the service.
     * An initial idle connection only resets queued-event state.
     */
    public synchronized Snapshot onServiceConnectionOpened() {
        if (isActiveState()) {
            release(State.INTERRUPTED, "service_reconnected");
        } else {
            disarmEventGate();
        }
        return snapshotWithoutClock();
    }

    /** Releases immediately when the live service binding is lost. */
    public synchronized Snapshot onServiceConnectionClosed() {
        if (isActiveState()) {
            release(State.INTERRUPTED, "service_disconnected");
        } else {
            disarmEventGate();
        }
        return snapshotWithoutClock();
    }

    public synchronized boolean shouldRestrict(
            String targetId,
            boolean disclosureAccepted,
            boolean serviceAvailable) {
        refresh(disclosureAccepted, serviceAvailable);
        return state == State.RUNNING && selectedTargetIds.contains(targetId);
    }

    /**
     * Checks only lease and event-time metadata. Callers can avoid reading the
     * package payload entirely when this returns false.
     */
    public synchronized boolean canInspectWindowEntry(
            long eventUptimeMillis,
            boolean disclosureAccepted,
            boolean serviceAvailable) {
        refresh(disclosureAccepted, serviceAvailable);
        if (state != State.RUNNING) {
            return false;
        }
        long now = readUptimeForActiveState();
        return state == State.RUNNING
                && isFreshEventTime(eventUptimeMillis, now);
    }

    /**
     * Records a fresh app-change transition. Every admitted departure advances
     * the watermark and cancels a pending target entry. A selected target entry
     * receives a one-use token but is not yet allowed to act; the caller must
     * wait for the settle interval and call {@link #takeWindowEntryAction}.
     */
    public synchronized WindowEntryDecision evaluateWindowEntry(
            String targetId,
            long eventUptimeMillis,
            boolean disclosureAccepted,
            boolean serviceAvailable) {
        refresh(disclosureAccepted, serviceAvailable);
        if (state != State.RUNNING) {
            return WindowEntryDecision.IGNORE;
        }
        long now = readUptimeForActiveState();
        if (state != State.RUNNING || !isFreshEventTime(eventUptimeMillis, now)) {
            return WindowEntryDecision.IGNORE;
        }
        eventWatermarkUptimeMillis = eventUptimeMillis;
        clearPendingEntry();
        if (targetId == null || !selectedTargetIds.contains(targetId)) {
            return WindowEntryDecision.DEPARTURE;
        }
        actionToken = nextToken(actionToken);
        pendingActionToken = actionToken;
        pendingEntryUptimeMillis = eventUptimeMillis;
        pendingTargetId = targetId;
        return new WindowEntryDecision(true, true, actionToken);
    }

    /**
     * Rechecks a settled target entry immediately before the restrictive action.
     * Taking the action consumes the pending token so duplicate callbacks cannot act.
     */
    public synchronized boolean takeWindowEntryAction(
            long token,
            boolean disclosureAccepted,
            boolean serviceAvailable) {
        refresh(disclosureAccepted, serviceAvailable);
        if (state != State.RUNNING || token == 0L || token != pendingActionToken) {
            return false;
        }
        long now = readUptimeForActiveState();
        boolean canAct = state == State.RUNNING
                && pendingEntryUptimeMillis == eventWatermarkUptimeMillis
                && pendingTargetId != null
                && selectedTargetIds.contains(pendingTargetId)
                && isWithinEventAge(pendingEntryUptimeMillis, now)
                && now - pendingEntryUptimeMillis >= WINDOW_ENTRY_SETTLE_MILLIS;
        if (!canAct) {
            clearPendingEntry();
            return false;
        }
        inFlightActionToken = token;
        clearPendingEntry();
        return true;
    }

    /**
     * Commits the result of the restrictive platform action only when its token
     * still belongs to the current running lease.
     */
    public synchronized Snapshot completeWindowEntryAction(
            long token,
            boolean succeeded) {
        if (token == 0L || token != inFlightActionToken || state != State.RUNNING) {
            return snapshotWithoutClock();
        }
        inFlightActionToken = 0L;
        if (!succeeded) {
            release(State.ERROR, "global_action_failed");
            return snapshotWithoutClock();
        }
        long now = readUptimeForActiveState();
        if (state == State.RUNNING) {
            eventWatermarkUptimeMillis = Math.max(eventWatermarkUptimeMillis, now);
        }
        return snapshotWithoutClock();
    }

    public synchronized Snapshot onWakeup(
            long token,
            boolean disclosureAccepted,
            boolean serviceAvailable) {
        if (token != wakeupToken) {
            return snapshotWithoutClock();
        }
        refresh(disclosureAccepted, serviceAvailable);
        return snapshotWithoutClock();
    }

    private void refresh(boolean disclosureAccepted, boolean serviceAvailable) {
        if (!isActiveState()) {
            return;
        }
        if (!disclosureAccepted) {
            release(State.INTERRUPTED, "consent_withdrawn");
            return;
        }
        if (!serviceAvailable) {
            release(State.INTERRUPTED, "service_disconnected");
            return;
        }
        if (state != State.RUNNING) {
            readClockForActiveState();
            return;
        }
        long now = readClockForActiveState();
        if (state == State.RUNNING && now >= deadlineElapsedMillis) {
            release(State.COMPLETED, "expired");
        }
    }

    private long readClockForStart() {
        long now = elapsedRealtimeClock.elapsedRealtimeMillis();
        if (now < 0L || (lastObservedElapsedMillis >= 0L && now < lastObservedElapsedMillis)) {
            release(State.ERROR, "clock_invalid");
            throw new IllegalStateException("Elapsed time must be non-negative and monotonic.");
        }
        lastObservedElapsedMillis = now;
        return now;
    }

    private long readClockForActiveState() {
        long now = elapsedRealtimeClock.elapsedRealtimeMillis();
        if (now < 0L || (lastObservedElapsedMillis >= 0L && now < lastObservedElapsedMillis)) {
            release(State.ERROR, "clock_invalid");
            return 0L;
        }
        lastObservedElapsedMillis = now;
        return now;
    }

    private long readUptimeForActiveState() {
        long now = uptimeClock.elapsedRealtimeMillis();
        if (now < 0L || (lastObservedUptimeMillis >= 0L && now < lastObservedUptimeMillis)) {
            release(State.ERROR, "clock_invalid");
            return -1L;
        }
        lastObservedUptimeMillis = now;
        return now;
    }

    private boolean armEventGate() {
        long now = readUptimeForActiveState();
        if (state != State.RUNNING || now < 0L) {
            return false;
        }
        activationUptimeMillis = now;
        eventWatermarkUptimeMillis = now;
        pendingActionToken = 0L;
        return true;
    }

    private boolean isFreshEventTime(long eventUptimeMillis, long nowUptimeMillis) {
        return eventUptimeMillis >= 0L
                && nowUptimeMillis >= 0L
                && eventUptimeMillis <= nowUptimeMillis
                && isWithinEventAge(eventUptimeMillis, nowUptimeMillis)
                && eventUptimeMillis > activationUptimeMillis
                && eventUptimeMillis > eventWatermarkUptimeMillis;
    }

    private boolean isWithinEventAge(long eventUptimeMillis, long nowUptimeMillis) {
        return eventUptimeMillis >= 0L
                && nowUptimeMillis >= eventUptimeMillis
                && nowUptimeMillis - eventUptimeMillis <= MAX_WINDOW_EVENT_AGE_MILLIS;
    }

    private void disarmEventGate() {
        activationUptimeMillis = -1L;
        eventWatermarkUptimeMillis = -1L;
        clearPendingEntry();
        inFlightActionToken = 0L;
    }

    private void clearPendingEntry() {
        pendingActionToken = 0L;
        pendingEntryUptimeMillis = -1L;
        pendingTargetId = null;
    }

    private Snapshot snapshotWithoutClock() {
        long remaining = 0L;
        if (state == State.RUNNING) {
            long now = lastObservedElapsedMillis;
            remaining = Math.max(0L, deadlineElapsedMillis - now);
        } else if (state == State.PAUSED) {
            remaining = remainingWhenPausedMillis;
        }
        return new Snapshot(state, remaining, selectedTargetIds, wakeupToken, detailCode);
    }

    private void release(State terminalState, String detail) {
        state = terminalState;
        selectedTargetIds = Collections.emptySet();
        remainingWhenPausedMillis = 0L;
        deadlineElapsedMillis = 0L;
        detailCode = detail;
        wakeupToken = nextToken(wakeupToken);
        disarmEventGate();
    }

    private boolean isActiveState() {
        return state == State.RUNNING || state == State.PAUSED;
    }

    private static Set<String> validateSelection(Set<String> targetIds) {
        if (targetIds == null || targetIds.isEmpty()) {
            throw new IllegalArgumentException("At least one whole-app target is required.");
        }
        LinkedHashSet<String> copy = new LinkedHashSet<>(targetIds);
        if (copy.size() != targetIds.size()
                || !copy.stream().allMatch(GuardQualificationTargets::isSupportedTargetId)) {
            throw new IllegalArgumentException("Only supported whole-app targets are allowed.");
        }
        return Collections.unmodifiableSet(copy);
    }

    private static long nextToken(long current) {
        return current == Long.MAX_VALUE ? 1L : current + 1L;
    }

    private static String safeDetail(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value;
    }
}
