import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/streak_calculator.dart';
import '../../domain/habit.dart';
import '../providers/habits_provider.dart';
import '../widgets/color_palette.dart';
import '../widgets/habit_avatar.dart';
import '../widgets/habit_heatmap.dart';
import '../widgets/habit_options_sheet.dart';

enum _ViewMode { list, grid }

class HabitListScreen extends ConsumerStatefulWidget {
  const HabitListScreen({super.key});

  @override
  ConsumerState<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends ConsumerState<HabitListScreen> {
  _ViewMode _mode = _ViewMode.grid;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(activeHabitsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: Icon(_mode == _ViewMode.grid
                ? Icons.view_list_outlined
                : Icons.grid_view_rounded),
            tooltip: _mode == _ViewMode.grid ? 'List view' : 'Grid view',
            onPressed: () => setState(() {
              _mode = _mode == _ViewMode.grid ? _ViewMode.list : _ViewMode.grid;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/habits/new'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 44,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 18),
                    Text('No habits yet', style: theme.textTheme.headlineSmall),
                  ],
                ),
              ),
            );
          }

          return _mode == _ViewMode.grid
              ? _GridView(habits: habits)
              : _ReorderableList(habits: habits);
        },
      ),
    );
  }
}

/// List view with drag-to-reorder. Dragging is only triggered from the grip
/// handle on the right (ReorderableDragStartListener), so tap/long-press on
/// the rest of the row stay free for navigation and the options sheet
/// without fighting the drag gesture for priority.
class _ReorderableList extends ConsumerWidget {
  final List<Habit> habits;

  const _ReorderableList({required this.habits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: habits.length,
      onReorder: (oldIndex, newIndex) {
        final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
        final reordered = [...habits];
        final moved = reordered.removeAt(oldIndex);
        reordered.insert(adjustedNewIndex, moved);
        ref
            .read(habitRepositoryProvider)
            .reorderHabits(reordered.map((h) => h.id).toList());
      },
      itemBuilder: (context, i) {
        final habit = habits[i];
        final accent = hexToColor(habit.color);

        return Column(
          key: ValueKey(habit.id),
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => context.push('/habits/detail', extra: habit),
              onLongPress: () => showHabitOptionsSheet(context, ref, habit),
              child: IntrinsicHeight(
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
                        child: Text(habit.name, style: theme.textTheme.titleMedium),
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.drag_handle,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}

class _GridView extends StatelessWidget {
  final List<Habit> habits;

  const _GridView({required this.habits});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: habits.length,
      itemBuilder: (context, i) => _HabitHeatmapCard(habit: habits[i]),
    );
  }
}

class _HabitHeatmapCard extends ConsumerWidget {
  final Habit habit;

  const _HabitHeatmapCard({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final completionsAsync = ref.watch(habitCompletionsProvider(habit.id));

    return completionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rows) {
        final byDate = {
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

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/habits/detail', extra: habit),
          onLongPress: () => showHabitOptionsSheet(context, ref, habit),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HabitAvatar(icon: habit.icon, colorHex: habit.color, size: 30),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (streak > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$streak day${streak == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Expanded(
                  child: HabitHeatmap(
                    type: habit.type,
                    targetPerDay: habit.targetPerDay,
                    colorHex: habit.color,
                    completionsByDate: byDate,
                    habitCreatedAt: habit.createdAt,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}