package com.newman.newmanapp

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class GuardQualificationChannel(context: Context) {
    private val applicationContext = context.applicationContext
    private var channel: MethodChannel? = null

    init {
        GuardQualificationRuntime.initialize(applicationContext)
    }

    fun register(messenger: BinaryMessenger) {
        unregister()
        channel = MethodChannel(messenger, CHANNEL_NAME).also { methodChannel ->
            methodChannel.setMethodCallHandler(::handle)
        }
    }

    fun unregister() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                METHOD_GET_STATUS -> {
                    requireNoArguments(call)
                    result.success(GuardQualificationRuntime.status())
                }
                METHOD_START -> result.success(start(call))
                METHOD_PAUSE -> {
                    requireNoArguments(call)
                    result.success(GuardQualificationRuntime.pause())
                }
                METHOD_RESUME -> {
                    requireNoArguments(call)
                    result.success(GuardQualificationRuntime.resume())
                }
                METHOD_END -> {
                    requireNoArguments(call)
                    result.success(GuardQualificationRuntime.end())
                }
                METHOD_OPEN_SETTINGS -> {
                    requireNoArguments(call)
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    applicationContext.startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (_: IllegalArgumentException) {
            result.error("guard_qualification_rejected", "The test request was rejected.", null)
        } catch (_: IllegalStateException) {
            result.error("guard_qualification_unavailable", "The test is unavailable.", null)
        } catch (_: RuntimeException) {
            result.error("guard_qualification_error", "The test could not be updated.", null)
        }
    }

    private fun start(call: MethodCall): Map<String, Any?> {
        val arguments = call.arguments as? Map<*, *>
            ?: throw IllegalArgumentException("Start arguments are required.")
        if (arguments.keys != START_ARGUMENT_KEYS) {
            throw IllegalArgumentException("Unexpected start arguments.")
        }
        if (arguments["schemaVersion"] != 1) {
            throw IllegalArgumentException("Unsupported start schema.")
        }
        val rawTargets = arguments["selectedTargetIds"] as? List<*>
            ?: throw IllegalArgumentException("Targets are required.")
        if (!rawTargets.all { it is String }) {
            throw IllegalArgumentException("Targets are invalid.")
        }
        val duration = arguments["durationMinutes"]
        val durationLong = when (duration) {
            is Int -> duration.toLong()
            is Long -> duration
            else -> throw IllegalArgumentException("Duration must be integral.")
        }
        val accepted = arguments["disclosureAccepted"] as? Boolean
            ?: throw IllegalArgumentException("Disclosure consent is required.")
        @Suppress("UNCHECKED_CAST")
        return GuardQualificationRuntime.start(
            rawTargets as List<String>,
            durationLong,
            accepted,
        )
    }

    private fun requireNoArguments(call: MethodCall) {
        if (call.arguments != null) {
            throw IllegalArgumentException("This command accepts no arguments.")
        }
    }

    companion object {
        private const val CHANNEL_NAME = "com.newman.newmanapp/guard_qualification"
        private const val METHOD_GET_STATUS = "getStatus"
        private const val METHOD_START = "start"
        private const val METHOD_PAUSE = "pause"
        private const val METHOD_RESUME = "resume"
        private const val METHOD_END = "end"
        private const val METHOD_OPEN_SETTINGS = "openAccessibilitySettings"
        private val START_ARGUMENT_KEYS = setOf(
            "schemaVersion",
            "selectedTargetIds",
            "durationMinutes",
            "disclosureAccepted",
        )
    }
}
