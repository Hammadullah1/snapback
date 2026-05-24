import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../agents/reflection_agent.dart';
import '../../config/theme.dart';
import '../../services/storage_service.dart';
import '../../shared/widgets/app_card.dart';
import '../../state/prefs_provider.dart';
import '../../state/sessions_provider.dart';
import '../../state/tasks_provider.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  Future<ReflectionResult>? _future;
  Timer? _tick;
  int _newStreak = 0;

  @override
  void initState() {
    super.initState();
    _maybeLoad();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _maybeLoad() async {
    final prefs = context.read<PrefsProvider>();
    if (DateTime.now().hour < prefs.reflectionHour) return;
    if (_future != null) return;

    final storage = StorageService();
    final tasks = storage.getTasksForDate(DateTime.now());
    final sessions = storage.getSessionsForDate(DateTime.now());

    _newStreak = await storage.computeAndUpdateStreak();
    if (mounted) context.read<PrefsProvider>().refresh();

    setState(() {
      _future = ReflectionAgent().generate(
        todayTasks: tasks,
        todaySessions: sessions,
        scrollLimit: storage.scrollLimit,
        streak: _newStreak,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsProvider>();
    final hour = DateTime.now().hour;
    final tooEarly = hour < prefs.reflectionHour;

    return Scaffold(
      appBar: AppBar(title: const Text("Today's reflection")),
      body: SafeArea(
        child: tooEarly ? _beforeHour(prefs.reflectionHour) : _afterHour(),
      ),
    );
  }

  Widget _beforeHour(int hourTarget) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, hourTarget);
    final remaining = target.difference(now);
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nightlight_round,
                size: 56, color: AppColors.warning),
            const SizedBox(height: AppSpacing.lg),
            Text('Reflection opens at ${hourTarget.toString().padLeft(2, '0')}:00',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              h > 0 ? 'in ${h}h ${m}m' : 'in ${m}m',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "Come back tonight — we'll look at how today went, together.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _afterHour() {
    final tasks = context.watch<TasksProvider>();
    final sessions = context.watch<SessionsProvider>();
    final prefs = context.watch<PrefsProvider>();

    if (_future == null) {
      _maybeLoad();
    }

    final planned = tasks.plannedTodayCount;
    final completed = tasks.completedTodayCount;
    final scrollMin = sessions.totalScrollMinutesToday;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tasks',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('$completed / $planned',
                          style: GoogleFonts.fraunces(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                Container(
                    height: 48, width: 1, color: AppColors.divider),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scroll',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('${scrollMin}m',
                            style: GoogleFonts.fraunces(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FutureBuilder<ReflectionResult>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return _shimmer();
              }
              final r = snap.data ??
                  ReflectionResult.fallback(completed, planned, prefs.streak);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(r.moodEmoji,
                          style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(r.streakMessage,
                            style:
                                Theme.of(context).textTheme.bodyLarge),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...r.reflection.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(s,
                          style:
                              Theme.of(context).textTheme.bodyLarge),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    color: AppColors.surfaceRaised,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tomorrow',
                            style:
                                Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(r.tomorrowChallenge,
                            style:
                                Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _shimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceRaised,
      highlightColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
          4,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
