import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/habit_type.dart';
import '../providers/habits_provider.dart';

/// Functional MVP form. Icon/emoji picker, streak goal, reminders, and
/// categories are stubbed as TODOs — build those out as separate features
/// (see PROJECT_PLAN.md section 5).
class AddEditHabitScreen extends ConsumerStatefulWidget {
  const AddEditHabitScreen({super.key});

  @override
  ConsumerState<AddEditHabitScreen> createState() =>
      _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  HabitType _type = HabitType.build;
  final String _color = '#16A394';
  final String _icon = '💪';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;

    await ref.read(habitRepositoryProvider).createHabit(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          icon: _icon,
          color: _color,
          type: _type,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Habit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 20),
          SegmentedButton<HabitType>(
            segments: const [
              ButtonSegment(
                value: HabitType.build,
                label: Text('Build a Habit'),
              ),
              ButtonSegment(
                value: HabitType.quit,
                label: Text('Quit a Habit'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 8),
          Text(
            _type.isBuild
                ? 'Mark each day you complete it.'
                : 'Completed by default — only mark the days you slipped.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
