// Preferences are stored in a single dynamic Hive box keyed by string.
// No HiveType needed — values are primitives (int, bool, String, List<String>, DateTime).
// This file is kept as a thin documentation marker plus default constants live in
// `lib/config/constants.dart`.

class PrefsDefaults {
  static const Map<String, dynamic> defaults = {
    'onboarding_complete': false,
    'scroll_limit_minutes': 15,
    'reflection_hour': 21,
    'monitored_apps': <String>[
      'com.instagram.android',
      'com.zhiliaoapp.musically',
      'com.google.android.youtube',
      'com.snapchat.android',
    ],
    'wifi_only_voice': false,
    'demo_mode': false,
    'streak': 0,
  };
}
