import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../services/permission_service.dart';
import '../../shared/widgets/outlined_button.dart';
import '../../shared/widgets/primary_button.dart';
import '../../state/prefs_provider.dart';
import '../home/home_screen.dart';
import 'widgets/onboarding_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final _controller = PageController();
  int _page = 0;
  PermissionStatusSnapshot? _perms;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final p = await PermissionService().snapshot();
    if (mounted) setState(() => _perms = p);
  }

  void _next() {
    if (_page < 4) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await context.read<PrefsProvider>().setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perms = _perms;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Dots(count: 5, current: _page),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  OnboardingStep(
                    icon: Icons.waving_hand_outlined,
                    title: 'Meet SnapBack',
                    body:
                        'Plan your day with your voice. When you scroll past your limit, we step in gently — with a message that knows what you set out to do today.',
                    action: PrimaryButton(label: 'Get started', onPressed: _next),
                  ),
                  OnboardingStep(
                    icon: Icons.mic_none,
                    title: 'Microphone',
                    body:
                        'Tell SnapBack what you want to do today. We turn it into a clean planner. Audio never leaves your device except as a one-shot to Whisper.',
                    action: PrimaryButton(
                      label: perms?.microphone == true ? 'Granted — continue' : 'Allow mic',
                      onPressed: () async {
                        final granted =
                            await PermissionService().requestMicrophone();
                        await _refresh();
                        if (granted) _next();
                      },
                    ),
                    status: _statusRow('Microphone', perms?.microphone ?? false),
                  ),
                  OnboardingStep(
                    icon: Icons.notifications_none,
                    title: 'Reflection reminders',
                    body:
                        'SnapBack sends one evening reminder so you can reflect on your tasks, scroll time, and streak.',
                    action: PrimaryButton(
                      label: perms?.notifications == true
                          ? 'Granted â€” continue'
                          : 'Allow notifications',
                      onPressed: () async {
                        final granted =
                            await PermissionService().requestNotifications();
                        await _refresh();
                        if (granted) _next();
                      },
                    ),
                    status: _statusRow(
                        'Notifications', perms?.notifications ?? false),
                  ),
                  OnboardingStep(
                    icon: Icons.accessibility_new,
                    title: 'Watch monitored apps',
                    body:
                        'SnapBack uses an Accessibility Service to notice when Instagram, TikTok, YouTube, or Snapchat are open. It does NOT read what you see.',
                    action: Column(
                      children: [
                        PrimaryButton(
                          label: perms?.accessibility == true
                              ? 'Granted — continue'
                              : 'Open accessibility settings',
                          onPressed: () async {
                            await PermissionService().openAccessibilitySettings();
                            await _refresh();
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppOutlinedButton(label: 'Continue', onPressed: _next),
                      ],
                    ),
                    status:
                        _statusRow('Accessibility', perms?.accessibility ?? false),
                  ),
                  OnboardingStep(
                    icon: Icons.layers_outlined,
                    title: 'Show overlay',
                    body:
                        'When time is up, SnapBack draws a soft overlay over the app. You can type back, pick "Done", or snooze. We never lock the phone.',
                    action: Column(
                      children: [
                        PrimaryButton(
                          label: perms?.overlay == true
                              ? "You're set"
                              : 'Allow overlay',
                          onPressed: () async {
                            if (perms?.overlay == true) {
                              _finish();
                            } else {
                              await PermissionService().openOverlaySettings();
                              await _refresh();
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppOutlinedButton(
                            label: 'Finish setup', onPressed: _finish),
                      ],
                    ),
                    status: _statusRow('Overlay', perms?.overlay ?? false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, bool granted) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: granted ? AppColors.success : AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ${granted ? "granted" : "needed"}',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int current;
  const _Dots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 22 : 6,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.divider,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
