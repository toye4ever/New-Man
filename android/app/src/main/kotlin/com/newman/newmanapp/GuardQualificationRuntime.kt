package com.newman.newmanapp

import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import java.util.LinkedHashSet

/** Process-local owner of the qualification lease. Nothing here is persisted. */
object GuardQualificationRuntime {
    private val lease = GuardQualificationLease(
        { SystemClock.elapsedRealtime() },
        { SystemClock.uptimeMillis() },
    )
    private val eventDelivery = GuardQualificationLease.EventDeliveryTransaction(lease)
    private val handler = Handler(Looper.getMainLooper())
    private var applicationContext: Context? = null
    private var serviceConnected = false
    private var disclosureAccepted = false
    private var scheduledWakeup: Runnable? = null
    private var scheduledWindowAction: Runnable? = null
    private var scheduledWindowActionToken = 0L
    private var eventDeliveryController: ((Boolean) -> Boolean)? = null

    @Synchronized
    fun initialize(context: Context) {
        applicationContext = context.applicationContext
    }

    @Synchronized
    fun onServiceConnected(
        context: Context,
        updateEventDelivery: (Boolean) -> Boolean,
    ) {
        initialize(context)
        disclosureAccepted = false
        cancelWakeupLocked()
        cancelWindowActionLocked()
        serviceConnected = false
        eventDeliveryController = updateEventDelivery
        eventDelivery.invalidate()
        var snapshot = lease.onServiceConnectionOpened()
        val deliveryFailure = applyEventDeliveryLocked(active = false)
        if (deliveryFailure == null) {
            serviceConnected = true
        } else {
            snapshot = deliveryFailure
        }
        rescheduleLocked(snapshot)
    }

    @Synchronized
    fun onServiceDisconnected() {
        val deliveryFailure = applyEventDeliveryLocked(active = false)
        serviceConnected = false
        disclosureAccepted = false
        cancelWakeupLocked()
        cancelWindowActionLocked()
        eventDeliveryController = null
        if (deliveryFailure == null) {
            lease.onServiceConnectionClosed()
        }
    }

    @Synchronized
    fun onServiceInterrupted() {
        val deliveryFailure = applyEventDeliveryLocked(active = false)
        serviceConnected = false
        disclosureAccepted = false
        cancelWakeupLocked()
        cancelWindowActionLocked()
        eventDeliveryController = null
        if (deliveryFailure == null) {
            lease.interrupt("service_interrupted")
        }
    }

    @Synchronized
    fun status(): Map<String, Any?> {
        return payload(rescheduleLocked(lease.snapshot(disclosureAccepted, serviceConnected)))
    }

    @Synchronized
    fun start(
        rawTargetIds: List<String>,
        durationMinutes: Long,
        acceptedDisclosure: Boolean,
    ): Map<String, Any?> {
        if (rawTargetIds.isEmpty() || rawTargetIds.toSet().size != rawTargetIds.size) {
            throw IllegalArgumentException("A unique whole-app selection is required.")
        }
        val targetIds = LinkedHashSet(rawTargetIds)
        if (!targetIds.all(GuardQualificationTargets::isSupportedTargetId)) {
            throw IllegalArgumentException("Only whole-app qualification targets are supported.")
        }
        if (!acceptedDisclosure) {
            throw IllegalArgumentException("Disclosure consent is required.")
        }
        if (!serviceConnected) {
            throw IllegalStateException("The accessibility service is not connected.")
        }
        val context = applicationContext
            ?: throw IllegalStateException("The qualification runtime is unavailable.")
        targetIds.forEach { targetId ->
            if (!isPackageInstalledAndEnabled(
                    context,
                    GuardQualificationTargets.packageForTarget(targetId),
                )
            ) {
                throw IllegalStateException("A selected app is unavailable.")
            }
        }

        var snapshot = lease.start(targetIds, durationMinutes, true, true)
        disclosureAccepted = true
        snapshot = rescheduleLocked(snapshot)
        if (snapshot.state != GuardQualificationLease.State.RUNNING) {
            throw IllegalStateException("Active event delivery is unavailable.")
        }
        return payload(snapshot)
    }

    @Synchronized
    fun pause(): Map<String, Any?> {
        val snapshot = rescheduleLocked(lease.pause(disclosureAccepted, serviceConnected))
        return payload(snapshot)
    }

    @Synchronized
    fun resume(): Map<String, Any?> {
        val snapshot = rescheduleLocked(lease.resume(disclosureAccepted, serviceConnected))
        return payload(snapshot)
    }

    @Synchronized
    fun end(): Map<String, Any?> {
        disclosureAccepted = false
        cancelWakeupLocked()
        cancelWindowActionLocked()
        return payload(rescheduleLocked(lease.end()))
    }

    @Synchronized
    fun handleWindowEntry(
        eventUptimeMillis: Long,
        packageName: () -> String?,
        sendHome: () -> Boolean,
    ) {
        // Do not read package/event payload while idle, paused, expired, revoked,
        // disconnected, or lacking current-process disclosure consent.
        if (!lease.canInspectWindowEntry(
                eventUptimeMillis,
                disclosureAccepted,
                serviceConnected,
            )
        ) {
            rescheduleLocked(lease.snapshot(disclosureAccepted, serviceConnected))
            return
        }

        val targetId = GuardQualificationTargets.targetForPackage(packageName())
        val decision = lease.evaluateWindowEntry(
            targetId,
            eventUptimeMillis,
            disclosureAccepted,
            serviceConnected,
        )
        if (!decision.acceptedTransition()) return
        cancelWindowActionLocked()
        if (!decision.shouldScheduleAction()) return

        val token = decision.actionToken
        val callback = Runnable { handleSettledWindowEntry(token, sendHome) }
        scheduledWindowAction = callback
        scheduledWindowActionToken = token
        if (!handler.postDelayed(
                callback,
                GuardQualificationLease.WINDOW_ENTRY_SETTLE_MILLIS,
            )
        ) {
            scheduledWindowAction = null
            scheduledWindowActionToken = 0L
            disclosureAccepted = false
            rescheduleLocked(lease.fail("event_delivery_unavailable"))
        }
    }

    @Synchronized
    private fun handleSettledWindowEntry(token: Long, sendHome: () -> Boolean) {
        if (token != scheduledWindowActionToken) return
        scheduledWindowAction = null
        scheduledWindowActionToken = 0L
        if (!eventDelivery.isKnownActive ||
            !lease.takeWindowEntryAction(token, disclosureAccepted, serviceConnected)
        ) {
            rescheduleLocked(lease.snapshot(disclosureAccepted, serviceConnected))
            return
        }

        val succeeded = try {
            sendHome()
        } catch (_: RuntimeException) {
            false
        }
        val snapshot = lease.completeWindowEntryAction(token, succeeded)
        if (!succeeded) disclosureAccepted = false
        rescheduleLocked(snapshot)
    }

    @Synchronized
    private fun handleWakeup(token: Long) {
        rescheduleLocked(lease.onWakeup(token, disclosureAccepted, serviceConnected))
    }

    private fun rescheduleLocked(
        initialSnapshot: GuardQualificationLease.Snapshot,
    ): GuardQualificationLease.Snapshot {
        var snapshot = initialSnapshot
        cancelWakeupLocked()
        val shouldUseActiveDelivery =
            snapshot.state == GuardQualificationLease.State.RUNNING
        val deliveryFailure = applyEventDeliveryLocked(shouldUseActiveDelivery)
        if (deliveryFailure != null) {
            disclosureAccepted = false
            cancelWindowActionLocked()
            snapshot = deliveryFailure
        }
        if (snapshot.state != GuardQualificationLease.State.RUNNING ||
            snapshot.remainingMillis <= 0L
        ) {
            cancelWindowActionLocked()
            if (snapshot.state != GuardQualificationLease.State.PAUSED) {
                disclosureAccepted = false
            }
            return snapshot
        }
        val token = snapshot.wakeupToken
        val callback = Runnable { handleWakeup(token) }
        scheduledWakeup = callback
        // Handler time is only a display/wakeup helper. Every status and event decision
        // re-evaluates the elapsed-realtime lease, including after deep sleep.
        if (!handler.postDelayed(callback, snapshot.remainingMillis)) {
            scheduledWakeup = null
            disclosureAccepted = false
            cancelWindowActionLocked()
            snapshot = lease.fail("event_delivery_unavailable")
            applyEventDeliveryLocked(active = false)?.let { snapshot = it }
        }
        return snapshot
    }

    private fun cancelWakeupLocked() {
        scheduledWakeup?.let(handler::removeCallbacks)
        scheduledWakeup = null
    }

    private fun cancelWindowActionLocked() {
        scheduledWindowAction?.let(handler::removeCallbacks)
        scheduledWindowAction = null
        scheduledWindowActionToken = 0L
    }

    private fun applyEventDeliveryLocked(
        active: Boolean,
    ): GuardQualificationLease.Snapshot? {
        val updater = eventDeliveryController?.let { controller ->
            GuardQualificationLease.EventDeliveryUpdater { requestedActive ->
                controller(requestedActive)
            }
        }
        return eventDelivery.applyOrFailLease(active, updater)
    }

    private fun payload(snapshot: GuardQualificationLease.Snapshot): Map<String, Any?> =
        mapOf(
            "schemaVersion" to 1,
            "platform" to "android",
            "status" to snapshot.state.name.lowercase(),
            "remainingMillis" to snapshot.remainingMillis,
            "selectedTargetIds" to snapshot.selectedTargetIds.toList(),
            "serviceConnected" to serviceConnected,
            "disclosureAccepted" to
                (disclosureAccepted &&
                    (snapshot.state == GuardQualificationLease.State.RUNNING ||
                        snapshot.state == GuardQualificationLease.State.PAUSED)),
            "detailCode" to snapshot.detailCode,
        )

    private fun isPackageInstalledAndEnabled(context: Context, packageName: String): Boolean {
        return try {
            val packageInfo = context.packageManager.getPackageInfo(packageName, 0)
            val applicationInfo = packageInfo.applicationInfo ?: return false
            when (context.packageManager.getApplicationEnabledSetting(packageName)) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
                PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> applicationInfo.enabled
                else -> false
            }
        } catch (_: PackageManager.NameNotFoundException) {
            false
        } catch (_: RuntimeException) {
            false
        }
    }

}
