package com.example.flutter_application_1

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.text.Editable
import android.text.TextWatcher
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import io.flutter.plugin.common.MethodChannel

class OverlayService : Service() {

    private val tag = "OverlayService"
    private val channelFlutter = "com.snapback.app/overlay"
    private val foregroundChannelId = "snapback_overlay_fg"
    private val foregroundId = 4242

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())

    private var appName: String = "this app"
    private var minutes: Int = 15
    private var snoozeCount: Int = 0

    private var debounceJob: Runnable? = null
    private var distressShown: Boolean = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        appName = intent?.getStringExtra("appName") ?: appName
        minutes = intent?.getIntExtra("minutes", minutes) ?: minutes
        snoozeCount = intent?.getIntExtra("snoozeCount", 0) ?: 0

        startForegroundNotification()
        showOverlay()
        fetchMessageFromFlutter()
        return START_NOT_STICKY
    }

    private fun startForegroundNotification() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                foregroundChannelId,
                getString(R.string.fg_channel_name),
                NotificationManager.IMPORTANCE_LOW
            )
            nm.createNotificationChannel(ch)
        }
        val notif: Notification = Notification.Builder(this, foregroundChannelId)
            .setContentTitle(getString(R.string.fg_notification_title))
            .setContentText(getString(R.string.fg_notification_body))
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                foregroundId,
                notif,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(foregroundId, notif)
        }
    }

    private fun showOverlay() {
        if (overlayView != null) return
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv() and 0 or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
            softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
        }

        val view = LayoutInflater.from(this).inflate(R.layout.overlay_intervention, null)
        overlayView = view

        val input = view.findViewById<EditText>(R.id.input)
        val hint = view.findViewById<TextView>(R.id.inputHint)
        val btnDone = view.findViewById<Button>(R.id.btnDone)
        val btnSnooze = view.findViewById<Button>(R.id.btnSnooze)
        val helpline = view.findViewById<TextView>(R.id.helpline)
        val messageView = view.findViewById<TextView>(R.id.message)

        // snooze visibility — hide after max
        if (snoozeCount >= 2) {
            btnSnooze.visibility = View.GONE
        }

        input.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                val len = s?.length ?: 0
                val unlocked = len >= 5
                btnDone.isEnabled = unlocked
                btnDone.alpha = if (unlocked) 1f else 0.5f
                btnSnooze.isEnabled = unlocked
                btnSnooze.alpha = if (unlocked) 1f else 0.5f
                hint.text = if (unlocked) " " else "Type ${5 - len} more characters to unlock"

                debounceJob?.let { handler.removeCallbacks(it) }
                val text = s?.toString().orEmpty()
                if (text.length >= 5) {
                    val r = Runnable { classifyMood(text, messageView, helpline, btnSnooze) }
                    debounceJob = r
                    handler.postDelayed(r, 1000)
                }
            }
        })

        btnDone.setOnClickListener {
            stopSelfClean()
        }
        btnSnooze.setOnClickListener {
            // Bump snooze count in prefs so accessibility service can hide button next time.
            val prefs = applicationContext.getSharedPreferences("snapback_native", MODE_PRIVATE)
            prefs.edit().putInt("last_snooze_count", snoozeCount + 1).apply()
            stopSelfClean()
        }

        try {
            windowManager?.addView(view, params)
        } catch (e: Exception) {
            Log.e(tag, "addView failed", e)
            stopSelfClean()
        }
    }

    private fun fetchMessageFromFlutter() {
        val engine = SnapBackEngineHolder.engine
        val messageView = overlayView?.findViewById<TextView>(R.id.message) ?: return
        if (engine == null) {
            messageView.text = fallbackMessage()
            return
        }
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, channelFlutter)
        channel.invokeMethod(
            "getInterventionMessage",
            mapOf("appName" to appName, "minutes" to minutes, "snoozeCount" to snoozeCount),
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    val msg = result as? String ?: fallbackMessage()
                    handler.post { messageView.text = msg }
                }
                override fun error(code: String, msg: String?, details: Any?) {
                    handler.post { messageView.text = fallbackMessage() }
                }
                override fun notImplemented() {
                    handler.post { messageView.text = fallbackMessage() }
                }
            }
        )
    }

    private fun classifyMood(
        text: String,
        messageView: TextView,
        helpline: TextView,
        snooze: Button
    ) {
        if (distressShown) return
        val engine = SnapBackEngineHolder.engine ?: return
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, channelFlutter)
        channel.invokeMethod(
            "classifyMood",
            mapOf("text" to text),
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    val map = result as? Map<*, *> ?: return
                    val distress = map["is_distress"] as? Boolean ?: false
                    if (!distress) return
                    val response = map["response"] as? String ?: ""
                    handler.post {
                        distressShown = true
                        if (response.isNotEmpty()) messageView.text = response
                        helpline.visibility = View.VISIBLE
                        snooze.visibility = View.GONE
                    }
                }
                override fun error(code: String, msg: String?, details: Any?) {}
                override fun notImplemented() {}
            }
        )
    }

    private fun fallbackMessage(): String {
        val pool = listOf(
            "You've been on $appName for $minutes minutes. Your planner is waiting.",
            "$minutes minutes is enough for now. Pick one small thing from your list.",
            "Step away from $appName. Your future self will thank you.",
            "Scroll's been long. There's a small task that fits in 10 minutes — go do it.",
            "You came for a quick break. It stopped being quick a while ago."
        )
        return pool.random()
    }

    private fun stopSelfClean() {
        try {
            overlayView?.let { windowManager?.removeView(it) }
        } catch (_: Exception) {}
        overlayView = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        try {
            overlayView?.let { windowManager?.removeView(it) }
        } catch (_: Exception) {}
        overlayView = null
        super.onDestroy()
    }
}
