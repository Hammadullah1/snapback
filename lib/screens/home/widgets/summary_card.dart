import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../../shared/widgets/app_card.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sublabel;
  final IconData icon;
  final Color accent;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.sublabel,
    required this.icon,
    this.accent = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(sublabel!,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
