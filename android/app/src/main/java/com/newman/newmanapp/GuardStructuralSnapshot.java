package com.newman.newmanapp;

/** Content-free structural observations supplied by a future qualified adapter. */
public final class GuardStructuralSnapshot {
    public enum Surface { ORDINARY, MESSAGING, SHORT_FORM, PIP, UNKNOWN }
    public enum Ownership { TARGET, FOREIGN, UNKNOWN }
    public final String packageName, version, profile, itemToken, sessionToken;
    public final Surface surface;
    public final Ownership ownership;
    public final boolean qualified, itemAttested;
    public final long eventMs, observedMs, generation;
    public final int windows, nodes, depth, budgetMs;

    public GuardStructuralSnapshot(String packageName, String version, String profile,
            String sessionToken, String itemToken, Surface surface, Ownership ownership,
            boolean qualified, boolean itemAttested, long eventMs, long observedMs,
            long generation, int windows, int nodes, int depth, int budgetMs) {
        this.packageName = packageName; this.version = version; this.profile = profile;
        this.sessionToken = sessionToken; this.itemToken = itemToken; this.surface = surface;
        this.ownership = ownership; this.qualified = qualified; this.itemAttested = itemAttested;
        this.eventMs = eventMs; this.observedMs = observedMs; this.generation = generation;
        this.windows = windows; this.nodes = nodes; this.depth = depth; this.budgetMs = budgetMs;
    }

    static boolean field(String value) {
        return value != null && value.matches("[A-Za-z0-9_.-]{1,128}");
    }

    boolean valid() {
        return GuardQualificationTargets.packageNames().contains(packageName)
                && field(version) && field(profile) && field(sessionToken)
                && (itemToken == null || field(itemToken)) && surface != null && ownership != null
                && (!itemAttested || (qualified && itemToken != null))
                && eventMs >= 0 && observedMs >= eventMs && generation >= 0
                && windows >= 1 && windows <= 4 && nodes >= 0 && nodes <= 128
                && depth >= 0 && depth <= 12 && budgetMs >= 0 && budgetMs <= 8;
    }
}
