import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../services/permission_service.dart';
import '../../state/prefs_provider.dart';
import '../../state/sessions_provider.dart';
import '../../state/tasks_provider.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/outlined_button.dart';
import '../planner/planner_screen.dart';
import '../reflection/reflection_screen.dart';
import '../settings/settings_screen.dart';
import '../voice_input/voice_input_screen.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/streak_bar.dart';
import 'widgets/summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = 0;
  bool _permissionWarning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      context.read<TasksProvider>().refresh();
      context.read<SessionsProvider>().refresh();
    }
  }

  Future<void> _checkPermissions() async {
    final snap = await PermissionService().snapshot();
    if (!mounted) return;
    setState(() => _permissionWarning = !snap.allGranted);
  }

  void _goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(onSeePlanner: () => _goToTab(1)),
      const PlannerScreen(),
      const ReflectionScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: _goToTab,
        showSettingsWarning: _permissionWarning,
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final VoidCallback onSeePlanner;
  const _HomeTab({required this.onSeePlanner});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksProvider>();
    final sessions = context.watch<SessionsProvider>();
    final prefs = context.watch<PrefsProvider>();

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM').format(now);
    final greeting = _greeting(now.hour);

    final planned = tasks.plannedTodayCount;
    final completed = tasks.completedTodayCount;
    final scrollMin = sessions.totalScrollMinutesToday;
    final scrollLimit = prefs.scrollLimit;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    )),
            const SizedBox(height: 4),
            Text(greeting,
                style: GoogleFonts.fraunces(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: AppSpacing.lg),
            StreakBar(streak: prefs.streak),
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.25,
              children: [
                SummaryCard(
                  label: 'Tasks planned',
                  value: '$planned',
                  icon: Icons.flag_outlined,
                ),
                SummaryCard(
                  label: 'Completed',
                  value: '$completed',
                  sublabel: planned == 0
                      ? 'Start by planning'
                      : '${(completed / planned * 100).round()}%',
                  icon: Icons.check_circle_outline,
                  accent: AppColors.success,
                ),
                SummaryCard(
                  label: 'Scroll time',
                  value: '${scrollMin}m',
                  sublabel: 'limit ${scrollLimit}m',
                  icon: Icons.phone_iphone,
                  accent: scrollMin > scrollLimit
                      ? AppColors.danger
                      : AppColors.warning,
                ),
                SummaryCard(
                  label: 'Pending',
                  value: '${planned - completed}',
                  icon: Icons.pending_outlined,
                  accent: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Plan with voice',
              icon: Icons.mic,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const VoiceInputScreen())),
            ),
            const SizedBox(height: AppSpacing.md),
            AppOutlinedButton(
              label: 'See planner',
              icon: Icons.checklist,
              onPressed: onSeePlanner,
            ),
            if (planned == 0) ...[
              const SizedBox(height: AppSpacing.xl),
              _EmptyHomeHint(),
            ],
          ],
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 5) return 'Late night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Winding down';
  }
}

class _EmptyHomeHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_outlined,
              color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No tasks yet. Tap "Plan with voice" and tell SnapBack about your day.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
