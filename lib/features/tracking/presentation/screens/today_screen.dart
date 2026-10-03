import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../habits/domain/habit.dart';
import '../../../habits/presentation/providers/habits_provider.dart';
import '../../../habits/presentation/widgets/color_palette.dart';
import '../../../habits/presentation/widgets/habit_avatar.dart';
import '../../../habits/presentation/widgets/habit_heatmap.dart';

/// Main tracking screen: one full-width card per habit — icon, name,
/// description, a today check button, and a large heatmap — matching the
/// HabitKit reference layout directly per request, rather than the
/// multi-day row-table this screen used previously.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(activeHabitsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/habits/new'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Something went wrong: $err')),
        data: (habits) {
          if (habits.isEmpty) return const _EmptyState();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: habits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _HabitCard(habit: habits[i]),
          );
        },
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final Habit habit;

  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = hexToColor(habit.color);
    final today = DateOnly.today();
    final repo = ref.read(habitRepositoryProvider);

    final todayCompletions = ref.watch(todayCompletionsProvider).valueOrNull ?? const {};
    final entry = todayCompletions[habit.id];
    final isDone = habit.type.isBuild
        ? (entry != null && entry.value >= habit.targetPerDay)
        : !(entry?.isSlip ?? false);

    final completionsAsync = ref.watch(habitCompletionsProvider(habit.id));
    final byDate = completionsAsync.maybeWhen(
      data: (rows) => {
        for (final r in rows) r.date: (value: r.value, isSlip: r.isSlip),
      },
      orElse: () => <String, ({int value, bool isSlip})>{},
    );

    return GestureDetector(
      onTap: () => context.push('/habits/detail', extra: habit),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Subtle color wash from the habit's own accent — this is what
          // makes each card feel distinct at a glance rather than a stack
          // of identical gray boxes.
          color: Color.alphaBlend(
            accent.withValues(alpha: 0.07),
            theme.colorScheme.surfaceContainerHigh,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HabitAvatar(icon: habit.icon, colorHex: habit.color, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (habit.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          habit.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => repo.toggleToday(habit: habit, date: today),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDone ? accent : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: isDone ? accent : theme.colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color: isDone ? Colors.white : theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 92,
              width: double.infinity,
              child: HabitHeatmap(
                type: habit.type,
                targetPerDay: habit.targetPerDay,
                colorHex: habit.color,
                completionsByDate: byDate,
                habitCreatedAt: habit.createdAt,
                days: 120,
                columns: 24,
              ),
            ),
          ],
        ),
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