import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class PlannerEmptyState extends StatelessWidget {
  final VoidCallback onPlan;
  const PlannerEmptyState({super.key, required this.onPlan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surfaceRaised,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.checklist,
                  size: 36, color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Nothing for today yet',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Use voice or quick chips to plan in a minute.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: onPlan,
              icon: const Icon(Icons.add),
              label: const Text('Add a task'),
            ),
          ],
        ),
      ),
    );
  }
}
