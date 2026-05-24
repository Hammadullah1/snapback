package com.example.flutter_application_1

import io.flutter.embedding.engine.FlutterEngine

/**
 * Singleton holding the Flutter engine so background services
 * (OverlayService, AccessibilityService) can invoke Dart MethodChannels
 * even when the activity isn't alive.
 *
 * The MainActivity attaches the engine on creation. If the engine isn't
 * attached yet, services will fall back to safe defaults.
 */
object SnapBackEngineHolder {
    @Volatile
    var engine: FlutterEngine? = null
        private set

    fun attach(e: FlutterEngine) {
        engine = e
    }

    fun detach() {
        engine = null
    }
}
