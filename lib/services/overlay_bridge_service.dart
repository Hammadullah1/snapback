import 'package:flutter/services.dart';

import '../agents/intervention_agent.dart';
import '../agents/mood_safety_gate.dart';
import 'storage_service.dart';

/// Bridges native Android (AccessibilityService / OverlayService) → Flutter agents.
/// Android calls into Flutter to fetch the intervention message and to classify
/// distress typed by the user. The overlay itself is rendered natively.
class OverlayBridgeService {
  static const _channel = MethodChannel('com.snapback.app/overlay');

  final InterventionAgent _intervention;
  final MoodSafetyGate _moodGate;
  final StorageService _storage;

  OverlayBridgeService({
    required InterventionAgent intervention,
    required MoodSafetyGate moodGate,
    required StorageService storage,
  })  : _intervention = intervention,
        _moodGate = moodGate,
        _storage = storage;

  void start() {
    _channel.setMethodCallHandler(_handler);
  }

  Future<dynamic> _handler(MethodCall call) async {
    switch (call.method) {
      case 'getInterventionMessage':
        final args = (call.arguments as Map?) ?? {};
        final appName = (args['appName'] as String?) ?? 'this app';
        final minutes = (args['minutes'] as int?) ?? 15;
        final snoozeCount = (args['snoozeCount'] as int?) ?? 0;
        final pending = _storage.getPendingTasksToday();
        return _intervention.generateMessage(
          appName: appName,
          minutesScrolled: minutes,
          pendingTasks: pending,
          completedCount: _storage.getCompletedCountToday(),
          totalScrollToday: _storage.getTotalScrollMinutesToday(),
          hourOfDay: DateTime.now().hour,
          streak: _storage.streak,
          snoozeCount: snoozeCount,
        );

      case 'classifyMood':
        final text = (call.arguments as Map?)?['text'] as String? ?? '';
        final result = await _moodGate.classify(text);
        return result.toMap();

      default:
        throw MissingPluginException('No handler for ${call.method}');
    }
  }

  /// Called from Flutter (e.g. settings, debug) to trigger overlay for testing.
  Future<void> showOverlay({String appName = 'Instagram', int minutes = 15}) async {
    try {
      await _channel.invokeMethod('showOverlay', {
        'appName': appName,
        'minutes': minutes,
      });
    } catch (_) {
      // Native side may not be wired in dev; ignore.
    }
  }
}
