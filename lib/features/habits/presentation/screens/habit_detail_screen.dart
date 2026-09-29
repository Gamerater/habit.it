import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/streak_calculator.dart';
import '../../domain/habit.dart';
import '../providers/habits_provider.dart';
import '../widgets/habit_avatar.dart';
import '../widgets/year_heatmap.dart';

class HabitDetailScreen extends ConsumerWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final completionsAsync = ref.watch(habitCompletionsProvider(habit.id));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HabitAvatar(icon: habit.icon, colorHex: habit.color, size: 28),
            const SizedBox(width: 10),
            Text(habit.name),
          ],
        ),
      ),
      body: completionsAsync.when(
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

          final bestStreak = _bestStreak(entries, habit);
          final totalGoodDays = _totalGoodDays(byDate, habit);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  _StatBlock(label: 'Current streak', value: '$currentStreak'),
                  const SizedBox(width: 24),
                  _StatBlock(label: 'Best streak', value: '$bestStreak'),
                  const SizedBox(width: 24),
                  _StatBlock(label: 'Total days', value: '$totalGoodDays'),
                ],
              ),
              const SizedBox(height: 28),
              Text('Past year', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              YearHeatmap(
                type: habit.type,
                targetPerDay: habit.targetPerDay,
                colorHex: habit.color,
                completionsByDate: byDate,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Longest streak in the habit's full history, not just the current one.
  int _bestStreak(List<CompletionEntry> entries, Habit habit) {
    if (entries.isEmpty) return 0;

    final byDate = {
      for (final e in entries) DateOnly.format(e.date): e,
    };
    final sortedDates = entries.map((e) => e.date).toList()..sort();
    final first = sortedDates.first;
    final today = DateOnly.today();

    var best = 0;
    var running = 0;
    var cursor = first;
    while (!cursor.isAfter(today)) {
      final entry = byDate[DateOnly.format(cursor)];
      final dayCounts = habit.type.isBuild
          ? (entry != null && entry.value >= habit.targetPerDay)
          : (entry == null || !entry.isSlip);

      if (dayCounts) {
        running += 1;
        if (running > best) best = running;
      } else {
        running = 0;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return best;
  }

  int _totalGoodDays(
    Map<String, ({int value, bool isSlip})> byDate,
    Habit habit,
  ) {
    if (habit.type.isBuild) {
      return byDate.values.where((e) => e.value >= habit.targetPerDay).length;
    }
    // For quit habits, "good days" = days since creation minus slipped days.
    final createdDate = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    final daysSinceCreation = DateOnly.today().difference(createdDate).inDays + 1;
    final slipCount = byDate.values.where((e) => e.isSlip).length;
    return (daysSinceCreation - slipCount).clamp(0, daysSinceCreation);
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}