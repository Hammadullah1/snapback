import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../state/tasks_provider.dart';
import '../voice_input/voice_input_screen.dart';
import 'widgets/category_filter.dart';
import 'widgets/empty_state.dart';
import 'widgets/task_card.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksProvider>();
    final today = tasks.today;
    final filtered = _category == 'All'
        ? today
        : today.where((t) => t.category == _category).toList();
    final active = filtered.where((t) => !t.completed).toList();
    final done = filtered.where((t) => t.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's plan"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VoiceInputScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: CategoryFilter(
                selected: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
            ),
            Expanded(
              child: today.isEmpty
                  ? PlannerEmptyState(
                      onPlan: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const VoiceInputScreen()),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 80),
                      children: [
                        if (active.isNotEmpty) ...[
                          Text(
                              'Active (${active.length})',
                              style:
                                  Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: AppSpacing.sm),
                          ..._taskCards(active),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        if (done.isNotEmpty) ...[
                          Text(
                              'Completed (${done.length})',
                              style:
                                  Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: AppSpacing.sm),
                          ..._taskCards(done),
                        ],
                        if (active.isEmpty && done.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 48),
                            child: Center(
                                child: Text('Nothing in this category.')),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Iterable<Widget> _taskCards(List<TaskModel> list) {
    final tp = context.read<TasksProvider>();
    return list.map(
      (t) => TaskCard(
        key: ValueKey(t.id),
        task: t,
        onToggle: () => tp.toggleComplete(t.id),
        onDelete: () => tp.remove(t.id),
        onMoveTomorrow: t.completed ? null : () => tp.moveToTomorrow(t.id),
      ),
    );
  }
}
