import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/session_model.dart';
import 'storage_service.dart';

/// Bridges native SharedPreferences ↔ Dart Hive.
///
/// Forward direction: pushes Dart-side prefs (scroll limit, monitored apps) to
/// the Android SharedPreferences that the AccessibilityService reads.
///
/// Reverse direction: drains any pending sessions the AccessibilityService
/// has queued (CSV in SharedPreferences "pending_sessions"), converts them to
/// SessionModel records, and saves them via StorageService.
class NativeSyncService {
  static const _channel = MethodChannel('com.snapback.app/native_sync');
  static const _uuid = Uuid();

  final StorageService _storage;
  NativeSyncService(this._storage);

  /// Tell native side our scroll limit / monitored apps so the accessibility
  /// service uses the same values.
  Future<void> pushPrefs() async {
    try {
      await _channel.invokeMethod('pushPrefs', {
        'scroll_limit_minutes': _storage.scrollLimit,
        'monitored_apps': _storage.monitoredApps,
      });
    } catch (_) {
      // Native side may not be wired in dev; ignore.
    }
  }

  /// Pull any sessions queued by AccessibilityService and write them to Hive.
  Future<int> drainSessions() async {
    String csv;
    try {
      csv = (await _channel.invokeMethod<String>('drainPendingSessions')) ?? '';
    } catch (_) {
      return 0;
    }
    if (csv.isEmpty) return 0;

    int added = 0;
    for (final line in csv.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 7) continue;
      try {
        final session = SessionModel(
          id: _uuid.v4(),
          packageName: parts[0],
          appDisplayName: parts[1],
          startedAt: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])),
          endedAt: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[3])),
          durationSeconds: int.parse(parts[4]),
          intervened: parts[5] == 'true',
          snoozeCount: int.tryParse(parts[6]) ?? 0,
        );
        await _storage.saveSession(session);
        added++;
      } catch (_) {
        // Skip malformed row.
      }
    }
    return added;
  }
}
