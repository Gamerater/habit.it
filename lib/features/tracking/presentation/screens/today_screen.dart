import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/streak_calculator.dart';
import '../../../habits/domain/habit.dart';
import '../../../habits/presentation/providers/habits_provider.dart';
import '../../../habits/presentation/widgets/color_palette.dart';
import '../../../habits/presentation/widgets/habit_avatar.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(activeHabitsProvider);
    final todayCompletions = ref.watch(todayCompletionsProvider);
    final repo = ref.read(habitRepositoryProvider);
    final today = DateOnly.today();

    return Scaffold(
      appBar: AppBar(title: Text(_formatFullDate(today))),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Something went wrong: $err')),
        data: (habits) {
          if (habits.isEmpty) return const _EmptyState();

          final completions = todayCompletions.valueOrNull ?? const {};

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: habits.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final habit = habits[index];
              final entry = completions[habit.id];
              final isDone = habit.type.isBuild
                  ? (entry != null && entry.value >= habit.targetPerDay)
                  : !(entry?.isSlip ?? false);

              return _HabitTodayRow(
                habit: habit,
                isDone: isDone,
                onToggle: () => repo.toggleToday(habit: habit, date: today),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/habits/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

/// A hairline-divided row with a colored accent stripe on the left,
/// deliberately not a rounded "card" — avoids the identical-cards-stacked
/// look and reads more like a considered list than a widget catalog.
class _HabitTodayRow extends ConsumerWidget {
  final Habit habit;
  final bool isDone;
  final VoidCallback onToggle;

  const _HabitTodayRow({
    required this.habit,
    required this.isDone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = hexToColor(habit.color);

    final completionsAsync = ref.watch(habitCompletionsProvider(habit.id));
    final streak = completionsAsync.maybeWhen(
      data: (rows) => StreakCalculator.currentStreak(
        type: habit.type,
        targetPerDay: habit.targetPerDay,
        entries: [
          for (final r in rows)
            CompletionEntry(
              date: DateOnly.parse(r.date),
              value: r.value,
              isSlip: r.isSlip,
            ),
        ],
      ),
      orElse: () => 0,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          HabitAvatar(icon: habit.icon, colorHex: habit.color, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    habit.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (streak > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$streak day${streak == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? accent : Colors.transparent,
                  border: Border.all(
                    color: isDone ? accent : theme.colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.self_improvement,
              size: 44,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 18),
            Text('No habits yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Tap + to build or quit your first one.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}