import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class CategoryFilter extends StatelessWidget {
  final String selected; // 'All' | category name
  final ValueChanged<String> onChanged;
  const CategoryFilter({super.key, required this.selected, required this.onChanged});

  static const _all = ['All', 'Study', 'Health', 'Family', 'Personal', 'Work', 'Other'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _all.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final c = _all[i];
          final sel = c == selected;
          return ChoiceChip(
            label: Text(c),
            selected: sel,
            onSelected: (_) => onChanged(c),
          );
        },
      ),
    );
  }
}
