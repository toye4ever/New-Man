package com.newman.newmanapp;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/** Platform-independent gates shared by the dormant Android foundation. */
public final class TaskReminderNativePolicy {
    public static final int MAX_PENDING = 64;
    public static final int MAX_RECEIPTS = 2048;
    public static final String TITLE = "New Man";
    public static final String BODY = "You have a task to review.";
    private TaskReminderNativePolicy() {}

    public static boolean key(String value) {
        return value != null && value.matches("[a-f0-9]{64}");
    }

    public static boolean access(boolean qualified, int api, boolean enabled,
            boolean acknowledged, boolean notifications, boolean permission) {
        return qualified && api >= 26 && enabled && acknowledged
                && notifications && permission;
    }

    public static boolean schedule(boolean access, String key, String scope,
            String activeScope, long revision, long expectedRevision,
            long now, long trigger, long expiry, boolean received,
            int pendingCount, boolean replacing, boolean authoritative) {
        return access && key(key) && key(scope) && scope.equals(activeScope)
                && revision >= 0 && revision == expectedRevision
                && trigger > now && expiry > trigger && !received
                && pendingCount >= 0 && pendingCount <= MAX_PENDING
                && (pendingCount < MAX_PENDING || replacing)
                && authoritative;
    }

    public static boolean deliver(boolean access, String key, String scope,
            String activeScope, long revision, long currentRevision,
            long now, long trigger, long expiry, boolean armed,
            boolean received, int receiptCount, boolean authoritative) {
        return access && key(key) && key(scope) && scope.equals(activeScope)
                && revision >= 0 && revision == currentRevision
                && armed && !received && withinWindow(now, trigger, expiry)
                && receiptCount >= 0 && receiptCount < MAX_RECEIPTS && authoritative;
    }

    @FunctionalInterface public interface CheckedAction { void run() throws Exception; }
    @FunctionalInterface public interface CheckedKeyAction { void run(String key) throws Exception; }

    /** Persist disarmed authority before cleanup; one failed job never skips later jobs. */
    public static boolean cancelQueue(Iterable<String> keys, CheckedAction disarm,
            CheckedKeyAction cleanup) {
        try { disarm.run(); } catch (Exception failure) { return false; }
        boolean confirmed = true;
        for (String key : keys) {
            try { cleanup.run(key); } catch (Exception failure) { confirmed = false; }
        }
        return confirmed;
    }

    public static boolean withinWindow(long now, long trigger, long expiry) {
        return now >= trigger && now < expiry;
    }

    /** API 26+ on Android; also portable on the JDK for DST validation. */
    public static Long resolveTrigger(String date, int minutes, String zoneName) {
        if (minutes < 0 || minutes > 1439) return null;
        java.time.LocalDate day = java.time.LocalDate.parse(date);
        java.time.ZoneId zone = java.time.ZoneId.of(zoneName);
        java.time.LocalDateTime local = day.atStartOfDay().plusMinutes(minutes);
        java.time.zone.ZoneOffsetTransition transition = zone.getRules().getTransition(local);
        java.time.LocalDateTime resolved = transition != null && transition.isGap()
                ? transition.getDateTimeAfter() : local;
        if (!resolved.toLocalDate().equals(day)) return null;
        return resolved.atZone(zone).toInstant().toEpochMilli();
    }

    public static long resolveExpiry(String date, String zoneName) {
        return java.time.LocalDate.parse(date).plusDays(1)
                .atStartOfDay(java.time.ZoneId.of(zoneName)).toInstant().toEpochMilli();
    }

    public static String digest(String value) {
        try {
            byte[] bytes = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder output = new StringBuilder(64);
            for (byte b : bytes) output.append(String.format(java.util.Locale.ROOT, "%02x", b & 255));
            return output.toString();
        } catch (java.security.NoSuchAlgorithmException impossible) {
            throw new IllegalStateException("SHA-256 unavailable");
        }
    }

    /** Matches Dart jsonEncode([scope, taskId, reminderKey]), without private titles. */
    public static String occurrenceKey(String scope, String taskId, String reminderKey) {
        return digest("[" + quote(scope) + "," + quote(taskId) + "," + quote(reminderKey) + "]");
    }

    private static String quote(String value) {
        StringBuilder out = new StringBuilder("\"");
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            switch (c) {
                case '"': out.append("\\\""); break;
                case '\\': out.append("\\\\"); break;
                case '\b': out.append("\\b"); break;
                case '\f': out.append("\\f"); break;
                case '\n': out.append("\\n"); break;
                case '\r': out.append("\\r"); break;
                case '\t': out.append("\\t"); break;
                default:
                    boolean paired = Character.isHighSurrogate(c) && i + 1 < value.length()
                            && Character.isLowSurrogate(value.charAt(i + 1));
                    if (c < 32 || (Character.isSurrogate(c) && !paired)) {
                        out.append(String.format(java.util.Locale.ROOT, "\\u%04x", (int) c));
                    } else {
                        out.append(c);
                        if (paired) out.append(value.charAt(++i));
                    }
            }
        }
        return out.append('"').toString();
    }
}
