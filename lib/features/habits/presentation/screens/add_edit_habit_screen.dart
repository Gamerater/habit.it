import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../icon_picker/presentation/icon_picker_screen.dart';
import '../../domain/habit_type.dart';
import '../providers/habits_provider.dart';
import '../widgets/color_palette.dart';
import '../widgets/habit_avatar.dart';

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
  String _color = habitColorPalette.first;
  String _icon = 'ic_fitness_center';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const IconPickerScreen()),
    );
    if (result != null) setState(() => _icon = result);
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

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Habit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickIcon,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  HabitAvatar(icon: _icon, colorHex: _color, size: 96),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 14,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const _FieldLabel('Name'),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'e.g. Morning run'),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Description'),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(hintText: 'Optional'),
          ),
          const SizedBox(height: 24),
          const _FieldLabel('Color'),
          ColorPaletteGrid(
            selectedHex: _color,
            onSelected: (hex) => setState(() => _color = hex),
          ),
          const SizedBox(height: 24),
          const _FieldLabel('Habit Type'),
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}