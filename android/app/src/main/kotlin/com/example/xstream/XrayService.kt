package com.example.xstream

import android.app.Service
import android.content.Intent
import android.net.VpnService
import android.os.IBinder
import java.io.File
import java.io.IOException

class XrayService : VpnService() {
    private var process: Process? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startXray()
            ACTION_STOP -> stopXray()
        }
        return Service.START_STICKY
    }

    private fun startXray() {
        if (process != null) return
        val binary = File(filesDir, "xray")
        if (!binary.exists()) {
            try {
                assets.open("xray-android-arm64").use { input ->
                    binary.outputStream().use { output -> input.copyTo(output) }
                }
                binary.setExecutable(true)
            } catch (e: IOException) {
                e.printStackTrace()
                return
            }
        }
        val config = File(filesDir, "config.json")
        if (!config.exists()) {
            assets.open("xray-vpn.json").use { input ->
                config.outputStream().use { output -> input.copyTo(output) }
            }
        }
        Builder().apply {
            setSession("Xray")
            addAddress("10.0.0.2", 32)
            addRoute("0.0.0.0", 0)
            establish()
        }
        try {
            process = ProcessBuilder(binary.absolutePath, "-config", config.absolutePath).start()
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    private fun stopXray() {
        process?.destroy()
        process = null
    }

    override fun onDestroy() {
        stopXray()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    companion object {
        const val ACTION_START = "com.example.xstream.action.START"
        const val ACTION_STOP = "com.example.xstream.action.STOP"
    }
}
