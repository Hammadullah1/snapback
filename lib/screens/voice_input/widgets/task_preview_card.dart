import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/task_model.dart';
import '../../../shared/widgets/app_card.dart';

class TaskPreviewCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onRemove;
  final VoidCallback? onEdit;

  const TaskPreviewCard({
    super.key,
    required this.task,
    this.onRemove,
    this.onEdit,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case 'high':
        return AppColors.danger;
      case 'low':
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: _priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _TinyBadge(text: task.category),
                    if (task.deadlineText != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _TinyBadge(
                          text: task.deadlineText!,
                          color: AppColors.warning),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
            ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _TinyBadge({required this.text, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}
