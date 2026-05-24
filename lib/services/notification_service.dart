import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

typedef NotificationTapCallback = void Function(String? payload);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  NotificationTapCallback? onTap;

  Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (resp) {
        onTap?.call(resp.payload);
      },
    );
    _ready = true;
  }

  static const _channelId = 'snapback_reflection';
  static const _channelName = 'Daily Reflection';
  static const _channelDesc = 'Evening nudge to reflect on your day.';

  Future<void> scheduleDailyReflection({required int hour, int minute = 0}) async {
    if (!_ready) await init();
    await _plugin.cancel(101);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        101,
        'Time to look back',
        'Two minutes of reflection — see how today went.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'reflect',
      );
    } catch (e) {
      debugPrint('Failed to schedule reflection notification: $e');
    }
  }

  Future<void> showDebugNow() async {
    if (!_ready) await init();
    await _plugin.show(
      999,
      'SnapBack debug',
      'Test notification fired.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
        ),
      ),
      payload: 'reflect',
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
