import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../agents/intervention_agent.dart';
import '../../agents/mood_safety_gate.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../services/notification_service.dart';
import '../../services/overlay_bridge_service.dart';
import '../../services/permission_service.dart';
import '../../services/storage_service.dart';
import '../../shared/widgets/app_card.dart';
import '../../state/prefs_provider.dart';
import '../../state/sessions_provider.dart';
import '../../state/tasks_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  PermissionStatusSnapshot? _perms;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPerms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadPerms();
  }

  Future<void> _loadPerms() async {
    final s = await PermissionService().snapshot();
    if (mounted) setState(() => _perms = s);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsProvider>();
    final scrollLimit = prefs.scrollLimit;
    final reflectionHour = prefs.reflectionHour;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            _section('Scroll limit'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$scrollLimit minutes per session',
                      style: Theme.of(context).textTheme.titleSmall),
                  Slider(
                    value: scrollLimit.toDouble().clamp(5, 60),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${scrollLimit}m',
                    onChanged: (v) => prefs.setScrollLimit(v.round()),
                  ),
                  Text(
                    'Overlay appears after this much continuous time in a monitored app.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _section('Monitored apps'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: AppConstants.packageDisplayName.entries.map((e) {
                  final enabled = prefs.monitoredApps.contains(e.key);
                  return SwitchListTile(
                    title: Text(e.value),
                    value: enabled,
                    activeThumbColor: AppColors.accent,
                    onChanged: (v) {
                      final next = [...prefs.monitoredApps];
                      if (v) {
                        if (!next.contains(e.key)) next.add(e.key);
                      } else {
                        next.remove(e.key);
                      }
                      prefs.setMonitoredApps(next);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _section('Reflection time'),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatReflectionHour(reflectionHour),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: reflectionHour, minute: 0),
                      );
                      if (picked != null) {
                        await prefs.setReflectionHour(picked.hour);
                        await NotificationService()
                            .scheduleDailyReflection(hour: picked.hour);
                      }
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _section('Streak'),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: AppColors.accent, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                      '${prefs.streak} day${prefs.streak == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _section('Permissions'),
            _PermissionTile(
              label: 'Microphone',
              granted: _perms?.microphone ?? false,
              onTap: () => PermissionService().requestMicrophone().then((_) => _loadPerms()),
            ),
            _PermissionTile(
              label: 'Notifications',
              granted: _perms?.notifications ?? false,
              onTap: () => PermissionService().requestNotifications().then((_) => _loadPerms()),
            ),
            _PermissionTile(
              label: 'Accessibility (scroll detection)',
              granted: _perms?.accessibility ?? false,
              onTap: () => PermissionService().openAccessibilitySettings(),
            ),
            _PermissionTile(
              label: 'Display over other apps (overlay)',
              granted: _perms?.overlay ?? false,
              onTap: () => PermissionService().openOverlaySettings(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _section('Voice'),
            AppCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use Wi-Fi only for voice'),
                subtitle: const Text('Skip Whisper calls on mobile data'),
                value: prefs.wifiOnlyVoice,
                activeThumbColor: AppColors.accent,
                onChanged: (v) => prefs.setWifiOnlyVoice(v),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _section('Demo data'),
            AppCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show demo content'),
                subtitle:
                    const Text('Seeds 5 tasks + 3 sessions for screenshots/demos.'),
                value: prefs.demoMode,
                activeThumbColor: AppColors.accent,
                onChanged: (v) async {
                  await prefs.setDemoMode(v);
                  if (!context.mounted) return;
                  context.read<TasksProvider>().refresh();
                  context.read<SessionsProvider>().refresh();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _section('About'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SnapBack',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Plan your day. Notice your scroll. Snap back.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Crisis support (Umang): ${AppConstants.umangHelpline}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _section('Debug'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Fire test reflection notification'),
                    onPressed: () => NotificationService().showDebugNow(),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.layers_outlined),
                    label: const Text('Trigger demo intervention'),
                    onPressed: () async {
                      final bridge = OverlayBridgeService(
                        intervention: InterventionAgent(),
                        moodGate: MoodSafetyGate(),
                        storage: StorageService(),
                      );
                      await bridge.showOverlay(appName: 'Instagram', minutes: 15);
                      if (!context.mounted) return;
                      await _showDemoIntervention();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReflectionHour(int hour) {
    final hh = hour.toString().padLeft(2, '0');
    return 'Evening nudge at $hh:00';
  }

  Future<void> _showDemoIntervention() async {
    final storage = StorageService();
    final message = await InterventionAgent().generateMessage(
      appName: 'Instagram',
      minutesScrolled: 15,
      pendingTasks: storage.getPendingTasksToday(),
      completedCount: storage.getCompletedCountToday(),
      totalScrollToday: storage.getTotalScrollMinutesToday(),
      hourOfDay: DateTime.now().hour,
      streak: storage.streak,
      snoozeCount: 0,
    );

    if (!mounted) return;
    final controller = TextEditingController();
    var unlocked = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('SnapBack'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: controller,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type what you will do next',
                    ),
                    onChanged: (value) {
                      setDialogState(() => unlocked = value.trim().length >= 5);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: unlocked
                      ? () => Navigator.of(dialogContext).pop()
                      : null,
                  child: const Text('5 more minutes'),
                ),
                ElevatedButton(
                  onPressed: unlocked
                      ? () => Navigator.of(dialogContext).pop()
                      : null,
                  child: const Text("I'm done scrolling"),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
        child: Text(title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                )),
      );
}

class _PermissionTile extends StatelessWidget {
  final String label;
  final bool granted;
  final VoidCallback onTap;
  const _PermissionTile({
    required this.label,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(
              granted ? Icons.check_circle : Icons.error_outline,
              color: granted ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
