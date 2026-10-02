import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/streak_calculator.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../domain/habit.dart';
import '../providers/habits_provider.dart';
import '../widgets/color_palette.dart';
import '../widgets/habit_avatar.dart';
import '../widgets/month_calendar.dart';
import '../widgets/year_heatmap.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  DateTime _selectedDate = DateOnly.today();

  Future<void> _editNote(String? existingContent) async {
    final controller = TextEditingController(text: existingContent ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_formatDate(_selectedDate)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'What went well? What got in the way?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(habitRepositoryProvider).setNote(
            habitId: widget.habit.id,
            date: _selectedDate,
            content: result,
          );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = widget.habit;
    final accent = hexToColor(habit.color);
    final completionsAsync = ref.watch(habitCompletionsProvider(habit.id));
    final notesAsync = ref.watch(habitNotesProvider(habit.id));
    final repo = ref.read(habitRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: completionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Something went wrong: $err')),
          data: (rows) {
            final byDate = {
              for (final r in rows) r.date: (value: r.value, isSlip: r.isSlip),
            };
            final entries = [
              for (final r in rows)
                CompletionEntry(
                  date: DateOnly.parse(r.date),
                  value: r.value,
                  isSlip: r.isSlip,
                ),
            ];
            final currentStreak = StreakCalculator.currentStreak(
              type: habit.type,
              targetPerDay: habit.targetPerDay,
              entries: entries,
            );

            final notesByDate = notesAsync.valueOrNull ?? const {};
            final selectedNote = notesByDate[DateOnly.format(_selectedDate)]?.content;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // Custom header — back, avatar, name/description, edit.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    HabitAvatar(icon: habit.icon, colorHex: habit.color, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(habit.name, style: theme.textTheme.headlineSmall),
                            if (habit.description?.isNotEmpty == true)
                              Text(
                                habit.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit habit',
                      onPressed: () {
                        // TODO: wire to AddEditHabitScreen in edit mode.
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Heatmap card.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: YearHeatmap(
                    type: habit.type,
                    targetPerDay: habit.targetPerDay,
                    colorHex: habit.color,
                    completionsByDate: byDate,
                  ),
                ),
                const SizedBox(height: 14),

                // Stat pills + category badges.
                Consumer(
                  builder: (context, ref, _) {
                    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
                    final habitCategories =
                        categories.where((c) => habit.categoryIds.contains(c.id));

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatPill(
                          icon: Icons.local_fire_department,
                          label: '$currentStreak',
                          color: accent,
                        ),
                        _StatPill(
                          icon: Icons.track_changes,
                          label: habit.streakGoal != null
                              ? '${habit.streakGoal}-day goal'
                              : 'No Streak Goal',
                          color: accent,
                        ),
                        for (final category in habitCategories)
                          _StatPill(
                            icon: Icons.label_outline,
                            label: category.name,
                            color: hexToColor(category.color),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Full month calendar.
                MonthCalendar(
                  type: habit.type,
                  targetPerDay: habit.targetPerDay,
                  colorHex: habit.color,
                  completionsByDate: byDate,
                  datesWithNotes: notesByDate.keys.toSet(),
                  onDayTap: (date) {
                    repo.toggleToday(habit: habit, date: date);
                  },
                  onDayLongPress: (date) {
                    setState(() => _selectedDate = date);
                    _editNote(notesByDate[DateOnly.format(date)]?.content);
                  },
                ),
                const SizedBox(height: 20),

                // Notes for the selected day.
                GestureDetector(
                  onTap: () => _editNote(selectedNote),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_note, color: accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedNote?.isNotEmpty == true
                                    ? _formatDate(_selectedDate)
                                    : 'No notes yet',
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                selectedNote?.isNotEmpty == true
                                    ? selectedNote!
                                    : 'What went well? What got in the way?',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                          child: const Icon(Icons.add, size: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}