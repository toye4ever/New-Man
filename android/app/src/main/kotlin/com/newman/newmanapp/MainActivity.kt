package com.newman.newmanapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var guardQualificationChannel: GuardQualificationChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GuardReadinessChannel(applicationContext).register(flutterEngine.dartExecutor.binaryMessenger)
        guardQualificationChannel = GuardQualificationChannel(applicationContext).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        guardQualificationChannel?.unregister()
        guardQualificationChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

