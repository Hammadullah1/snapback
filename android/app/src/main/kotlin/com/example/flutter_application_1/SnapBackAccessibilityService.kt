package com.example.flutter_application_1

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * Detects foreground-app changes for the monitored social apps.
 * Tracks duration in the current app; when the user exceeds their scroll
 * limit, launches OverlayService to render the intervention.
 *
 * The accessibility service is the source of truth for "time spent in app";
 * the in-app scroll detection (TYPE_VIEW_SCROLLED) is unreliable across
 * Android versions, so we use foreground-app duration which works everywhere.
 */
class SnapBackAccessibilityService : AccessibilityService() {

    private val tag = "SnapBackA11y"

    private val defaultMonitored = setOf(
        "com.instagram.android",
        "com.zhiliaoapp.musically",
        "com.google.android.youtube",
        "com.snapchat.android"
    )

    private val displayNames = mapOf(
        "com.instagram.android" to "Instagram",
        "com.zhiliaoapp.musically" to "TikTok",
        "com.google.android.youtube" to "YouTube",
        "com.snapchat.android" to "Snapchat"
    )

    private var currentApp: String? = null
    private var appOpenedAt: Long = 0L
    private var intervenedThisSession: Boolean = false
    private var snoozeCount: Int = 0
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var prefs: SharedPreferences

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = applicationContext.getSharedPreferences("snapback_native", MODE_PRIVATE)
        scheduleCheck()
        Log.i(tag, "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val pkg = event.packageName?.toString() ?: return

        if (pkg == currentApp) return

        // App switch: close previous session if it was a monitored one.
        currentApp?.let { closePreviousSession(it) }

        if (pkg in monitoredPackages()) {
            currentApp = pkg
            appOpenedAt = System.currentTimeMillis()
            intervenedThisSession = false
            snoozeCount = 0
            Log.i(tag, "Entered monitored app: $pkg")
        } else {
            currentApp = null
            appOpenedAt = 0L
        }
    }

    private fun monitoredPackages(): Set<String> {
        val saved = prefs.getString("monitored_apps", null)
        if (saved.isNullOrBlank()) return defaultMonitored
        return saved.split(",")
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .toSet()
            .ifEmpty { defaultMonitored }
    }

    override fun onInterrupt() {}

    override fun onUnbind(intent: Intent?): Boolean {
        currentApp?.let { closePreviousSession(it) }
        handler.removeCallbacksAndMessages(null)
        return super.onUnbind(intent)
    }

    private fun closePreviousSession(pkg: String) {
        if (appOpenedAt <= 0L) return
        val ended = System.currentTimeMillis()
        val durationSec = ((ended - appOpenedAt) / 1000).toInt().coerceAtLeast(0)
        if (durationSec < 5) return // ignore tiny blips

        // Persist a session record to native prefs so Dart can pick it up.
        // Format: a CSV ring buffer of pending sessions, drained by Dart on app open.
        val existing = prefs.getString("pending_sessions", "") ?: ""
        val entry = listOf(
            pkg,
            displayNames[pkg] ?: pkg,
            appOpenedAt.toString(),
            ended.toString(),
            durationSec.toString(),
            intervenedThisSession.toString(),
            snoozeCount.toString()
        ).joinToString(",")
        val next = if (existing.isEmpty()) entry else "$existing\n$entry"
        prefs.edit().putString("pending_sessions", next).apply()

        Log.i(tag, "Closed session: $pkg, ${durationSec}s")
        appOpenedAt = 0L
    }

    private fun scheduleCheck() {
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed(checkRunnable, 30_000L)
    }

    private val checkRunnable = object : Runnable {
        override fun run() {
            try {
                val pkg = currentApp
                val started = appOpenedAt
                if (pkg != null && started > 0L && !intervenedThisSession) {
                    val elapsedSec = (System.currentTimeMillis() - started) / 1000
                    val limitMin = prefs.getInt("scroll_limit_minutes", 15)
                    if (elapsedSec >= limitMin * 60L) {
                        triggerOverlay(pkg, (elapsedSec / 60).toInt())
                    }
                }
            } catch (e: Exception) {
                Log.e(tag, "check error", e)
            } finally {
                scheduleCheck()
            }
        }
    }

    private fun triggerOverlay(pkg: String, minutes: Int) {
        intervenedThisSession = true
        val intent = Intent(this, OverlayService::class.java).apply {
            putExtra("appName", displayNames[pkg] ?: pkg)
            putExtra("packageName", pkg)
            putExtra("minutes", minutes)
            putExtra("snoozeCount", snoozeCount)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
