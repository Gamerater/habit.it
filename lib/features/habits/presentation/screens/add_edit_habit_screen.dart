import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/screens/category_picker_screen.dart';
import '../../../icon_picker/presentation/icon_picker_screen.dart';
import '../../domain/amount_format.dart';
import '../../domain/habit.dart';
import '../../domain/habit_type.dart';
import '../providers/habits_provider.dart';
import '../widgets/color_palette.dart';
import '../widgets/habit_avatar.dart';
import '../widgets/tracking_settings_section.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  /// When non-null, the screen opens in edit mode, prefilled from this habit,
  /// and Save updates it in place instead of creating a new one.
  final Habit? existingHabit;

  const AddEditHabitScreen({super.key, this.existingHabit});

  bool get isEditing => existingHabit != null;

  @override
  ConsumerState<AddEditHabitScreen> createState() =>
      _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  late final _nameController =
      TextEditingController(text: widget.existingHabit?.name ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.existingHabit?.description ?? '');
  late HabitType _type = widget.existingHabit?.type ?? HabitType.build;
  late String _color = widget.existingHabit?.color ?? habitColorPalette.first;
  late String _icon = widget.existingHabit?.icon ?? 'ic_fitness_center';
  late List<String> _categoryIds = widget.existingHabit?.categoryIds ?? [];

  // Tracking settings. The goal and per-tap amount fields hold what the user
  // sees (e.g. "2.5"); they're converted to stored units only on save.
  late TrackingMethod _method = widget.existingHabit?.trackingMethod ?? TrackingMethod.yesNo;
  late TrackingMode _tapMode = widget.existingHabit?.trackingMode ?? TrackingMode.stepByStep;
  late final _goalController = TextEditingController(
    text: (widget.existingHabit?.tracksAmount ?? false)
        ? widget.existingHabit!.formatAmount(widget.existingHabit!.targetPerDay)
        : '',
  );
  late final _unitController = TextEditingController(text: widget.existingHabit?.unit ?? '');
  late final _incrementController = TextEditingController(
    text: (widget.existingHabit?.tracksAmount ?? false)
        ? widget.existingHabit!.formatAmount(widget.existingHabit!.tapIncrement)
        : '1',
  );
  late final _streakGoalController = TextEditingController(
    text: widget.existingHabit?.streakGoal?.toString() ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    _unitController.dispose();
    _incrementController.dispose();
    _streakGoalController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const IconPickerScreen()),
    );
    if (result != null) setState(() => _icon = result);
  }

  Future<void> _pickCategories() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => CategoryPickerScreen(initiallySelected: _categoryIds),
      ),
    );
    if (result != null) setState(() => _categoryIds = result);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Switching between Count and Measure changes whether decimals are
  /// allowed, so numbers typed under one method are tidied for the other
  /// rather than left to fail validation later.
  void _onMethodChanged(TrackingMethod next) {
    setState(() {
      if (next == TrackingMethod.count) {
        for (final controller in [_goalController, _incrementController]) {
          controller.text = controller.text.split(RegExp(r'[.,]')).first;
        }
      }
      if (next != TrackingMethod.yesNo) {
        final increment = int.tryParse(_incrementController.text.trim()) ?? 0;
        if (_incrementController.text.trim().isEmpty || (next == TrackingMethod.count && increment <= 0)) {
          _incrementController.text = '1';
        }
      }
      _method = next;
    });
  }

  String _conversionNote(TrackingMethod from, TrackingMethod to) {
    if (from == TrackingMethod.yesNo) {
      return 'Days you already marked done will count as reaching the new goal.';
    }
    if (to == TrackingMethod.yesNo) {
      return 'Days where you reached the goal stay marked done. Days with only partial '
          'progress will be cleared, since Yes / No has no partial progress.';
    }
    if (from == TrackingMethod.count) {
      return 'Your logged counts carry over as amounts in the new unit.';
    }
    return 'Your logged amounts will be rounded to whole numbers, and days that round '
        'to zero will be cleared.';
  }

  /// Changing how an existing habit is tracked rewrites its logged history
  /// (see HabitRepository.updateHabit), so confirm before doing it.
  Future<bool> _confirmMethodChange(TrackingMethod from, TrackingMethod to) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change tracking method?'),
        content: Text(
          'This habit will switch from ${from.label} to ${to.label}.\n\n'
          '${_conversionNote(from, to)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Change'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Give your habit a name.');
      return;
    }

    // Only build habits can track amounts; quit habits are always yes/no
    // (you mark the days you slip).
    final method = _type.isBuild ? _method : TrackingMethod.yesNo;
    final scale = method == TrackingMethod.measure ? measureScale : 1;

    var targetPerDay = 1;
    var tapIncrement = scale;
    var tapMode = TrackingMode.stepByStep;
    String? unit;

    if (method != TrackingMethod.yesNo) {
      final goal = parseScaledAmount(_goalController.text, scale);
      if (goal == null || goal <= 0) {
        _showError('Enter a daily goal greater than 0.');
        return;
      }
      targetPerDay = goal;

      final unitText = _unitController.text.trim();
      if (method == TrackingMethod.measure && unitText.isEmpty) {
        _showError('Enter a unit, like L or km.');
        return;
      }
      unit = unitText.isEmpty ? null : unitText;

      tapMode = _tapMode;
      if (tapMode == TrackingMode.stepByStep) {
        final increment = parseScaledAmount(_incrementController.text, scale);
        if (increment == null || increment <= 0) {
          _showError('Enter an amount per tap greater than 0.');
          return;
        }
        tapIncrement = increment;
      }
    }

    int? streakGoal;
    final streakText = _streakGoalController.text.trim();
    if (streakText.isNotEmpty) {
      streakGoal = int.tryParse(streakText);
      if (streakGoal == null || streakGoal <= 0) {
        _showError('Streak goal must be a whole number of days.');
        return;
      }
    }

    final repo = ref.read(habitRepositoryProvider);
    final name = _nameController.text.trim();
    final description =
        _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();

    if (widget.isEditing) {
      final existing = widget.existingHabit!;
      if (existing.type.isBuild && _type.isBuild && existing.trackingMethod != method) {
        final ok = await _confirmMethodChange(existing.trackingMethod, method);
        if (!ok) return;
      }

      await repo.updateHabit(
        id: existing.id,
        name: name,
        description: description,
        icon: _icon,
        color: _color,
        type: _type,
        trackingMethod: method,
        trackingMode: tapMode,
        targetPerDay: targetPerDay,
        tapIncrement: tapIncrement,
        unit: unit,
        streakGoal: streakGoal,
        categoryIds: _categoryIds,
      );
    } else {
      await repo.createHabit(
        name: name,
        description: description,
        icon: _icon,
        color: _color,
        type: _type,
        trackingMethod: method,
        trackingMode: tapMode,
        targetPerDay: targetPerDay,
        tapIncrement: tapIncrement,
        unit: unit,
        streakGoal: streakGoal,
        categoryIds: _categoryIds,
      );
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Habit' : 'New Habit'),
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
          _FieldLabel('Name'),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'e.g. Morning run'),
          ),
          const SizedBox(height: 20),
          _FieldLabel('Description'),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(hintText: 'Optional'),
          ),
          const SizedBox(height: 24),
          _FieldLabel('Color'),
          ColorPaletteGrid(
            selectedHex: _color,
            onSelected: (hex) => setState(() => _color = hex),
          ),
          const SizedBox(height: 24),
          _FieldLabel('Categories'),
          Consumer(
            builder: (context, ref, _) {
              final categoriesAsync = ref.watch(categoriesProvider);
              final allCategories = categoriesAsync.valueOrNull ?? [];
              final selected = allCategories
                  .where((c) => _categoryIds.contains(c.id))
                  .toList();

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickCategories,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: selected.isEmpty
                            ? Text(
                                'None',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final category in selected)
                                    Chip(
                                      label: Text(category.name),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                      ),
                      Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _FieldLabel('Habit Type'),
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
          if (_type.isBuild) ...[
            const SizedBox(height: 28),
            TrackingSettingsSection(
              method: _method,
              tapMode: _tapMode,
              goalController: _goalController,
              unitController: _unitController,
              incrementController: _incrementController,
              onMethodChanged: _onMethodChanged,
              onTapModeChanged: (mode) => setState(() => _tapMode = mode),
            ),
          ],
          const SizedBox(height: 28),
          _FieldLabel('Streak goal'),
          TextField(
            controller: _streakGoalController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: 'Optional', suffixText: 'days'),
          ),
          const SizedBox(height: 8),
          Text(
            'A target to work toward, shown on the habit\'s page.',
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