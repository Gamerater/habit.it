import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
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
  final Map<String, GlobalKey> _noteKeys = {};

  GlobalKey _keyForDate(String dateKey) =>
      _noteKeys.putIfAbsent(dateKey, () => GlobalKey());

  void _scrollToNote(String dateKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _noteKeys[dateKey];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.3,
          curve: Curves.easeOut,
        );
      }
    });
  }

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

  List<MapEntry<String, NoteRow>> _sortedNoteEntries(Map<String, NoteRow> notesByDate) {
    final entries = notesByDate.entries.toList();
    entries.sort((a, b) => b.key.compareTo(a.key)); // date strings sort lexically = chronologically
    return entries;
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
              habitCreatedAt: habit.createdAt,
              entries: entries,
            );

            final notesByDate = notesAsync.valueOrNull ?? const {};

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
                    habitCreatedAt: habit.createdAt,
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
                  habitCreatedAt: habit.createdAt,
                  onDayTap: (date) {
                    repo.toggleToday(habit: habit, date: date);
                    final dateKey = DateOnly.format(date);
                    if (notesByDate.containsKey(dateKey)) {
                      setState(() => _selectedDate = date);
                      _scrollToNote(dateKey);
                    }
                  },
                  onDayLongPress: (date) {
                    setState(() => _selectedDate = date);
                    _editNote(notesByDate[DateOnly.format(date)]?.content);
                  },
                ),
                const SizedBox(height: 20),

                // Notes feed — every note for this habit, newest first.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notes', style: theme.textTheme.titleMedium),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: accent),
                      tooltip: 'Add a note for today',
                      onPressed: () {
                        setState(() => _selectedDate = DateOnly.today());
                        _editNote(
                          notesByDate[DateOnly.format(DateOnly.today())]?.content,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (notesByDate.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No notes yet', style: theme.textTheme.titleMedium),
                        Text(
                          'What went well? What got in the way?',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._sortedNoteEntries(notesByDate).map((entry) {
                    final dateKey = entry.key;
                    final note = entry.value;
                    final date = DateOnly.parse(dateKey);
                    final isSelected = DateOnly.isSameDay(date, _selectedDate);

                    return Padding(
                      key: _keyForDate(dateKey),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(dateKey),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                        ),
                        onDismissed: (_) => repo.setNote(
                          habitId: habit.id,
                          date: date,
                          content: '',
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedDate = date);
                            _editNote(note.content);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(18),
                              border: isSelected
                                  ? Border.all(color: accent, width: 1.5)
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(date),
                                  style: theme.textTheme.labelLarge?.copyWith(color: accent),
                                ),
                                const SizedBox(height: 4),
                                Text(note.content, style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
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