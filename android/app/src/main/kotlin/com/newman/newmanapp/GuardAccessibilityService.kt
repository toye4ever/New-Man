package com.newman.newmanapp

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class GuardAccessibilityService : AccessibilityService() {
    override fun onServiceConnected() {
        super.onServiceConnected()
        GuardQualificationRuntime.onServiceConnected(
            applicationContext,
            ::updateEventDelivery,
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        GuardQualificationRuntime.handleWindowEntry(
            event.eventTime,
            { event.packageName?.toString() },
            { performGlobalAction(GLOBAL_ACTION_HOME) },
        )
    }

    override fun onInterrupt() {
        GuardQualificationRuntime.onServiceInterrupted()
    }

    override fun onUnbind(intent: Intent?): Boolean {
        GuardQualificationRuntime.onServiceDisconnected()
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        GuardQualificationRuntime.onServiceDisconnected()
        super.onDestroy()
    }

    /**
     * Observe all app-change identities only while a consented lease is running.
     * Idle delivery stays limited to the four fixed readiness packages. No window
     * content is requested, and a zero timeout avoids coalescing a departure that
     * must cancel a queued target action.
     */
    private fun updateEventDelivery(active: Boolean): Boolean = try {
        val info = serviceInfo ?: return false
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.notificationTimeout = 0L
        info.packageNames = if (active) null else IDLE_PACKAGES.clone()
        serviceInfo = info
        val applied = serviceInfo ?: return false
        applied.eventTypes == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            applied.notificationTimeout == 0L &&
            if (active) {
                applied.packageNames == null
            } else {
                applied.packageNames?.toSet() == IDLE_PACKAGES.toSet()
            }
    } catch (_: RuntimeException) {
        false
    }

    companion object {
        private val IDLE_PACKAGES = GuardQualificationTargets.packageNames().toTypedArray()
    }
}
