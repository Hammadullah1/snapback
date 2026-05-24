package com.example.flutter_application_1

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val PERMISSIONS_CHANNEL = "com.snapback.app/permissions"
    private val OVERLAY_CHANNEL = "com.snapback.app/overlay"
    private val NATIVE_SYNC_CHANNEL = "com.snapback.app/native_sync"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Cache the Flutter engine so background services (OverlayService) can
        // call back into Dart agents even after the activity is gone.
        SnapBackEngineHolder.attach(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" -> result.success(isAccessibilityEnabled())
                    "isOverlayGranted" -> result.success(isOverlayGranted())
                    "openAccessibilitySettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }
                    "openOverlaySettings" -> {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showOverlay" -> {
                        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                        val appName = args["appName"] as? String ?: "this app"
                        val minutes = (args["minutes"] as? Int) ?: 15
                        startOverlay(appName, minutes, snoozeCount = 0)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_SYNC_CHANNEL)
            .setMethodCallHandler { call, result ->
                val prefs = applicationContext.getSharedPreferences("snapback_native", MODE_PRIVATE)
                when (call.method) {
                    "pushPrefs" -> {
                        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                        val limit = (args["scroll_limit_minutes"] as? Int) ?: 15
                        val apps = (args["monitored_apps"] as? List<*>)
                            ?.filterIsInstance<String>()
                            ?.joinToString(",") ?: ""
                        prefs.edit()
                            .putInt("scroll_limit_minutes", limit)
                            .putString("monitored_apps", apps)
                            .apply()
                        result.success(null)
                    }
                    "drainPendingSessions" -> {
                        val csv = prefs.getString("pending_sessions", "") ?: ""
                        prefs.edit().remove("pending_sessions").apply()
                        result.success(csv)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startOverlay(appName: String, minutes: Int, snoozeCount: Int) {
        val intent = Intent(this, OverlayService::class.java).apply {
            putExtra("appName", appName)
            putExtra("minutes", minutes)
            putExtra("snoozeCount", snoozeCount)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun isOverlayGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else true
    }

    private fun isAccessibilityEnabled(): Boolean {
        val expected = ComponentName(this, SnapBackAccessibilityService::class.java)
            .flattenToString()
        val enabled = try {
            Settings.Secure.getInt(contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED) == 1
        } catch (_: Settings.SettingNotFoundException) {
            false
        }
        if (!enabled) return false
        val services = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(services)
        while (splitter.hasNext()) {
            val name = splitter.next()
            if (name.equals(expected, ignoreCase = true)) return true
        }
        return false
    }
}
