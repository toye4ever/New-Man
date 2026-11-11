package com.newman.newmanapp;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

public final class GuardQualificationLeaseTest {
    private static final long MINUTE = 60_000L;

    public static void main(String[] args) {
        qualificationTargetRegistryIsExactAndImmutable();
        startRequiresConsentServiceAndExactTargets();
        expandedTargetsFollowLeaseLifecycle();
        durationBoundsAndOverflowFailClosed();
        startPauseResumeEndAndDefensiveCopies();
        duplicateStartDoesNotReplaceLease();
        expiryClearsBeforeBlockingDecision();
        backwardAndInvalidTimeReleaseSafely();
        staleWakeupCannotEndLaterLease();
        processRecreationStartsInactive();
        unrelatedAndUnselectedTargetsNeverBlock();
        prerequisiteLossInterruptsActiveAndPausedLeases();
        serviceLifecycleInvalidatesPriorLease();
        eventGateHandlesFreshReentryAndQueuedEvents();
        eventGateResetsAcrossLifecycleChanges();
        actionFailureAndStaleCompletionReleaseSafely();
        elapsedRealtimeExpiresThroughDeepSleep();
        absentUpdaterPreservesInitialInactiveUnknown();
        activeRequestWithoutUpdaterFailsSafely();
        bindAndRebindApplyRestrictiveDelivery();
        activeDeliveryFailureRollsBackThroughProductionTransaction();
        thrownActiveDeliveryFailureRollsBackThroughProductionTransaction();
        failedCleanupStaysUnknownAndNeverSuppressesRestoration();
        nativeAdapterAdmitsActiveDeparturesAndStaysContentBlind();
        System.out.println("GuardQualificationLeaseTest: all assertions passed");
    }

    private static void qualificationTargetRegistryIsExactAndImmutable() {
        Set<String> expectedTargets = set(
                "youtube_app", "instagram_app", "facebook_app", "tiktok_app");
        Set<String> expectedPackages = set(
                "com.google.android.youtube",
                "com.instagram.android",
                "com.facebook.katana",
                "com.zhiliaoapp.musically");

        assert GuardQualificationTargets.targetIds().equals(expectedTargets);
        assert GuardQualificationTargets.packageNames().equals(expectedPackages);
        assert GuardQualificationTargets.targetIds().size()
                == GuardQualificationTargets.packageNames().size();
        assert "com.google.android.youtube".equals(
                GuardQualificationTargets.packageForTarget("youtube_app"));
        assert "com.instagram.android".equals(
                GuardQualificationTargets.packageForTarget("instagram_app"));
        assert "com.facebook.katana".equals(
                GuardQualificationTargets.packageForTarget("facebook_app"));
        assert "com.zhiliaoapp.musically".equals(
                GuardQualificationTargets.packageForTarget("tiktok_app"));
        for (String targetId : expectedTargets) {
            String packageName = GuardQualificationTargets.packageForTarget(targetId);
            assert targetId.equals(GuardQualificationTargets.targetForPackage(packageName));
            assert GuardQualificationTargets.isSupportedTargetId(targetId);
        }

        assert !GuardQualificationTargets.isSupportedTargetId(null);
        assert !GuardQualificationTargets.isSupportedTargetId("youtube_shorts");
        assert GuardQualificationTargets.targetForPackage(null) == null;
        assert GuardQualificationTargets.targetForPackage("com.facebook.lite") == null;
        assert GuardQualificationTargets.targetForPackage("com.facebook.orca") == null;
        assert GuardQualificationTargets.targetForPackage("com.ss.android.ugc.trill") == null;
        assert GuardQualificationTargets.targetForPackage("com.ss.android.ugc.aweme") == null;
        assert GuardQualificationTargets.targetForPackage("com.newman.newmanapp") == null;
        assert GuardQualificationTargets.targetForPackage("com.android.settings") == null;
        assert GuardQualificationTargets.targetForPackage("com.android.systemui") == null;
        assert GuardQualificationTargets.targetForPackage("com.android.dialer") == null;
        expectThrows(() -> GuardQualificationTargets.packageForTarget(null));
        expectThrows(() -> GuardQualificationTargets.packageForTarget("unknown"));
        expectThrows(() -> GuardQualificationTargets.targetIds().add("unknown"));
        expectThrows(() -> GuardQualificationTargets.packageNames().clear());
    }

    private static void startRequiresConsentServiceAndExactTargets() {
        FakeClock clock = new FakeClock(100L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        expectThrows(() -> lease.start(set(), 15L, true, true));
        expectThrows(() -> lease.start(set("youtube_shorts"), 15L, true, true));
        expectThrows(() -> lease.start(set("instagram_reels"), 15L, true, true));
        expectThrows(() -> lease.start(set("com.ss.android.ugc.trill"), 15L, true, true));
        expectThrows(() -> lease.start(set("unknown"), 15L, true, true));
        expectThrows(() -> lease.start(set("youtube_app"), 15L, false, true));
        expectThrows(() -> lease.start(set("youtube_app"), 15L, true, false));

        GuardQualificationLease.Snapshot started = lease.start(
                set("youtube_app", "instagram_app", "facebook_app", "tiktok_app"),
                15L,
                true,
                true);
        assert started.getState() == GuardQualificationLease.State.RUNNING;
        assert started.getRemainingMillis() == 15L * MINUTE;
    }

    private static void expandedTargetsFollowLeaseLifecycle() {
        FakeClock elapsed = new FakeClock(0L);
        FakeClock uptime = new FakeClock(100L);
        GuardQualificationLease lease = new GuardQualificationLease(elapsed, uptime);
        Set<String> selection = set("facebook_app", "tiktok_app");
        GuardQualificationLease.Snapshot started = lease.start(selection, 15L, true, true);
        selection.clear();
        assert started.getSelectedTargetIds().equals(set("facebook_app", "tiktok_app"));
        assert lease.shouldRestrict("facebook_app", true, true);
        assert lease.shouldRestrict("tiktok_app", true, true);
        assert !lease.shouldRestrict("com.facebook.katana", true, true);
        assert !lease.shouldRestrict("com.zhiliaoapp.musically", true, true);

        uptime.advance(1L);
        GuardQualificationLease.WindowEntryDecision facebookEntry =
                lease.evaluateWindowEntry("facebook_app", uptime.now, true, true);
        assert facebookEntry.shouldScheduleAction();
        uptime.advance(1L);
        GuardQualificationLease.WindowEntryDecision departure =
                lease.evaluateWindowEntry(null, uptime.now, true, true);
        assert departure.acceptedTransition();
        assert !departure.shouldScheduleAction();
        uptime.advance(GuardQualificationLease.WINDOW_ENTRY_SETTLE_MILLIS);
        assert !lease.takeWindowEntryAction(facebookEntry.getActionToken(), true, true);

        GuardQualificationLease.Snapshot paused = lease.pause(true, true);
        assert paused.getState() == GuardQualificationLease.State.PAUSED;
        assert !lease.shouldRestrict("tiktok_app", true, true);
        assert lease.resume(true, true).getState() == GuardQualificationLease.State.RUNNING;
        assert lease.shouldRestrict("tiktok_app", true, true);
        assert lease.end().getState() == GuardQualificationLease.State.ENDED;
        assert lease.snapshot(true, true).getSelectedTargetIds().isEmpty();

        GuardQualificationLease revoked = new GuardQualificationLease(elapsed, uptime);
        revoked.start(set("tiktok_app"), 15L, true, true);
        GuardQualificationLease.Snapshot afterRevocation = revoked.snapshot(false, true);
        assert afterRevocation.getState() == GuardQualificationLease.State.INTERRUPTED;
        assert "consent_withdrawn".equals(afterRevocation.getDetailCode());
        assert afterRevocation.getSelectedTargetIds().isEmpty();

        GuardQualificationLease recreated = new GuardQualificationLease(elapsed, uptime);
        assert recreated.snapshot(false, false).getState() == GuardQualificationLease.State.IDLE;
        assert !recreated.shouldRestrict("facebook_app", false, false);
    }

    private static void durationBoundsAndOverflowFailClosed() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        expectThrows(() -> lease.start(set("youtube_app"), 14L, true, true));
        expectThrows(() -> lease.start(set("youtube_app"), 241L, true, true));

        GuardQualificationLease maximum = new GuardQualificationLease(clock);
        assert maximum.start(set("youtube_app"), 240L, true, true).getRemainingMillis()
                == 240L * MINUTE;

        FakeClock overflowClock = new FakeClock(Long.MAX_VALUE - MINUTE);
        GuardQualificationLease overflow = new GuardQualificationLease(overflowClock);
        expectThrows(() -> overflow.start(set("youtube_app"), 15L, true, true));
        assert overflow.snapshot(true, true).getState() == GuardQualificationLease.State.ERROR;
    }

    private static void startPauseResumeEndAndDefensiveCopies() {
        FakeClock clock = new FakeClock(1_000L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        Set<String> source = set("youtube_app");
        GuardQualificationLease.Snapshot started = lease.start(source, 15L, true, true);
        source.clear();
        assert started.getSelectedTargetIds().contains("youtube_app");
        expectThrows(() -> started.getSelectedTargetIds().clear());

        clock.advance(2L * MINUTE);
        GuardQualificationLease.Snapshot paused = lease.pause(true, true);
        assert paused.getState() == GuardQualificationLease.State.PAUSED;
        assert paused.getRemainingMillis() == 13L * MINUTE;
        assert !lease.shouldRestrict("youtube_app", true, true);

        clock.advance(20L * MINUTE);
        assert lease.snapshot(true, true).getRemainingMillis() == 13L * MINUTE;
        GuardQualificationLease.Snapshot resumed = lease.resume(true, true);
        assert resumed.getState() == GuardQualificationLease.State.RUNNING;
        assert resumed.getRemainingMillis() == 13L * MINUTE;
        assert lease.shouldRestrict("youtube_app", true, true);

        GuardQualificationLease.Snapshot ended = lease.end();
        assert ended.getState() == GuardQualificationLease.State.ENDED;
        assert ended.getRemainingMillis() == 0L;
        assert ended.getSelectedTargetIds().isEmpty();
        assert lease.end().getState() == GuardQualificationLease.State.ENDED;
    }

    private static void duplicateStartDoesNotReplaceLease() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        lease.start(set("youtube_app"), 15L, true, true);
        clock.advance(MINUTE);
        expectThrows(() -> lease.start(set("instagram_app"), 240L, true, true));
        GuardQualificationLease.Snapshot snapshot = lease.snapshot(true, true);
        assert snapshot.getSelectedTargetIds().equals(set("youtube_app"));
        assert snapshot.getRemainingMillis() == 14L * MINUTE;
    }

    private static void expiryClearsBeforeBlockingDecision() {
        FakeClock clock = new FakeClock(5_000L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        lease.start(set("youtube_app"), 15L, true, true);
        clock.advance(15L * MINUTE);
        assert !lease.shouldRestrict("youtube_app", true, true);
        GuardQualificationLease.Snapshot snapshot = lease.snapshot(true, true);
        assert snapshot.getState() == GuardQualificationLease.State.COMPLETED;
        assert snapshot.getSelectedTargetIds().isEmpty();
    }

    private static void backwardAndInvalidTimeReleaseSafely() {
        FakeClock clock = new FakeClock(10_000L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        lease.start(set("youtube_app"), 15L, true, true);
        clock.now = 9_999L;
        assert !lease.shouldRestrict("youtube_app", true, true);
        assert lease.snapshot(true, true).getState() == GuardQualificationLease.State.ERROR;

        FakeClock restartClock = new FakeClock(10_000L);
        GuardQualificationLease restarted = new GuardQualificationLease(restartClock);
        restarted.start(set("youtube_app"), 15L, true, true);
        restarted.end();
        restartClock.now = 9_999L;
        expectThrows(() -> restarted.start(set("youtube_app"), 15L, true, true));
        assert restarted.snapshot(true, true).getState()
                == GuardQualificationLease.State.ERROR;

        FakeClock negativeClock = new FakeClock(-1L);
        GuardQualificationLease negative = new GuardQualificationLease(negativeClock);
        expectThrows(() -> negative.start(set("youtube_app"), 15L, true, true));
        assert negative.snapshot(true, true).getState() == GuardQualificationLease.State.ERROR;
    }

    private static void staleWakeupCannotEndLaterLease() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        long oldToken = lease.start(set("youtube_app"), 15L, true, true).getWakeupToken();
        lease.end();
        clock.advance(MINUTE);
        GuardQualificationLease.Snapshot newer = lease.start(
                set("instagram_app"), 15L, true, true);
        assert newer.getWakeupToken() != oldToken;
        GuardQualificationLease.Snapshot afterStale = lease.onWakeup(oldToken, true, true);
        assert afterStale.getState() == GuardQualificationLease.State.RUNNING;
        assert afterStale.getSelectedTargetIds().equals(set("instagram_app"));
    }

    private static void processRecreationStartsInactive() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease first = new GuardQualificationLease(clock);
        first.start(set("youtube_app"), 15L, true, true);
        GuardQualificationLease recreated = new GuardQualificationLease(clock);
        assert recreated.snapshot(false, false).getState() == GuardQualificationLease.State.IDLE;
        assert !recreated.shouldRestrict("youtube_app", false, false);
    }

    private static void unrelatedAndUnselectedTargetsNeverBlock() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        lease.start(set("youtube_app"), 15L, true, true);
        assert lease.shouldRestrict("youtube_app", true, true);
        assert !lease.shouldRestrict("instagram_app", true, true);
        assert !lease.shouldRestrict("new_man", true, true);
        assert !lease.shouldRestrict("launcher", true, true);
        assert !lease.shouldRestrict("system_ui", true, true);
        assert !lease.shouldRestrict("settings", true, true);
        assert !lease.shouldRestrict("phone", true, true);
    }

    private static void prerequisiteLossInterruptsActiveAndPausedLeases() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease serviceLoss = new GuardQualificationLease(clock);
        serviceLoss.start(set("youtube_app"), 15L, true, true);
        assert !serviceLoss.shouldRestrict("youtube_app", true, false);
        assert serviceLoss.snapshot(true, false).getState()
                == GuardQualificationLease.State.INTERRUPTED;

        GuardQualificationLease consentLoss = new GuardQualificationLease(clock);
        consentLoss.start(set("youtube_app"), 15L, true, true);
        consentLoss.pause(true, true);
        assert consentLoss.snapshot(false, true).getState()
                == GuardQualificationLease.State.INTERRUPTED;
    }

    private static void serviceLifecycleInvalidatesPriorLease() {
        FakeClock elapsed = new FakeClock(0L);
        FakeClock uptime = new FakeClock(100L);
        GuardQualificationLease lease = new GuardQualificationLease(elapsed, uptime);
        assert lease.onServiceConnectionOpened().getState()
                == GuardQualificationLease.State.IDLE;

        lease.start(set("youtube_app"), 15L, true, true);
        GuardQualificationLease.Snapshot rebound = lease.onServiceConnectionOpened();
        assert rebound.getState() == GuardQualificationLease.State.INTERRUPTED;
        assert "service_reconnected".equals(rebound.getDetailCode());
        assert rebound.getSelectedTargetIds().isEmpty();

        lease.start(set("youtube_app"), 15L, true, true);
        GuardQualificationLease.Snapshot unbound = lease.onServiceConnectionClosed();
        assert unbound.getState() == GuardQualificationLease.State.INTERRUPTED;
        assert "service_disconnected".equals(unbound.getDetailCode());
    }

    private static void eventGateHandlesFreshReentryAndQueuedEvents() {
        FakeClock elapsed = new FakeClock(0L);
        FakeClock uptime = new FakeClock(1_000L);
        GuardQualificationLease lease = new GuardQualificationLease(elapsed, uptime);
        lease.start(set("youtube_app"), 15L, true, true);

        assert !lease.canInspectWindowEntry(999L, true, true);
        assert !lease.evaluateWindowEntry("youtube_app", 999L, true, true)
                .shouldScheduleAction();
        assert !lease.canInspectWindowEntry(1_001L, true, true);

        uptime.advance(1L);
        assert lease.canInspectWindowEntry(1_001L, true, true);
        GuardQualificationLease.WindowEntryDecision initial =
                lease.evaluateWindowEntry("youtube_app", 1_001L, true, true);
        assert initial.acceptedTransition();
        assert initial.shouldScheduleAction();
        assert !lease.evaluateWindowEntry("youtube_app", 1_001L, true, true)
                .shouldScheduleAction();
        assert !lease.evaluateWindowEntry("youtube_app", 1_000L, true, true)
                .shouldScheduleAction();

        uptime.advance(100L);
        GuardQualificationLease.WindowEntryDecision settledEntry =
                lease.evaluateWindowEntry("youtube_app", 1_101L, true, true);
        assert settledEntry.shouldScheduleAction();
        uptime.advance(GuardQualificationLease.WINDOW_ENTRY_SETTLE_MILLIS);
        assert lease.takeWindowEntryAction(settledEntry.getActionToken(), true, true);
        lease.completeWindowEntryAction(settledEntry.getActionToken(), true);

        // A Home/launcher departure is admitted through the active all-package
        // stream, then a genuinely fresh re-entry remains actionable without a
        // target cooldown.
        uptime.advance(1L);
        GuardQualificationLease.WindowEntryDecision departure =
                lease.evaluateWindowEntry(null, uptime.now, true, true);
        assert departure.acceptedTransition();
        assert !departure.shouldScheduleAction();
        uptime.advance(1L);
        GuardQualificationLease.WindowEntryDecision rapidReentry =
                lease.evaluateWindowEntry("youtube_app", uptime.now, true, true);
        assert rapidReentry.shouldScheduleAction();
        uptime.advance(GuardQualificationLease.WINDOW_ENTRY_SETTLE_MILLIS);
        assert lease.takeWindowEntryAction(rapidReentry.getActionToken(), true, true);
        lease.completeWindowEntryAction(rapidReentry.getActionToken(), true);

        // A first target callback that is delivered much later is rejected even
        // when no intervening departure event exists.
        FakeClock delayedElapsed = new FakeClock(0L);
        FakeClock delayedUptime = new FakeClock(1_000L);
        GuardQualificationLease delayed =
                new GuardQualificationLease(delayedElapsed, delayedUptime);
        delayed.start(set("youtube_app"), 15L, true, true);
        delayedUptime.now = 11_000L;
        assert !delayed.canInspectWindowEntry(1_100L, true, true);
        assert !delayed.evaluateWindowEntry("youtube_app", 1_100L, true, true)
                .shouldScheduleAction();
    }

    private static void eventGateResetsAcrossLifecycleChanges() {
        FakeClock elapsed = new FakeClock(0L);
        FakeClock uptime = new FakeClock(500L);
        GuardQualificationLease lease = new GuardQualificationLease(elapsed, uptime);
        lease.start(set("youtube_app"), 15L, true, true);
        uptime.advance(1L);
        GuardQualificationLease.WindowEntryDecision first =
                lease.evaluateWindowEntry("youtube_app", 501L, true, true);
        assert first.shouldScheduleAction();

        lease.pause(true, true);
        uptime.advance(1L);
        assert !lease.takeWindowEntryAction(first.getActionToken(), true, true);
        assert !lease.canInspectWindowEntry(502L, true, true);
        lease.resume(true, true);
        assert !lease.evaluateWindowEntry("youtube_app", 502L, true, true)
                .shouldScheduleAction();
        uptime.advance(1L);
        GuardQualificationLease.WindowEntryDecision beforeEnd =
                lease.evaluateWindowEntry("youtube_app", 503L, true, true);
        assert beforeEnd.shouldScheduleAction();
        lease.end();
        uptime.advance(GuardQualificationLease.WINDOW_ENTRY_SETTLE_MILLIS);
        assert !lease.takeWindowEntryAction(beforeEnd.getActionToken(), true, true);

        lease.start(set("youtube_app"), 15L, true, true);
        uptime.advance(1L);
        GuardQualificationLease.WindowEntryDecision beforeExpiry =
                lease.evaluateWindowEntry("youtube_app", uptime.now, true, true);
        elapsed.advance(15L * MINUTE);
        uptime.advance(GuardQualificationLease.WINDOW_ENTRY_SETTLE_MILLIS);
        assert !lease.takeWindowEntryAction(beforeExpiry.getActionToken(), true, true);
        assert lease.snapshot(true, true).getState()
                == GuardQualificationLease.State.COMPLETED;

        lease.start(set("youtube_app"), 15L, true, true);
        uptime.advance(1L);
        GuardQualificationLease.WindowEntryDecision beforeRebind =
                lease.evaluateWindowEntry("youtube_app", uptime.now, true, true);
        lease.onServiceConnectionOpened();
        uptime.advance(GuardQualificationLease.WINDOW_ENTRY_SETTLE_MILLIS);
        assert !lease.takeWindowEntryAction(beforeRebind.getActionToken(), true, true);
        assert !lease.canInspectWindowEntry(uptime.now, true, true);
    }

    private static void actionFailureAndStaleCompletionReleaseSafely() {
        FakeClock elapsed = new FakeClock(0L);
        FakeClock uptime = new FakeClock(50L);
        GuardQualificationLease lease = new GuardQualificationLease(elapsed, uptime);
        lease.start(set("youtube_app"), 15L, true, true);
        uptime.advance(1L);
        GuardQualificationLease.WindowEntryDecision failed =
                lease.evaluateWindowEntry("youtube_app", 51L, true, true);
        uptime.advance(GuardQualificationLease.WINDOW_ENTRY_SETTLE_MILLIS);
        assert lease.takeWindowEntryAction(failed.getActionToken(), true, true);
        GuardQualificationLease.Snapshot failure =
                lease.completeWindowEntryAction(failed.getActionToken(), false);
        assert failure.getState() == GuardQualificationLease.State.ERROR;
        assert "global_action_failed".equals(failure.getDetailCode());
        assert failure.getSelectedTargetIds().isEmpty();

        lease.start(set("instagram_app"), 15L, true, true);
        GuardQualificationLease.Snapshot afterOldCallback =
                lease.completeWindowEntryAction(failed.getActionToken(), false);
        assert afterOldCallback.getState() == GuardQualificationLease.State.RUNNING;
        assert afterOldCallback.getSelectedTargetIds().equals(set("instagram_app"));
    }

    private static void elapsedRealtimeExpiresThroughDeepSleep() {
        FakeClock elapsed = new FakeClock(10L);
        FakeClock uptime = new FakeClock(10L);
        GuardQualificationLease lease = new GuardQualificationLease(elapsed, uptime);
        lease.start(set("youtube_app"), 15L, true, true);

        elapsed.advance(15L * MINUTE);
        assert !lease.canInspectWindowEntry(11L, true, true);
        assert lease.snapshot(true, true).getState()
                == GuardQualificationLease.State.COMPLETED;
    }

    private static void absentUpdaterPreservesInitialInactiveUnknown() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        GuardQualificationLease.EventDeliveryTransaction delivery =
                new GuardQualificationLease.EventDeliveryTransaction(lease);

        assert delivery.applyOrFailLease(false, null) == null;
        assert delivery.isUnknown();
        GuardQualificationLease.Snapshot snapshot = lease.snapshot(false, false);
        assert snapshot.getState() == GuardQualificationLease.State.IDLE;
        assert snapshot.getDetailCode() == null;
    }

    private static void activeRequestWithoutUpdaterFailsSafely() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        GuardQualificationLease.EventDeliveryTransaction delivery =
                new GuardQualificationLease.EventDeliveryTransaction(lease);

        lease.start(set("youtube_app"), 15L, true, true);
        GuardQualificationLease.Snapshot failure =
                delivery.applyOrFailLease(true, null);

        assert failure != null;
        assert failure.getState() == GuardQualificationLease.State.ERROR;
        assert "event_delivery_unavailable".equals(failure.getDetailCode());
        assert failure.getSelectedTargetIds().isEmpty();
        assert delivery.isUnknown();
        assert !lease.shouldRestrict("youtube_app", true, true);
    }

    private static void bindAndRebindApplyRestrictiveDelivery() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        GuardQualificationLease.EventDeliveryTransaction delivery =
                new GuardQualificationLease.EventDeliveryTransaction(lease);
        PlatformDelivery platform = new PlatformDelivery();

        assert delivery.applyOrFailLease(false, platform::succeed) == null;
        assert delivery.isKnownIdle();
        assert platform.calls.equals(Arrays.asList(false));

        delivery.invalidate();
        assert delivery.applyOrFailLease(false, platform::succeed) == null;
        assert delivery.isKnownIdle();
        assert platform.calls.equals(Arrays.asList(false, false));
    }

    private static void activeDeliveryFailureRollsBackThroughProductionTransaction() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        GuardQualificationLease.EventDeliveryTransaction delivery =
                new GuardQualificationLease.EventDeliveryTransaction(lease);
        PlatformDelivery platform = new PlatformDelivery();

        assert delivery.applyOrFailLease(false, platform::succeed) == null;
        assert delivery.isKnownIdle();
        assert !platform.active;
        platform.calls.clear();

        lease.start(set("youtube_app"), 15L, true, true);
        GuardQualificationLease.Snapshot failure = delivery.applyOrFailLease(
                true,
                platform::assignThenFailActive);

        assert failure != null;
        assert failure.getState() == GuardQualificationLease.State.ERROR;
        assert "event_delivery_unavailable".equals(failure.getDetailCode());
        assert failure.getSelectedTargetIds().isEmpty();
        assert !lease.shouldRestrict("youtube_app", true, true);
        assert platform.calls.equals(Arrays.asList(true, false));
        assert !platform.active;
        assert delivery.isKnownIdle();
    }

    private static void thrownActiveDeliveryFailureRollsBackThroughProductionTransaction() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        GuardQualificationLease.EventDeliveryTransaction delivery =
                new GuardQualificationLease.EventDeliveryTransaction(lease);
        PlatformDelivery platform = new PlatformDelivery();

        assert delivery.applyOrFailLease(false, platform::succeed) == null;
        platform.calls.clear();
        lease.start(set("instagram_app"), 15L, true, true);
        GuardQualificationLease.Snapshot failure = delivery.applyOrFailLease(
                true,
                platform::assignThenThrowActive);

        assert failure != null;
        assert failure.getState() == GuardQualificationLease.State.ERROR;
        assert platform.calls.equals(Arrays.asList(true, false));
        assert !platform.active;
        assert delivery.isKnownIdle();
    }

    private static void failedCleanupStaysUnknownAndNeverSuppressesRestoration() {
        FakeClock clock = new FakeClock(0L);
        GuardQualificationLease lease = new GuardQualificationLease(clock);
        GuardQualificationLease.EventDeliveryTransaction delivery =
                new GuardQualificationLease.EventDeliveryTransaction(lease);
        PlatformDelivery platform = new PlatformDelivery();

        assert delivery.applyOrFailLease(false, platform::succeed) == null;
        assert delivery.applyOrFailLease(false, platform::unexpectedCall) == null;
        assert platform.calls.equals(Arrays.asList(false));

        platform.calls.clear();
        lease.start(set("youtube_app"), 15L, true, true);
        GuardQualificationLease.Snapshot failure = delivery.applyOrFailLease(
                true,
                platform::failActiveAndCleanup);
        assert failure != null;
        assert failure.getState() == GuardQualificationLease.State.ERROR;
        assert delivery.isUnknown();
        assert platform.active;
        assert platform.calls.equals(Arrays.asList(true, false));

        platform.calls.clear();
        assert delivery.applyOrFailLease(false, null) == null;
        assert delivery.isUnknown();
        assert lease.snapshot(false, false).getState()
                == GuardQualificationLease.State.ERROR;
        assert "event_delivery_unavailable".equals(
                lease.snapshot(false, false).getDetailCode());
        assert platform.calls.isEmpty();

        assert delivery.applyOrFailLease(false, platform::succeed) == null;
        assert platform.calls.equals(Arrays.asList(false));
        assert !platform.active;
        assert delivery.isKnownIdle();

        platform.calls.clear();
        delivery.invalidate();
        assert delivery.applyOrFailLease(false, platform::succeed) == null;
        assert platform.calls.equals(Arrays.asList(false));
        assert delivery.isKnownIdle();
    }

    private static void nativeAdapterAdmitsActiveDeparturesAndStaysContentBlind() {
        String xml = readSource(
                "android/app/src/main/res/xml/guard_accessibility_service.xml");
        assert xml.contains("android:accessibilityEventTypes=\"typeWindowStateChanged\"");
        assert xml.contains("android:notificationTimeout=\"0\"");
        assert xml.contains("android:canRetrieveWindowContent=\"false\"");
        assert xml.contains("android:packageNames=\""
                + String.join(",", GuardQualificationTargets.packageNames())
                + "\"");

        String manifest = readSource("android/app/src/main/AndroidManifest.xml");
        assert occurrences(manifest, "<package android:name=") == 4;
        for (String packageName : GuardQualificationTargets.packageNames()) {
            assert manifest.contains("<package android:name=\"" + packageName + "\" />");
        }

        String service = readSource(
                "android/app/src/main/kotlin/com/newman/newmanapp/GuardAccessibilityService.kt");
        assert service.contains("GuardQualificationTargets.packageNames().toTypedArray()");
        assert service.contains("info.packageNames = if (active) null else IDLE_PACKAGES.clone()");
        assert service.contains("info.notificationTimeout = 0L");
        assert service.contains("event.eventTime");
        assert service.contains("{ event.packageName?.toString() }");
        assert !service.contains("rootInActiveWindow");
        assert !service.contains("event.text");
        assert !service.contains("event.source");

        String englishDisclosure = readSource(
                "android/app/src/main/res/values/guard_strings.xml");
        assert englishDisclosure.contains("app-change identities from other apps");
        assert englishDisclosure.contains("reads no screen content");
        assert englishDisclosure.contains("text, messages, or screenshots");
        assert englishDisclosure.contains("saves no app history");
        assert englishDisclosure.contains("sends nothing");
        assert englishDisclosure.contains("Facebook");
        assert englishDisclosure.contains("TikTok");
        String spanishDisclosure = readSource(
                "android/app/src/main/res/values-es/guard_strings.xml");
        assert spanishDisclosure.contains("identidades de cambio de aplicación");
        assert spanishDisclosure.contains("No lee contenido de pantalla");
        assert spanishDisclosure.contains("texto, mensajes ni capturas de pantalla");
        assert spanishDisclosure.contains("no guarda historial de aplicaciones");
        assert spanishDisclosure.contains("ni envía nada");
        assert spanishDisclosure.contains("Facebook");
        assert spanishDisclosure.contains("TikTok");

        String runtime = readSource(
                "android/app/src/main/kotlin/com/newman/newmanapp/GuardQualificationRuntime.kt");
        assert runtime.contains("lease.canInspectWindowEntry(");
        assert runtime.indexOf("lease.canInspectWindowEntry(")
                < runtime.indexOf("packageName())");
        assert runtime.contains("handler.postDelayed(");
        assert runtime.contains("lease.takeWindowEntryAction(");
        assert runtime.indexOf("lease.takeWindowEntryAction(")
                < runtime.indexOf("sendHome()");
        assert runtime.contains("catch (_: RuntimeException)");
        assert runtime.contains("GuardQualificationTargets.packageForTarget(targetId)");
        assert runtime.contains("GuardQualificationTargets.targetForPackage(packageName())");

        String readiness = readSource(
                "android/app/src/main/kotlin/com/newman/newmanapp/GuardReadinessChannel.kt");
        assert readiness.contains("GuardQualificationTargets.packageNames().map(::readPackage)");
    }

    private static int occurrences(String source, String value) {
        int count = 0;
        int start = 0;
        while ((start = source.indexOf(value, start)) >= 0) {
            count++;
            start += value.length();
        }
        return count;
    }

    private static String readSource(String path) {
        try {
            return Files.readString(Path.of(path));
        } catch (IOException error) {
            throw new AssertionError("Could not read shipped adapter source: " + path, error);
        }
    }

    private static LinkedHashSet<String> set(String... values) {
        LinkedHashSet<String> result = new LinkedHashSet<>();
        CollectionsSupport.addAll(result, values);
        return result;
    }

    private static void expectThrows(ThrowingRunnable action) {
        boolean threw = false;
        try {
            action.run();
        } catch (RuntimeException expected) {
            threw = true;
        }
        assert threw : "Expected a runtime exception";
    }

    private interface ThrowingRunnable {
        void run();
    }

    private static final class FakeClock implements GuardQualificationLease.Clock {
        private long now;

        private FakeClock(long now) {
            this.now = now;
        }

        @Override
        public long elapsedRealtimeMillis() {
            return now;
        }

        private void advance(long millis) {
            now = Math.addExact(now, millis);
        }
    }

    private static final class PlatformDelivery {
        private final List<Boolean> calls = new ArrayList<>();
        private boolean active;

        private boolean succeed(boolean requestedActive) {
            calls.add(requestedActive);
            active = requestedActive;
            return true;
        }

        private boolean assignThenFailActive(boolean requestedActive) {
            calls.add(requestedActive);
            active = requestedActive;
            return !requestedActive;
        }

        private boolean assignThenThrowActive(boolean requestedActive) {
            calls.add(requestedActive);
            active = requestedActive;
            if (requestedActive) {
                throw new IllegalStateException("post-assignment verification failed");
            }
            return true;
        }

        private boolean failActiveAndCleanup(boolean requestedActive) {
            calls.add(requestedActive);
            if (requestedActive) {
                active = true;
            }
            return false;
        }

        private boolean unexpectedCall(boolean requestedActive) {
            throw new AssertionError("Confirmed idle delivery should be idempotent.");
        }
    }

    private static final class CollectionsSupport {
        private static void addAll(Set<String> target, String[] values) {
            for (String value : values) {
                target.add(value);
            }
        }
    }
}
