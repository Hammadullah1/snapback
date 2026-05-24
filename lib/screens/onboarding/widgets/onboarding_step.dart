import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class OnboardingStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget action;
  final Widget? status;

  const OnboardingStep({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 32),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: AppSpacing.md),
          Text(body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  )),
          const Spacer(),
          if (status != null) ...[status!, const SizedBox(height: AppSpacing.md)],
          action,
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
