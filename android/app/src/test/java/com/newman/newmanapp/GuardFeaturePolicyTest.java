package com.newman.newmanapp;

import static com.newman.newmanapp.GuardFeaturePolicy.Result.*;
import static com.newman.newmanapp.GuardStructuralSnapshot.Surface.*;
import static com.newman.newmanapp.GuardStructuralSnapshot.Ownership.*;

public final class GuardFeaturePolicyTest {
    static long now = 1000, gen = 0;
    static GuardFeaturePolicy p = new GuardFeaturePolicy(() -> now);
    static GuardStructuralSnapshot s(String pkg, String version, String profile, String item,
            GuardStructuralSnapshot.Surface surface, GuardStructuralSnapshot.Ownership owner,
            boolean qualified, boolean attested, long event, long observed, long generation,
            int windows, int nodes, int depth, int budget) {
        return new GuardStructuralSnapshot(pkg, version, profile, "session", item, surface, owner,
                qualified, attested, event, observed, generation, windows, nodes, depth, budget);
    }
    static GuardStructuralSnapshot snap(String item, GuardStructuralSnapshot.Surface surface) {
        return s("com.google.android.youtube", "v1", "fixture", item, surface, TARGET,
                true, item != null, now, now, gen, 4, 128, 12, 8);
    }
    static void start() { assert p.start(true, GuardFeaturePolicy.Mode.FEATURE, "youtube_shorts", "v1", "fixture", "session", true, ++gen, now + 5000); }
    static void tick() { now += 125; }
    static void lifecycleTests() {
        Runnable[] stops = {p::pause, p::end, p::revoke, p::disconnect, p::uncertainty};
        for (Runnable stop : stops) {
            start(); var action = p.observe(snap("one", SHORT_FORM));
            assert action.result == SCOPED_NAVIGATION;
            stop.run(); assert !p.consume(action.token) && !p.allowOneVideo();
            assert p.observe(snap("one", SHORT_FORM)).result == UNSUPPORTED;
            start(); assert p.observe(snap("one", SHORT_FORM)).result == SCOPED_NAVIGATION;
            assert p.allowOneVideo(); stop.run();
            assert !p.allowOneVideo() && p.observe(snap("one", SHORT_FORM)).result == UNSUPPORTED;
            assert !p.start(true, GuardFeaturePolicy.Mode.FEATURE, "youtube_shorts", "v1", "fixture", "session", true, gen, now + 5000);
            start(); assert p.observe(snap("one", SHORT_FORM)).result == SCOPED_NAVIGATION;
        }
        long fresh = gen + 1;
        assert !p.start(false, GuardFeaturePolicy.Mode.FEATURE, "youtube_shorts", "v1", "fixture", "session", true, fresh, now + 5000);
        assert !p.start(true, GuardFeaturePolicy.Mode.FEATURE, "youtube_shorts", "v1", "fixture", "session", false, fresh, now + 5000);
        assert p.start(true, GuardFeaturePolicy.Mode.FEATURE, "youtube_shorts", "v1", "fixture", "session", true, ++gen, now + 5000);
        for (boolean allowance : new boolean[]{false, true}) {
            assert p.start(true, GuardFeaturePolicy.Mode.FEATURE, "youtube_shorts", "v1", "fixture", "session", true, ++gen, now + 1);
            var action = p.observe(snap("one", SHORT_FORM)); assert action.result == SCOPED_NAVIGATION;
            if (allowance) assert p.allowOneVideo();
            now++; assert !p.consume(action.token) && !p.allowOneVideo();
            assert p.observe(snap("one", SHORT_FORM)).result == UNSUPPORTED;
            start(); assert p.observe(snap("one", SHORT_FORM)).result == SCOPED_NAVIGATION;
        }
    }
    static GuardStructuralSnapshot timed(long event, long observed) {
        return s("com.google.android.youtube", "v1", "fixture", "one", SHORT_FORM, TARGET,
                true, true, event, observed, gen, 1, 1, 1, 1);
    }
    static void timingTests() {
        for (boolean allowance : new boolean[]{false, true}) {
            long[] clock = {1000}; var probe = new GuardFeaturePolicy(() -> clock[0]);
            assert probe.start(true, GuardFeaturePolicy.Mode.FEATURE, "youtube_shorts", "v1", "fixture", "session", true, 1, 5000);
            var action = probe.observe(s("com.google.android.youtube", "v1", "fixture", "one", SHORT_FORM, TARGET, true, true, 1, 1000, 1, 1, 1, 1, 1));
            assert action.result == SCOPED_NAVIGATION; clock[0] = 1500;
            assert !(allowance ? probe.allowOneVideo() : probe.consume(action.token));
            assert !probe.allowOneVideo() && !probe.consume(action.token);
        }
        // Event-age boundary with a current observation, for both authority operations.
        for (boolean allowance : new boolean[]{false, true}) {
            now += 2000; start(); var a = p.observe(timed(now - 999, now));
            now++; assert allowance ? p.allowOneVideo() : p.consume(a.token);
            now += 2000; start(); a = p.observe(timed(now - 999, now));
            now += 2; assert !(allowance ? p.allowOneVideo() : p.consume(a.token));
            assert !p.allowOneVideo() && !p.consume(a.token);
            now += 2000; start(); a = p.observe(timed(now - 999, now));
            now += 500; assert !(allowance ? p.allowOneVideo() : p.consume(a.token));
        }
        // Coherence requires event <= observation: an old observation necessarily
        // also has an event at least as old, so it cannot be isolated at 1001 ms.
        for (boolean allowance : new boolean[]{false, true}) {
            now += 2000; start(); var a = p.observe(timed(now, now));
            now += 1000; assert allowance ? p.allowOneVideo() : p.consume(a.token);
            now += 2000; start(); a = p.observe(timed(now, now));
            now += 1001; assert !(allowance ? p.allowOneVideo() : p.consume(a.token));
        }
        now += 2000; start(); assert p.observe(timed(now + 1, now + 1)).result == UNSUPPORTED;
        assert p.observe(timed(now, now + 1)).result == UNSUPPORTED;
        assert p.observe(timed(now, now - 1)).result == UNSUPPORTED;
        var a = p.observe(timed(now, now)); assert a.result == SCOPED_NAVIGATION;
        now--; assert !p.consume(a.token); now++; assert !p.allowOneVideo();
        start(); assert p.observe(timed(now, now)).result == SCOPED_NAVIGATION;
        now++; assert p.observe(timed(now - 1, now)).result == UNSUPPORTED;
        assert p.observe(timed(now, now - 1)).result == UNSUPPORTED;
    }
    static void raceTests() throws Exception {
        for (int i = 0; i < 100; i++) {
            now += 2000; start(); var action = p.observe(snap("one", SHORT_FORM));
            var ready = new java.util.concurrent.CountDownLatch(2);
            var go = new java.util.concurrent.CountDownLatch(1);
            var success = new java.util.concurrent.atomic.AtomicInteger();
            var failure = new java.util.concurrent.atomic.AtomicReference<Throwable>();
            Runnable consume = () -> { try { ready.countDown(); go.await(); if (p.consume(action.token)) success.incrementAndGet(); } catch (Throwable t) { failure.set(t); } };
            Thread a = new Thread(consume), b = new Thread(consume); a.start(); b.start(); ready.await(); go.countDown(); a.join(); b.join();
            assert failure.get() == null : failure.get(); assert success.get() == 1;
            now += 2000; start();
            var observed = new java.util.concurrent.atomic.AtomicReference<GuardFeaturePolicy.Decision>();
            final var ready2 = new java.util.concurrent.CountDownLatch(2);
            final var go2 = new java.util.concurrent.CountDownLatch(1);
            Thread observer = new Thread(() -> { try { ready2.countDown(); go2.await(); observed.set(p.observe(snap("one", SHORT_FORM))); } catch (Throwable t) { failure.set(t); } });
            Thread stopper = new Thread(() -> { try { ready2.countDown(); go2.await(); p.pause(); } catch (Throwable t) { failure.set(t); } });
            observer.start(); stopper.start(); ready2.await(); go2.countDown(); observer.join(); stopper.join();
            assert failure.get() == null : failure.get();
            assert observed.get().result == SCOPED_NAVIGATION || observed.get().result == UNSUPPORTED;
            assert !p.consume(observed.get().token) && !p.allowOneVideo();
        }
    }
    public static void main(String[] args) throws Exception {
        String[] features = {"youtube_shorts", "instagram_reels", "facebook_reels", "tiktok_feed"};
        String[] pkgs = {"com.google.android.youtube", "com.instagram.android", "com.facebook.katana", "com.zhiliaoapp.musically"};
        for (int i = 0; i < features.length; i++) {
            assert p.start(true, GuardFeaturePolicy.Mode.FEATURE, features[i], "v1", "fixture", "session", true, ++gen, now + 5000);
            assert p.observe(s(pkgs[i], "v1", "fixture", "item", SHORT_FORM, TARGET, true, true, now, now, gen, 1, 1, 1, 1)).result == SCOPED_NAVIGATION;
            tick();
        }
        start();
        var first = p.observe(snap("one", SHORT_FORM));
        assert first.result == SCOPED_NAVIGATION && first.token != 0;
        assert p.allowOneVideo() && !p.consume(first.token);
        tick(); assert p.observe(snap("one", SHORT_FORM)).result == ALLOWED_ITEM;
        tick(); var next = p.observe(snap("two", SHORT_FORM));
        assert next.result == SCOPED_NAVIGATION && p.consume(next.token) && !p.consume(next.token);
        tick(); assert p.observe(snap(null, SHORT_FORM)).result == SCOPED_NAVIGATION;
        assert !p.allowOneVideo();
        tick(); assert p.observe(snap(null, ORDINARY)).result == PASS;
        tick(); assert p.observe(snap(null, MESSAGING)).result == PASS;
        tick(); assert p.observe(snap(null, PIP)).result == PIP_UNSUPPORTED;
        tick(); assert p.observe(s("com.instagram.android", "v1", "fixture", null, PIP, FOREIGN, true, false, now, now, gen, 1, 1, 1, 1)).result == PIP_UNSUPPORTED;
        tick(); assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, GuardStructuralSnapshot.Ownership.UNKNOWN, true, false, now, now, gen, 1, 1, 1, 1)).result == UNSUPPORTED;
        start(); assert p.observe(snap("one", SHORT_FORM)).result == SCOPED_NAVIGATION; assert p.allowOneVideo();
        tick(); assert p.observe(snap(null, ORDINARY)).result == PASS;
        tick(); assert p.observe(snap("one", SHORT_FORM)).result == SCOPED_NAVIGATION;
        p.pause(); assert p.observe(snap("one", SHORT_FORM)).result == UNSUPPORTED;
        start(); p.revoke(); assert !p.allowOneVideo();
        start(); p.disconnect(); assert !p.allowOneVideo();
        start(); p.uncertainty(); assert !p.allowOneVideo();
        start(); p.end(); assert !p.allowOneVideo();
        assert p.start(true, GuardFeaturePolicy.Mode.WHOLE_APP, "youtube_app", "v1", "fixture", "session", true, ++gen, now + 1);
        assert p.observe(snap(null, ORDINARY)).result == WHOLE_APP; now++; assert p.observe(snap(null, ORDINARY)).result == UNSUPPORTED;
        start();
        assert p.observe(s("com.google.android.youtube", "wrong", "fixture", null, SHORT_FORM, TARGET, true, false, now, now, gen, 1, 1, 1, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, false, false, now, now, gen, 1, 1, 1, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, true, false, now, now, gen + 1, 1, 1, 1, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, true, false, now + 1, now + 1, gen, 1, 1, 1, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, true, false, now - 1001, now - 1001, gen, 1, 1, 1, 1)).result == UNSUPPORTED;
        assert p.observe(snap("one", SHORT_FORM)).result == SCOPED_NAVIGATION;
        assert p.observe(snap("one", SHORT_FORM)).result == UNSUPPORTED;
        tick(); assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, true, false, now, now, gen, 5, 1, 1, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, true, false, now, now, gen, 1, 129, 1, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, true, false, now, now, gen, 1, 1, 13, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, true, false, now, now, gen, 1, 1, 1, 9)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, true, false, now, now, gen, 0, 1, 1, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, true, false, now, now, gen, 1, -1, 1, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, true, false, now, now, gen, 1, 1, -1, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", null, SHORT_FORM, TARGET, true, false, now, now, gen, 1, 1, 1, -1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", "item", SHORT_FORM, TARGET, false, true, now, now, gen, 1, 1, 1, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "x".repeat(129), null, SHORT_FORM, TARGET, true, false, now, now, gen, 1, 1, 1, 1)).result == UNSUPPORTED;
        assert p.observe(s("com.google.android.youtube", "v1", "other", null, SHORT_FORM, TARGET, true, false, now, now, gen, 1, 1, 1, 1)).result == UNSUPPORTED;
        start(); var staleAction = p.observe(snap("one", SHORT_FORM));
        tick(); assert p.observe(snap("two", SHORT_FORM)).result == SCOPED_NAVIGATION;
        assert !p.consume(staleAction.token);
        tick(); var paused = p.observe(snap("three", SHORT_FORM)); p.pause(); assert !p.consume(paused.token);
        start(); var replaced = p.observe(snap("one", SHORT_FORM));
        assert p.start(true, GuardFeaturePolicy.Mode.FEATURE, "youtube_shorts", "v1", "fixture", "session", true, ++gen, now + 5000);
        assert !p.consume(replaced.token);
        assert p.observe(s("com.google.android.youtube", "v1", "fixture", "one", SHORT_FORM, TARGET, true, true, now, now, gen - 1, 1, 1, 1, 1)).result == UNSUPPORTED;
        start(); for (int i = 0; i < 8; i++) { assert p.observe(snap(null, ORDINARY)).result == PASS; now++; }
        assert p.observe(snap(null, ORDINARY)).result == UNSUPPORTED;
        now += 992; assert p.observe(snap(null, ORDINARY)).result == PASS;
        lifecycleTests(); timingTests(); raceTests();
        System.out.println("GuardFeaturePolicy assertions passed");
    }
}
