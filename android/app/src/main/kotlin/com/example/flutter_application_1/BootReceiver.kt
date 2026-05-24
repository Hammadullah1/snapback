package com.example.flutter_application_1

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receives BOOT_COMPLETED. The Accessibility Service is auto-started by the
 * system once it's enabled in settings, so we don't need to start it here.
 * This receiver exists as a hook for any future scheduled work that should
 * survive reboot (e.g., re-arming alarms).
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED) return
        Log.i("SnapBackBoot", "BOOT_COMPLETED received")
        // Future: re-schedule any alarms here if needed.
    }
}
