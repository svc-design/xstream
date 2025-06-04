package com.example.xstream

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.xstream/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startNodeService" -> {
                    val intent = Intent(this, XrayService::class.java).apply { action = XrayService.ACTION_START }
                    startService(intent)
                    result.success("started")
                }
                "stopNodeService" -> {
                    val intent = Intent(this, XrayService::class.java).apply { action = XrayService.ACTION_STOP }
                    startService(intent)
                    result.success("stopped")
                }
                "performAction" -> {
                    val action = call.argument<String>("action")
                    if (action == "initXray") {
                        val intent = Intent(this, XrayService::class.java).apply { action = XrayService.ACTION_START }
                        startService(intent)
                        result.success("initialized")
                    } else {
                        result.notImplemented()
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
