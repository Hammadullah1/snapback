import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onMoveTomorrow;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    this.onMoveTomorrow,
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
    return Dismissible(
      key: ValueKey('task_${task.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.check, color: AppColors.success),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggle();
          return false; // keep in list — just toggle
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.completed ? AppColors.success : Colors.transparent,
                  border: Border.all(
                    color: task.completed
                        ? AppColors.success
                        : AppColors.divider,
                    width: 1.5,
                  ),
                ),
                child: task.completed
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 4,
              height: 28,
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
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.completed
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(task.category,
                          style: Theme.of(context).textTheme.bodySmall),
                      if (task.deadlineText != null) ...[
                        const Text(' · '),
                        Text(task.deadlineText!,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (onMoveTomorrow != null)
              IconButton(
                icon: const Icon(Icons.update, size: 18),
                tooltip: 'Move to tomorrow',
                onPressed: onMoveTomorrow,
              ),
          ],
        ),
      ),
    );
  }
}
