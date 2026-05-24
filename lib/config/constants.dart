class AppConstants {
  static const String appName = 'SnapBack';

  // OpenAI
  static const String chatModel = 'gpt-4o-mini';
  static const String whisperModel = 'whisper-1';

  // Monitored package names
  static const Set<String> monitoredPackages = {
    'com.instagram.android',
    'com.zhiliaoapp.musically', // TikTok
    'com.google.android.youtube',
    'com.snapchat.android',
  };

  static const Map<String, String> packageDisplayName = {
    'com.instagram.android': 'Instagram',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.google.android.youtube': 'YouTube',
    'com.snapchat.android': 'Snapchat',
  };

  // Hive box names
  static const String tasksBox = 'tasks';
  static const String sessionsBox = 'sessions';
  static const String prefsBox = 'prefs';

  // Defaults
  static const int defaultScrollLimitMinutes = 15;
  static const int defaultReflectionHour = 21; // 9pm
  static const int overlayUnlockChars = 5;
  static const int sessionMergeWindowSeconds = 60;
  static const int maxSnoozes = 2;

  // Crisis support
  static const String umangHelpline = '0317-4288665';

  // Prefs keys
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefScrollLimit = 'scroll_limit_minutes';
  static const String prefReflectionHour = 'reflection_hour';
  static const String prefMonitoredApps = 'monitored_apps';
  static const String prefWifiOnlyVoice = 'wifi_only_voice';
  static const String prefDemoMode = 'demo_mode';
  static const String prefStreak = 'streak';
  static const String prefStreakLastUpdated = 'streak_last_updated';

  // Fallback intervention messages — used if OpenAI fails
  static const List<String> fallbackInterventions = [
    "You've been scrolling for a while. You have things you wanted to do today. Take a breath and check your planner.",
    "This isn't the moment you imagined for yourself. There's a small task waiting that you can finish in 10 minutes.",
    "Your phone will still be here later. Right now, your future self would thank you for closing this app.",
    "Scrolling is easy. So is the next small thing on your list. Pick the one that helps tomorrow-you.",
    "You came here for a quick break. It stopped being quick a while ago. Step away — you've got this.",
  ];
}
