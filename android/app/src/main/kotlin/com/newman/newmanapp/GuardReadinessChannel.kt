package com.newman.newmanapp

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class GuardReadinessChannel(private val context: Context) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            if (call.method != METHOD_GET_READINESS) {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                result.success(
                    mapOf(
                        "schemaVersion" to 1,
                        "platform" to "android",
                        "apps" to GuardQualificationTargets.packageNames().map(::readPackage),
                    ),
                )
            } catch (_: RuntimeException) {
                result.error("guard_readiness_unavailable", "Readiness is unavailable.", null)
            }
        }
    }

    private fun readPackage(packageName: String): Map<String, Any?> {
        return try {
            val packageInfo = context.packageManager.getPackageInfo(packageName, 0)
            mapOf(
                "packageName" to packageName,
                "installed" to true,
                "enabled" to isPackageEnabled(packageName, packageInfo),
                "versionName" to packageInfo.versionName,
                "versionCode" to packageInfo.longVersionCodeCompat(),
            )
        } catch (_: PackageManager.NameNotFoundException) {
            mapOf(
                "packageName" to packageName,
                "installed" to false,
                "enabled" to false,
                "versionName" to null,
                "versionCode" to null,
            )
        }
    }

    private fun isPackageEnabled(packageName: String, packageInfo: PackageInfo): Boolean {
        return when (context.packageManager.getApplicationEnabledSetting(packageName)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED_UNTIL_USED -> false
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> packageInfo.applicationInfo?.enabled ?: false
            else -> false
        }
    }

    @Suppress("DEPRECATION")
    private fun PackageInfo.longVersionCodeCompat(): Long =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) longVersionCode else versionCode.toLong()

    companion object {
        private const val CHANNEL_NAME = "com.newman.newmanapp/guard_readiness"
        private const val METHOD_GET_READINESS = "getReadiness"
    }
}
