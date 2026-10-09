import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/streak_calculator.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../habits/domain/habit.dart';
import '../../../habits/presentation/providers/habits_provider.dart';
import '../../../habits/presentation/widgets/color_palette.dart';
import '../../../habits/presentation/widgets/habit_avatar.dart';
import '../../../habits/presentation/widgets/habit_heatmap.dart';
import '../../../habits/presentation/widgets/habit_options_sheet.dart';

/// Main tracking screen: one full-width card per habit — icon, name,
/// description, a today check button, and a large heatmap — matching the
/// HabitKit reference layout directly per request, rather than the
/// multi-day row-table this screen used previously.
///
/// Stateful now to hold the category filter selection — tap a chip to show
/// only habits in that category (multiple chips = any-of match), tap again
/// to clear it.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final Set<String> _selectedCategoryIds = {};

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(activeHabitsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? const <Category>[];

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

          final filtered = _selectedCategoryIds.isEmpty
              ? habits
              : habits
                  .where((h) => h.categoryIds.any(_selectedCategoryIds.contains))
                  .toList();

          return Column(
            children: [
              if (categories.isNotEmpty)
                _CategoryFilterRow(
                  categories: categories,
                  selectedIds: _selectedCategoryIds,
                  onToggle: (id) => setState(() {
                    if (!_selectedCategoryIds.remove(id)) {
                      _selectedCategoryIds.add(id);
                    }
                  }),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? _NoMatchesState(
                        onClear: () => setState(_selectedCategoryIds.clear),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => _HabitCard(habit: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  final List<Category> categories;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _CategoryFilterRow({
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = categories[i];
          final accent = hexToColor(category.color);
          final isSelected = selectedIds.contains(category.id);

          return GestureDetector(
            onTap: () => onToggle(category.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? accent.withValues(alpha: 0.18) : theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(22),
                border: isSelected ? Border.all(color: accent, width: 1.5) : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HabitAvatar(icon: category.icon, colorHex: category.color, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected ? accent : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoMatchesState extends StatelessWidget {
  final VoidCallback onClear;

  const _NoMatchesState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_off, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text('No habits in this category', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            TextButton(onPressed: onClear, child: const Text('Clear filter')),
          ],
        ),
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
    final today = DateOnly.today();
    final repo = ref.read(habitRepositoryProvider);

    final todayCompletions = ref.watch(todayCompletionsProvider).valueOrNull ?? const {};
    final entry = todayCompletions[habit.id];
    final isDone = habit.type.isBuild
        ? (entry != null && entry.value >= habit.targetPerDay)
        : !(entry?.isSlip ?? false);

    final completionsAsync = ref.watch(habitCompletionsProvider(habit.id));
    final rows = completionsAsync.valueOrNull ?? const [];
    final Map<String, ({int value, bool isSlip})> byDate = {
      for (final r in rows) r.date: (value: r.value, isSlip: r.isSlip),
    };

    final streak = StreakCalculator.currentStreak(
      type: habit.type,
      targetPerDay: habit.targetPerDay,
      habitCreatedAt: habit.createdAt,
      entries: [
        for (final r in rows)
          CompletionEntry(
            date: DateOnly.parse(r.date),
            value: r.value,
            isSlip: r.isSlip,
          ),
      ],
    );
    final recent = _lastSevenDays(habit, byDate, today);

    return GestureDetector(
      onTap: () => context.push('/habits/detail', extra: habit),
      onLongPress: () => showHabitOptionsSheet(context, ref, habit),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Deliberately identical in both states: tinting the whole card
          // when a habit was checked looked heavy and inconsistent across
          // themes. Completion is shown by the check button alone.
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
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
                      color: isDone ? theme.colorScheme.primary : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: isDone ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
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
            // No fixed height: the grid sizes itself from the card's width.
            // A fixed box taller than the grid needed was what left the
            // empty strip under the dots, and how much it left varied with
            // phone width.
            SizedBox(
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
            const SizedBox(height: 12),
            _CardFooter(
              isQuit: habit.type.isQuit,
              streak: streak,
              good: recent.good,
              total: recent.total,
            ),
          ],
        ),
      ),
    );
  }
}

/// How many of the last 7 days (today included) count as good, ignoring
/// days before the habit existed. Built with DateTime(y, m, d - i) rather
/// than subtracting Durations, which can land on the wrong date across a
/// daylight-saving change.
({int good, int total}) _lastSevenDays(
  Habit habit,
  Map<String, ({int value, bool isSlip})> byDate,
  DateTime today,
) {
  final createdDay = DateTime(
    habit.createdAt.year,
    habit.createdAt.month,
    habit.createdAt.day,
  );

  var good = 0;
  var total = 0;
  for (var i = 0; i < 7; i++) {
    final date = DateTime(today.year, today.month, today.day - i);
    if (date.isBefore(createdDay)) continue;
    total++;

    final entry = byDate[DateOnly.format(date)];
    final isGood = habit.type.isBuild
        ? (entry != null && entry.value >= habit.targetPerDay)
        : (entry == null || !entry.isSlip);
    if (isGood) good++;
  }
  return (good: good, total: total);
}

/// One quiet line under the heatmap: current streak on the left (flame in the
/// theme's tertiary color, per the streak styling rule), last-7-days tally on
/// the right.
class _CardFooter extends StatelessWidget {
  final bool isQuit;
  final int streak;
  final int good;
  final int total;

  const _CardFooter({
    required this.isQuit,
    required this.streak,
    required this.good,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasStreak = streak > 0;

    final streakLabel = hasStreak
        ? (isQuit
            ? '$streak day${streak == 1 ? '' : 's'} clean'
            : '$streak day${streak == 1 ? '' : 's'} streak')
        : (isQuit ? 'Slipped today' : 'No streak yet');

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 16,
                color: hasStreak
                    ? scheme.tertiary
                    : scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  streakLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasStreak ? scheme.onSurface : scheme.onSurfaceVariant,
                    fontWeight: hasStreak ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$good/$total last 7 days',
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
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