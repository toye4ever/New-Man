package com.newman.newmanapp;

import java.nio.file.Files;
import java.nio.file.Path;

/** Portable assertions: no Android runtime, alarm, notification or user data. */
public final class TaskReminderNativePolicyTest {
    private static final String KEY = "a".repeat(64);
    private static final String SCOPE = "b".repeat(64);
    public static void main(String[] args) throws Exception {
        cancellationFaults();
        accessFailsClosed();
        schedulingRequiresEveryGate();
        deliveryRequiresFreshAuthorityAndReceipt();
        hashesMatchDartCompatibleVectors();
        localTimeResolutionIsExplicit();
        sourceRemainsDormant();
        System.out.println("TaskReminderNativePolicyTest: all assertions passed");
    }
    private static void cancellationFaults() {
        java.util.List<String> calls = new java.util.ArrayList<>();
        boolean confirmed = TaskReminderNativePolicy.cancelQueue(java.util.List.of("a", "b"),
            () -> calls.add("durable-disarm"), key -> {
                calls.add(key);
                if (key.equals("a")) throw new java.io.IOException("injected OS failure");
            });
        assert !confirmed;
        assert calls.equals(java.util.List.of("durable-disarm", "a", "b"));
        calls.clear();
        confirmed = TaskReminderNativePolicy.cancelQueue(java.util.List.of("a", "b"),
            () -> { throw new java.io.IOException("injected persistence failure"); }, calls::add);
        assert !confirmed && calls.isEmpty();
        assert TaskReminderNativePolicy.cancelQueue(java.util.List.of("a", "b"),
            () -> calls.add("durable-disarm"), calls::add);
        assert calls.equals(java.util.List.of("durable-disarm", "a", "b"));
    }

    private static void accessFailsClosed() {
        assert !TaskReminderNativePolicy.access(false, 33, true, true, true, true);
        assert !TaskReminderNativePolicy.access(true, 25, true, true, true, true);
        assert !TaskReminderNativePolicy.access(true, 33, false, true, true, true);
        assert !TaskReminderNativePolicy.access(true, 33, true, false, true, true);
        assert !TaskReminderNativePolicy.access(true, 33, true, true, false, true);
        assert !TaskReminderNativePolicy.access(true, 33, true, true, true, false);
        assert TaskReminderNativePolicy.access(true, 26, true, true, true, true);
        assert TaskReminderNativePolicy.access(true, 33, true, true, true, true);
    }
    private static boolean schedule(boolean access, String key, String owner, long expected,
            long now, long trigger, long expiry, boolean received, int count, boolean replacing, boolean authority) {
        return TaskReminderNativePolicy.schedule(access, key, owner, SCOPE, 4, expected,
                now, trigger, expiry, received, count, replacing, authority);
    }
    private static void schedulingRequiresEveryGate() {
        assert schedule(true, KEY, SCOPE, 4, 10, 20, 30, false, 0, false, true);
        assert !schedule(true, KEY, SCOPE, 4, 10, 20, 30, false, 65, true, true);
        assert schedule(true, KEY, SCOPE, 4, 10, 20, 30, false, 64, true, true);
        assert !schedule(true, KEY, SCOPE, 4, 10, 20, 30, false, 64, false, true);
        assert !schedule(false, KEY, SCOPE, 4, 10, 20, 30, false, 0, false, true);
        assert !schedule(true, "raw-task-id", SCOPE, 4, 10, 20, 30, false, 0, false, true);
        assert !schedule(true, KEY, "c".repeat(64), 4, 10, 20, 30, false, 0, false, true);
        assert !schedule(true, KEY, SCOPE, 3, 10, 20, 30, false, 0, false, true);
        assert !schedule(true, KEY, SCOPE, 4, 20, 20, 30, false, 0, false, true);
        assert !schedule(true, KEY, SCOPE, 4, 21, 20, 30, false, 0, false, true);
        assert !schedule(true, KEY, SCOPE, 4, 10, 20, 20, false, 0, false, true);
        assert !schedule(true, KEY, SCOPE, 4, 10, 20, 30, true, 0, false, true);
        assert !schedule(true, KEY, SCOPE, 4, 10, 20, 30, false, 64, false, true);
        assert schedule(true, KEY, SCOPE, 4, 10, 20, 30, false, 64, true, true);
        assert !schedule(true, KEY, SCOPE, 4, 10, 20, 30, false, -1, true, true);
        assert !schedule(true, KEY, SCOPE, 4, 10, 20, 30, false, 0, false, false);
    }
    private static boolean deliver(boolean access, long revision, long now, boolean armed,
            boolean received, int receipts, boolean authority) {
        return TaskReminderNativePolicy.deliver(access, KEY, SCOPE, SCOPE, revision, 4,
                now, 20, 30, armed, received, receipts, authority);
    }
    private static void deliveryRequiresFreshAuthorityAndReceipt() {
        assert deliver(true, 4, 20, true, false, 0, true);
        assert deliver(true, 4, 29, true, false, 0, true); // Inexact delay, before expiry.
        assert !deliver(false, 4, 20, true, false, 0, true); // Revocation at delivery.
        assert !deliver(true, 3, 20, true, false, 0, true); // Off/re-enable revision.
        assert !deliver(true, 4, 19, true, false, 0, true);
        assert !deliver(true, 4, 30, true, false, 0, true);
        assert !deliver(true, 4, 20, false, false, 0, true); // Failed/incomplete arming.
        assert !deliver(true, 4, 20, true, true, 0, true); // Restart or repeated-hour replay.
        assert !deliver(true, 4, 20, true, false, 2048, true); // Bounded durable receipts.
        assert !deliver(true, 4, 20, true, false, 0, false); // Deleted/completed/edited task.
    }
    private static void hashesMatchDartCompatibleVectors() {
        assert TaskReminderNativePolicy.digest("abc").equals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
        String scope = TaskReminderNativePolicy.digest("opaque-installation-token-123");
        assert TaskReminderNativePolicy.occurrenceKey(scope, "task-1", "2026-11-17:540")
                .equals("246fb25e810e63f65e4d0923cc3cc8e6b6bfbb163264cf7f333a5a064fa55a4b");
        assert TaskReminderNativePolicy.occurrenceKey(scope, "a\"b\\c\n", "2026-11-17:540")
                .equals("4c708d95cbfb0480c8a8ff2a6e18b570e0bf6c52992c4fa3e61ac5f0e19b270e");
        assert TaskReminderNativePolicy.occurrenceKey(scope, "unicode-é-😀", "2026-11-17:540")
                .equals("978be8558b6c30e18dce7cdd4fbbc4193e4fc4ba56a905ce1f35f2e0e1262578");
        assert TaskReminderNativePolicy.TITLE.equals("New Man");
        assert TaskReminderNativePolicy.BODY.equals("You have a task to review.");
        assert !TaskReminderNativePolicy.key(KEY.toUpperCase());
        assert !TaskReminderNativePolicy.key(null);
    }
    private static void localTimeResolutionIsExplicit() {
        assert TaskReminderNativePolicy.resolveTrigger("2026-03-08", 150, "America/New_York")
                == java.time.Instant.parse("2026-03-08T07:00:00Z").toEpochMilli();
        assert TaskReminderNativePolicy.resolveTrigger("2026-11-01", 90, "America/New_York")
                == java.time.Instant.parse("2026-11-01T05:30:00Z").toEpochMilli();
        assert TaskReminderNativePolicy.resolveTrigger("2011-12-30", 540, "Pacific/Apia") == null;
        assert TaskReminderNativePolicy.resolveTrigger("2026-11-17", -1, "UTC") == null;
        assert TaskReminderNativePolicy.resolveExpiry("2026-03-08", "America/New_York")
                == java.time.Instant.parse("2026-03-09T04:00:00Z").toEpochMilli();
        assert !TaskReminderNativePolicy.resolveTrigger("2026-11-17", 540, "UTC").equals(
                TaskReminderNativePolicy.resolveTrigger("2026-11-17", 540, "America/New_York"));
    }

    private static void sourceRemainsDormant() throws Exception {
        String foundation = Files.readString(Path.of("android/app/src/main/kotlin/com/newman/newmanapp/TaskReminderNativeFoundation.kt"));
        assert foundation.contains("fun qualified(): Boolean = false");
        assert foundation.contains("alarms.setAndAllowWhileIdle(");
        assert !foundation.contains("alarms.setExact(");
        assert !foundation.contains("alarms.setExactAndAllowWhileIdle(");
        assert !foundation.contains("alarms.setAlarmClock(");
        assert foundation.contains("SQLiteDatabase.OPEN_READONLY");
        assert foundation.contains("Notification.VISIBILITY_SECRET");
        String activity = Files.readString(Path.of("android/app/src/main/kotlin/com/newman/newmanapp/MainActivity.kt"));
        assert !activity.contains("TaskReminderNative");
        for (String variant : new String[] {"main", "debug", "profile"}) {
            String manifest = Files.readString(Path.of("android/app/src/" + variant + "/AndroidManifest.xml"));
            assert !manifest.contains("TaskReminderAlarmReceiver");
            assert !manifest.contains("TaskReminderSystemReceiver");
            assert !manifest.contains("POST_NOTIFICATIONS");
            assert !manifest.contains("SCHEDULE_EXACT_ALARM");
            assert !manifest.contains("USE_EXACT_ALARM");
        }
    }
}
