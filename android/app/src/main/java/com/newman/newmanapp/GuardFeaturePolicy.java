package com.newman.newmanapp;

import java.util.ArrayDeque;
import java.util.function.LongSupplier;

/** Pure proposal engine; decisions are not proof of playback prevention.
 * Authority operations serialize on this instance. The injected monotonic clock
 * must be nonblocking and must not call back into the policy.
 */
public final class GuardFeaturePolicy {
    public enum Mode { FEATURE, WHOLE_APP }
    public enum Result { PASS, UNSUPPORTED, ALLOWED_ITEM, SCOPED_NAVIGATION, WHOLE_APP, PIP_UNSUPPORTED }
    public static final class Decision {
        public final Result result;
        public final long token;
        private Decision(Result result, long token) { this.result = result; this.token = token; }
    }
    private final LongSupplier clock;
    private final ArrayDeque<Long> rate = new ArrayDeque<>();
    private String target, version, profile, session, allowedItem;
    private Mode mode;
    private long generation, highestGeneration = -1, expiry, lastEvent = -1, lastObserved = -1, lastClock = -1, nextToken, pending;
    private GuardStructuralSnapshot current;
    private boolean running;

    public GuardFeaturePolicy(LongSupplier clock) { this.clock = clock; }
    private static String packageFor(String feature) {
        if (feature == null) return null;
        switch (feature) {
            case "youtube_shorts": return "com.google.android.youtube";
            case "instagram_reels": return "com.instagram.android";
            case "facebook_reels": return "com.facebook.katana";
            case "tiktok_feed": return "com.zhiliaoapp.musically";
            default: return null;
        }
    }
    public synchronized boolean start(boolean optedIn, Mode mode, String selected, String version,
            String profile, String session, boolean qualified, long generation, long expiry) {
        end();
        String pkg = mode == Mode.FEATURE ? packageFor(selected)
                : mode == Mode.WHOLE_APP && GuardQualificationTargets.isSupportedTargetId(selected)
                    ? GuardQualificationTargets.packageForTarget(selected) : null;
        long now = readClock();
        if (!optedIn || !qualified || pkg == null || !GuardStructuralSnapshot.field(version)
                || !GuardStructuralSnapshot.field(profile) || !GuardStructuralSnapshot.field(session)
                || generation <= highestGeneration || now < 0 || expiry <= now) return false;
        this.target = pkg; this.version = version; this.profile = profile; this.session = session;
        this.generation = generation; highestGeneration = generation; this.expiry = expiry; this.mode = mode; running = true;
        return true;
    }
    private void clearAuthority() { pending = 0; allowedItem = null; current = null; }
    public synchronized void end() { running = false; clearAuthority(); rate.clear(); lastEvent = -1; lastObserved = -1; }
    public synchronized void pause() { end(); }
    public synchronized void revoke() { end(); }
    public synchronized void disconnect() { end(); }
    public synchronized void uncertainty() { end(); }
    private long readClock() {
        long now = clock.getAsLong();
        if (now < 0 || now < lastClock) { end(); return -1; }
        lastClock = now;
        return now;
    }
    private boolean fresh(GuardStructuralSnapshot s, long now) {
        return s != null && now >= 0 && s.eventMs >= 0 && s.observedMs >= s.eventMs
                && s.observedMs <= now && now - s.eventMs <= 1000
                && now - s.observedMs <= 1000;
    }
    private boolean live(long now) {
        if (!running || now < 0 || now >= expiry) { end(); return false; }
        return true;
    }
    private Decision decision(Result r) { return new Decision(r, 0); }
    private Decision action(Result r) { pending = ++nextToken; return new Decision(r, pending); }
    public synchronized Decision observe(GuardStructuralSnapshot s) {
        long now = readClock();
        if (!live(now) || s == null || !s.valid() || !s.qualified || s.generation != generation
                || !version.equals(s.version) || !profile.equals(s.profile) || !session.equals(s.sessionToken)
                || !fresh(s, now)
                || s.eventMs <= lastEvent || s.observedMs < lastObserved) {
            clearAuthority(); return decision(Result.UNSUPPORTED);
        }
        while (!rate.isEmpty() && now - rate.peekFirst() >= 1000) rate.removeFirst();
        if (rate.size() >= 8) { clearAuthority(); return decision(Result.UNSUPPORTED); }
        rate.addLast(now); lastEvent = s.eventMs; lastObserved = s.observedMs;
        pending = 0;
        if (!target.equals(s.packageName) || s.ownership != GuardStructuralSnapshot.Ownership.TARGET) {
            clearAuthority();
            return decision(s.surface == GuardStructuralSnapshot.Surface.PIP ? Result.PIP_UNSUPPORTED
                    : !target.equals(s.packageName) && s.ownership == GuardStructuralSnapshot.Ownership.FOREIGN
                        ? Result.PASS : Result.UNSUPPORTED);
        }
        if (s.surface == GuardStructuralSnapshot.Surface.UNKNOWN) { clearAuthority(); return decision(Result.UNSUPPORTED); }
        if (s.surface != GuardStructuralSnapshot.Surface.SHORT_FORM) allowedItem = null;
        else if (allowedItem != null && (!s.itemAttested || !allowedItem.equals(s.itemToken))) allowedItem = null;
        current = s;
        if (mode == Mode.WHOLE_APP) return action(Result.WHOLE_APP);
        if (s.surface == GuardStructuralSnapshot.Surface.PIP) { clearAuthority(); return decision(Result.PIP_UNSUPPORTED); }
        if (s.surface != GuardStructuralSnapshot.Surface.SHORT_FORM) return decision(Result.PASS);
        if (allowedItem != null) return decision(Result.ALLOWED_ITEM);
        return action(Result.SCOPED_NAVIGATION);
    }
    public synchronized boolean allowOneVideo() {
        long now = readClock();
        if (!live(now) || mode != Mode.FEATURE || current == null
                || current.surface != GuardStructuralSnapshot.Surface.SHORT_FORM
                || !current.qualified || !current.itemAttested || current.itemToken == null
                || !fresh(current, now)) { clearAuthority(); return false; }
        allowedItem = current.itemToken; pending = 0; return true;
    }
    public synchronized boolean consume(long token) {
        long now = readClock();
        if (!live(now) || current == null || !fresh(current, now)
                || current.generation != generation || current.ownership != GuardStructuralSnapshot.Ownership.TARGET
                || !target.equals(current.packageName) || !version.equals(current.version)
                || !profile.equals(current.profile) || !session.equals(current.sessionToken)) {
            clearAuthority(); return false;
        }
        if (token == 0 || token != pending) { pending = 0; return false; }
        pending = 0; return true;
    }
}
