import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'agents/intervention_agent.dart';
import 'agents/mood_safety_gate.dart';
import 'config/theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/reflection/reflection_screen.dart';
import 'services/native_sync_service.dart';
import 'services/notification_service.dart';
import 'services/overlay_bridge_service.dart';
import 'services/storage_service.dart';
import 'state/prefs_provider.dart';
import 'state/sessions_provider.dart';
import 'state/tasks_provider.dart';

final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final storage = StorageService();
  await storage.init();

  final notifications = NotificationService();
  await notifications.init();
  notifications.onTap = (payload) {
    if (payload == 'reflect') {
      rootNavKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ReflectionScreen()),
      );
    }
  };
  await notifications.scheduleDailyReflection(hour: storage.reflectionHour);

  final intervention = InterventionAgent();
  final moodGate = MoodSafetyGate();
  final bridge = OverlayBridgeService(
    intervention: intervention,
    moodGate: moodGate,
    storage: storage,
  );
  bridge.start();

  final sync = NativeSyncService(storage);
  await sync.pushPrefs();
  await sync.drainSessions();

  runApp(SnapBackApp(storage: storage, sync: sync));
}

class SnapBackApp extends StatefulWidget {
  final StorageService storage;
  final NativeSyncService sync;
  const SnapBackApp({super.key, required this.storage, required this.sync});

  @override
  State<SnapBackApp> createState() => _SnapBackAppState();
}

class _SnapBackAppState extends State<SnapBackApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.sync.drainSessions();
    } else if (state == AppLifecycleState.paused) {
      widget.sync.pushPrefs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TasksProvider(widget.storage)),
        ChangeNotifierProvider(create: (_) => SessionsProvider(widget.storage)),
        ChangeNotifierProvider(create: (_) => PrefsProvider(widget.storage)),
      ],
      child: MaterialApp(
        navigatorKey: rootNavKey,
        title: 'SnapBack',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: widget.storage.onboardingComplete
            ? const HomeScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}
