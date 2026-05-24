import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../shared/widgets/primary_button.dart';

class ManualAddResult {
  final String title;
  final String category;
  final String priority;
  ManualAddResult(this.title, this.category, this.priority);
}

class ManualAddSheet extends StatefulWidget {
  const ManualAddSheet({super.key});

  @override
  State<ManualAddSheet> createState() => _ManualAddSheetState();
}

class _ManualAddSheetState extends State<ManualAddSheet> {
  final _controller = TextEditingController();
  String _category = 'Personal';
  String _priority = 'medium';

  static const _categories = ['Study', 'Health', 'Family', 'Personal', 'Work', 'Other'];
  static const _priorities = ['low', 'medium', 'high'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a task', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'What do you want to do?'),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: _priorities
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() => _priority = v ?? _priority),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Add task',
            onPressed: () {
              final title = _controller.text.trim();
              if (title.isEmpty) return;
              Navigator.of(context)
                  .pop(ManualAddResult(title, _category, _priority));
            },
          ),
        ],
      ),
    );
  }
}
