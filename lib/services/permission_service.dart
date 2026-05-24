import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class PermissionStatusSnapshot {
  final bool microphone;
  final bool notifications;
  final bool accessibility;
  final bool overlay;

  const PermissionStatusSnapshot({
    required this.microphone,
    required this.notifications,
    required this.accessibility,
    required this.overlay,
  });

  bool get allGranted =>
      microphone && notifications && accessibility && overlay;
}

class PermissionService {
  static const _channel = MethodChannel('com.snapback.app/permissions');

  Future<bool> requestMicrophone() async {
    final s = await Permission.microphone.request();
    return s.isGranted;
  }

  Future<bool> requestNotifications() async {
    final s = await Permission.notification.request();
    return s.isGranted;
  }

  Future<bool> isMicGranted() async => Permission.microphone.isGranted;
  Future<bool> isNotificationGranted() async =>
      Permission.notification.isGranted;

  Future<bool> isAccessibilityEnabled() async {
    try {
      final v = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return v ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isOverlayGranted() async {
    try {
      final v = await _channel.invokeMethod<bool>('isOverlayGranted');
      return v ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {
      await AppSettings.openAppSettings(type: AppSettingsType.accessibility);
    }
  }

  Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (_) {
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
    }
  }

  Future<PermissionStatusSnapshot> snapshot() async {
    final mic = await isMicGranted();
    final notif = await isNotificationGranted();
    final access = await isAccessibilityEnabled();
    final overlay = await isOverlayGranted();
    return PermissionStatusSnapshot(
      microphone: mic,
      notifications: notif,
      accessibility: access,
      overlay: overlay,
    );
  }
}
