package com.newman.newmanapp

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.time.ZoneId
import java.util.UUID

/** No registration, manifest entries, or permission UI accompanies this source. */
internal class TaskReminderNativeBackend(context: Context) {
    private val app = context.applicationContext
    private val preferences = app.getSharedPreferences("task_reminder_native_v1", Context.MODE_PRIVATE)
    private val alarms = app.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val notifications = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    companion object {
        val lock = Any()
        const val CHANNEL = "newman_private_task_reminders_v1"
        const val ACTION = "com.newman.newmanapp.TASK_REMINDER_V1"
        const val TAG_PREFIX = "newman-task:"
        // Requires a separate source review, native compilation and device qualification.
        fun qualified(): Boolean = false
    }

    private var storeReady = false
    init {
        synchronized(lock) {
            try {
                if (!preferences.contains("installationToken")) {
                    check(preferences.edit().putString("installationToken", UUID.randomUUID().toString())
                        .putBoolean("enabled", false).putBoolean("acknowledged", false)
                        .putLong("revision", 0).putString("pending", "{}").putString("receipts", "{}").commit())
                }
                storeReady = (preferences.getString("installationToken", "") ?: "").matches(Regex("[A-Za-z0-9_-]{16,128}")) && revision() >= 0
            } catch (_: Exception) { storeReady = false }
        }
    }

    private fun revision() = preferences.getLong("revision", 0)
    private fun scope() = TaskReminderNativePolicy.digest(preferences.getString("installationToken", "") ?: "")
    private fun pending() = JSONObject(preferences.getString("pending", "{}") ?: "{}")
    private fun receipts() = JSONObject(preferences.getString("receipts", "{}") ?: "{}")
    private fun permission(): Boolean = Build.VERSION.SDK_INT < 33 ||
        app.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    private fun notificationsAllowed(): Boolean = Build.VERSION.SDK_INT >= 26 && notifications.areNotificationsEnabled() &&
        notifications.getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE
    private fun access(): Boolean {
        if (!storeReady || !qualified() || Build.VERSION.SDK_INT < 26) return false
        return try { TaskReminderNativePolicy.access(true, Build.VERSION.SDK_INT,
            preferences.getBoolean("enabled", false), preferences.getBoolean("acknowledged", false),
            notificationsAllowed(), permission()) } catch (_: Exception) { false }
    }

    fun state(): Map<String, Any> = synchronized(lock) {
        if (!storeReady || !qualified() || Build.VERSION.SDK_INT < 26) return@synchronized mapOf("protocol" to 1, "supported" to false)
        mapOf("protocol" to 1, "supported" to true, "platform" to "android", "apiLevel" to Build.VERSION.SDK_INT,
            "deliveryMode" to "inexact", "redaction" to "generic", "revision" to revision(),
            "installationToken" to (preferences.getString("installationToken", "") ?: ""),
            "consentEnabled" to preferences.getBoolean("enabled", false),
            "inexactAcknowledged" to preferences.getBoolean("acknowledged", false),
            "notificationsEnabled" to notificationsAllowed(),
            "permission" to if (Build.VERSION.SDK_INT < 33) "notRequested" else if (permission()) "granted" else "denied")
    }

    fun canAttemptEnable(args: Map<*, *>): Boolean = synchronized(lock) {
        storeReady && qualified() && Build.VERSION.SDK_INT >= 26 && args["userInitiated"] == true &&
            args["acceptedInexactTiming"] == true && args["expectedOwnerScope"] == scope() &&
            integer(args["expectedRevision"]) == revision()
    }

    fun finishEnable(args: Map<*, *>): Map<String, Any> = synchronized(lock) {
        if (!canAttemptEnable(args)) return@synchronized state()
        if (!permission() || !notificationsAllowed()) {
            disableAndCancelAll()
            return@synchronized state()
        }
        check(preferences.edit().putBoolean("enabled", true).putBoolean("acknowledged", true)
            .putLong("revision", Math.addExact(revision(), 1)).commit())
        state()
    }

    fun needsPermission(): Boolean = Build.VERSION.SDK_INT >= 33 && !permission()

    private fun alarmIntent(key: String, create: Boolean): PendingIntent? {
        val intent = Intent(app, TaskReminderAlarmReceiver::class.java).setAction(ACTION)
            .setData(Uri.Builder().scheme("newman-task-reminder").authority(app.packageName).appendPath(key).build())
        val flags = PendingIntent.FLAG_IMMUTABLE or if (create) PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_NO_CREATE
        return PendingIntent.getBroadcast(app, 0, intent, flags)
    }

    fun cancel(key: String): Map<String, Any> = synchronized(lock) {
        require(TaskReminderNativePolicy.key(key))
        alarmIntent(key, false)?.let { alarms.cancel(it); it.cancel() }
        notifications.cancel(TAG_PREFIX + key, 0)
        val records = pending()
        records.remove(key)
        check(preferences.edit().putString("pending", records.toString()).commit())
        mapOf("protocol" to 1, "key" to key, "cancelled" to true, "postedCleared" to true)
    }

    fun cancelAllPending(): Map<String, Any> = synchronized(lock) {
        var confirmed = true
        try {
            val records = pending()
            val keys = records.keys().asSequence().toList()
            for (key in keys) cancel(key)
            val handled = receipts()
            for (key in handled.keys()) notifications.cancel(TAG_PREFIX + key, 0)
        } catch (_: Exception) { confirmed = false }
        // Clear only this feature's posted notifications, never other app features.
        try {
            if (Build.VERSION.SDK_INT >= 23) {
                for (posted in notifications.activeNotifications) {
                    if (posted.tag?.startsWith(TAG_PREFIX) == true) notifications.cancel(posted.tag, posted.id)
                }
            }
        } catch (_: Exception) { confirmed = false }
        mapOf("protocol" to 1, "cancelledAll" to confirmed, "postedCleared" to confirmed)
    }

    fun disableAndCancelAll(): Map<String, Any> = synchronized(lock) {
        // Commit Off and invalidate in-flight revisions before touching OS jobs.
        check(preferences.edit().putBoolean("enabled", false).putBoolean("acknowledged", false)
            .putLong("revision", Math.addExact(revision(), 1)).commit())
        cancelAllPending() + mapOf("consentEnabled" to false)
    }

    fun upsert(args: Map<*, *>): Map<String, Any> = synchronized(lock) {
        val key = args["key"] as? String ?: error("invalid request")
        val owner = args["ownerScope"] as? String ?: error("invalid request")
        val trigger = integer(args["notBeforeUtcMillis"]) ?: error("invalid request")
        val expiry = integer(args["expiresAtUtcMillis"]) ?: error("invalid request")
        val expected = integer(args["expectedRevision"]) ?: error("invalid request")
        require(args["deliveryMode"] == "inexact" && args["redaction"] == "generic" &&
            args["title"] == TaskReminderNativePolicy.TITLE && args["body"] == TaskReminderNativePolicy.BODY)
        if (!access()) { cancelAllPending(); error("not authorized") }
        val records = pending()
        val handled = receipts()
        val record = JSONObject().put("key", key).put("ownerScope", owner).put("trigger", trigger)
            .put("expiry", expiry).put("revision", expected).put("armed", false)
        require(TaskReminderNativePolicy.schedule(access(), key, owner, scope(), revision(), expected,
            System.currentTimeMillis(), trigger, expiry, handled.has(key), records.length(), records.has(key), authoritative(record)))
        check(handled.length() < TaskReminderNativePolicy.MAX_RECEIPTS)
        records.put(key, record)
        check(preferences.edit().putString("pending", records.toString()).commit())
        val intent = alarmIntent(key, true) ?: error("alarm unavailable")
        try {
            // Inexact only: no setExact, alarm-clock API, or exact-alarm permission.
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, intent)
            record.put("armed", true)
            check(preferences.edit().putString("pending", records.toString()).commit())
        } catch (error: Exception) {
            alarms.cancel(intent)
            throw error
        }
        mapOf("protocol" to 1, "key" to key, "ownerScope" to owner, "revision" to expected,
            "ledgerCommitted" to true, "inexact" to true, "redacted" to true)
    }

    fun deliver(key: String) = synchronized(lock) {
        if (!TaskReminderNativePolicy.key(key)) return@synchronized
        try {
            val records = pending()
            val record = records.optJSONObject(key) ?: return@synchronized
            val handled = receipts()
            val eligible = TaskReminderNativePolicy.deliver(access(), key, record.getString("ownerScope"), scope(),
                record.getLong("revision"), revision(), System.currentTimeMillis(), record.getLong("trigger"),
                record.getLong("expiry"), record.optBoolean("armed", false), handled.has(key), handled.length(), authoritative(record))
            if (!eligible) { cancel(key); return@synchronized }
            // At-most-once attempt: receipt is durable BEFORE notify. A crash or
            // rejected post after this commit may lose an alert, never replay it.
            handled.put(key, record.getLong("expiry")); records.remove(key)
            check(preferences.edit().putString("receipts", handled.toString()).putString("pending", records.toString()).commit())
            if (!access() || !TaskReminderNativePolicy.withinWindow(System.currentTimeMillis(), record.getLong("trigger"), record.getLong("expiry")) || !authoritative(record)) return@synchronized
            val channel = NotificationChannel(CHANNEL, "Task reminders", NotificationManager.IMPORTANCE_DEFAULT)
            channel.lockscreenVisibility = Notification.VISIBILITY_SECRET
            notifications.createNotificationChannel(channel)
            if (!access() || !TaskReminderNativePolicy.withinWindow(System.currentTimeMillis(), record.getLong("trigger"), record.getLong("expiry")) || !authoritative(record)) return@synchronized
            val builder = Notification.Builder(app, CHANNEL).setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(TaskReminderNativePolicy.TITLE).setContentText(TaskReminderNativePolicy.BODY)
                .setVisibility(Notification.VISIBILITY_SECRET).setAutoCancel(true).setOnlyAlertOnce(true)
            app.packageManager.getLaunchIntentForPackage(app.packageName)?.let {
                builder.setContentIntent(PendingIntent.getActivity(app, 0, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
            }
            notifications.notify(TAG_PREFIX + key, 0, builder.build())
        } catch (_: Exception) {
            // No private diagnostics in logs. Leave delivery unclaimed.
        }
    }

    private fun authoritative(record: JSONObject): Boolean {
        if (Build.VERSION.SDK_INT < 26) return false
        val file = File(app.filesDir, "database/new_man.sqlite")
        if (!file.isFile) return false
        return try {
            SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY).use { db ->
                db.rawQuery("SELECT id,due_date,reminder_minutes_local,reminder_dismissed_key FROM tasks WHERE is_completed=0 AND due_date IS NOT NULL AND reminder_minutes_local IS NOT NULL LIMIT 1000", null).use { cursor ->
                    while (cursor.moveToNext()) {
                        val day = cursor.getString(1)
                        val minutes = cursor.getInt(2)
                        if (minutes !in 0..1439) continue
                        val reminderKey = "${cursor.getString(1)}:$minutes"
                        if (!cursor.isNull(3) && cursor.getString(3) == reminderKey) continue
                        val hash = TaskReminderNativePolicy.occurrenceKey(record.getString("ownerScope"), cursor.getString(0), reminderKey)
                        if (hash != record.getString("key")) continue
                        val zone = ZoneId.systemDefault().id
                        return TaskReminderNativePolicy.resolveTrigger(day, minutes, zone) == record.getLong("trigger") &&
                            TaskReminderNativePolicy.resolveExpiry(day, zone) == record.getLong("expiry")
                    }
                    false
                }
            }
        } catch (_: Exception) { false }
    }

    fun resetForSystemBoundary() { cancelAllPending() } // No automatic rearm after reboot/clock/zone changes.
    fun integer(value: Any?): Long? = when (value) { is Int -> value.toLong(); is Long -> value; else -> null }
}

/** Not registered by MainActivity. Permission UI requires a separately audited host callback. */
class TaskReminderNativeChannel(context: Context, private val permissionRequest: ((() -> Unit) -> Unit)? = null) : MethodChannel.MethodCallHandler {
    private val backend = TaskReminderNativeBackend(context)
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "com.newman.newmanapp/task_reminders_v1").setMethodCallHandler(this)
    }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        try {
            require(args != null && backend.integer(args["protocol"]) == 1L)
            when (call.method) {
                "getState" -> result.success(backend.state())
                "cancel" -> result.success(backend.cancel(args["key"] as? String ?: error("invalid request")))
                "cancelAllPending" -> result.success(backend.cancelAllPending())
                "disableAndCancelAll" -> result.success(backend.disableAndCancelAll())
                "upsert" -> result.success(backend.upsert(args))
                "enableFromUserAction" -> {
                    if (!backend.canAttemptEnable(args)) { result.success(backend.state()); return }
                    val finish = { try { result.success(backend.finishEnable(args)) } catch (_: Exception) { result.error("unconfirmed", "Reminder operation unconfirmed", null) } }
                    if (backend.needsPermission() && permissionRequest != null) permissionRequest.invoke(finish) else finish()
                }
                else -> result.notImplemented()
            }
        } catch (_: Exception) { result.error("unconfirmed", "Reminder operation unconfirmed", null) }
    }
}

/** Undeclared in all manifests: no alarm or system broadcast can reach these yet. */
class TaskReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TaskReminderNativeBackend.ACTION || intent.data?.scheme != "newman-task-reminder" || intent.data?.authority != context.packageName) return
        val key = intent.data?.lastPathSegment ?: return
        TaskReminderNativeBackend(context).deliver(key)
    }
}

class TaskReminderSystemReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action in setOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED)) {
            TaskReminderNativeBackend(context).resetForSystemBoundary()
        }
    }
}
