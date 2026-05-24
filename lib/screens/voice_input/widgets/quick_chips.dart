import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class QuickChips extends StatelessWidget {
  final ValueChanged<String> onTap;
  const QuickChips({super.key, required this.onTap});

  static const List<({String label, String category, String priority})> chips = [
    (label: 'Pray',     category: 'Personal', priority: 'high'),
    (label: 'Study',    category: 'Study',    priority: 'high'),
    (label: 'Gym',      category: 'Health',   priority: 'medium'),
    (label: 'Homework', category: 'Study',    priority: 'high'),
    (label: 'Family',   category: 'Family',   priority: 'medium'),
    (label: 'Read',     category: 'Personal', priority: 'low'),
    (label: 'Sleep early', category: 'Health', priority: 'medium'),
    (label: 'Quiz prep', category: 'Study',   priority: 'high'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: chips.map((c) {
        return ActionChip(
          label: Text(c.label),
          onPressed: () => onTap(c.label),
        );
      }).toList(),
    );
  }
}
