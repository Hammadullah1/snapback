import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';

class StreakBar extends StatelessWidget {
  final int streak;
  const StreakBar({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final flame = streak > 0;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: flame ? AppColors.accentSoft : AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(
            flame ? Icons.local_fire_department : Icons.bedtime_outlined,
            color: flame ? AppColors.accent : AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$streak',
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            streak == 1 ? 'day streak' : 'day streak',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            flame ? 'Keep going' : 'Start today',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}
