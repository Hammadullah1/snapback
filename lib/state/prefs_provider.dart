import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../services/storage_service.dart';

class PrefsProvider extends ChangeNotifier {
  final StorageService _storage;
  PrefsProvider(this._storage);

  int get scrollLimit => _storage.scrollLimit;
  int get reflectionHour => _storage.reflectionHour;
  int get streak => _storage.streak;
  bool get onboardingComplete => _storage.onboardingComplete;
  List<String> get monitoredApps => _storage.monitoredApps;

  bool get demoMode =>
      _storage.getPref<bool>(AppConstants.prefDemoMode, false);

  bool get wifiOnlyVoice =>
      _storage.getPref<bool>(AppConstants.prefWifiOnlyVoice, false);

  Future<void> setScrollLimit(int minutes) async {
    await _storage.setPref(AppConstants.prefScrollLimit, minutes);
    notifyListeners();
  }

  Future<void> setReflectionHour(int hour) async {
    await _storage.setPref(AppConstants.prefReflectionHour, hour);
    notifyListeners();
  }

  Future<void> setOnboardingComplete(bool v) async {
    await _storage.setPref(AppConstants.prefOnboardingComplete, v);
    notifyListeners();
  }

  Future<void> setMonitoredApps(List<String> packages) async {
    await _storage.setMonitoredApps(packages);
    notifyListeners();
  }

  Future<void> setWifiOnlyVoice(bool v) async {
    await _storage.setPref(AppConstants.prefWifiOnlyVoice, v);
    notifyListeners();
  }

  Future<void> setDemoMode(bool v) async {
    if (v) {
      await _storage.seedDemoData();
    } else {
      await _storage.clearDemoData();
    }
    notifyListeners();
  }

  void refresh() => notifyListeners();
}
