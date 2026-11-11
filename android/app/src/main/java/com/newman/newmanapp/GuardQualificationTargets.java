package com.newman.newmanapp;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

/** Exact whole-app target registry for the developer Guard qualification test. */
public final class GuardQualificationTargets {
    private static final Map<String, String> TARGET_TO_PACKAGE;
    private static final Map<String, String> PACKAGE_TO_TARGET;
    private static final Set<String> TARGET_IDS;
    private static final Set<String> PACKAGE_NAMES;

    static {
        LinkedHashMap<String, String> targets = new LinkedHashMap<>();
        targets.put("youtube_app", "com.google.android.youtube");
        targets.put("instagram_app", "com.instagram.android");
        targets.put("facebook_app", "com.facebook.katana");
        targets.put("tiktok_app", "com.zhiliaoapp.musically");

        LinkedHashMap<String, String> packages = new LinkedHashMap<>();
        for (Map.Entry<String, String> entry : targets.entrySet()) {
            if (packages.put(entry.getValue(), entry.getKey()) != null) {
                throw new IllegalStateException("Guard package mappings must be one-to-one.");
            }
        }

        TARGET_TO_PACKAGE = Collections.unmodifiableMap(targets);
        PACKAGE_TO_TARGET = Collections.unmodifiableMap(packages);
        TARGET_IDS = Collections.unmodifiableSet(new LinkedHashSet<>(targets.keySet()));
        PACKAGE_NAMES = Collections.unmodifiableSet(new LinkedHashSet<>(packages.keySet()));
    }

    private GuardQualificationTargets() {}

    public static Set<String> targetIds() {
        return TARGET_IDS;
    }

    public static Set<String> packageNames() {
        return PACKAGE_NAMES;
    }

    public static boolean isSupportedTargetId(String targetId) {
        return targetId != null && TARGET_TO_PACKAGE.containsKey(targetId);
    }

    public static String packageForTarget(String targetId) {
        String packageName = targetId == null ? null : TARGET_TO_PACKAGE.get(targetId);
        if (packageName == null) {
            throw new IllegalArgumentException("Unsupported Guard qualification target.");
        }
        return packageName;
    }

    public static String targetForPackage(String packageName) {
        return packageName == null ? null : PACKAGE_TO_TARGET.get(packageName);
    }
}
