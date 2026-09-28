import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../habits/domain/habit.dart';
import '../../../habits/presentation/providers/habits_provider.dart';
import '../../../habits/presentation/widgets/color_palette.dart';
import '../../../habits/presentation/widgets/habit_avatar.dart';

const List<int> _dayRangeOptions = [5, 7, 14];

/// The main tracking screen, matching HabitKit's layout directly per request:
/// a header row of day labels, then one row per habit with a tappable
/// colored square under each day — not just a single "today" checkbox.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  int _dayCount = 5;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(activeHabitsProvider);
    final theme = Theme.of(context);
    final today = DateOnly.today();
    final days = List.generate(
      _dayCount,
      (i) => today.subtract(Duration(days: _dayCount - 1 - i)),
    );

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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DayRangeChip(
                      value: _dayCount,
                      onChanged: (v) => setState(() => _dayCount = v),
                    ),
                    Text(
                      _formatRange(days.first, days.last),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _DayHeaderRow(days: days),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: habits.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _HabitGridRow(
                    habit: habits[i],
                    days: days,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatRange(DateTime start, DateTime end) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final startStr = '${start.day} ${months[start.month - 1]}';
    final endStr = '${end.day} ${months[end.month - 1]}';
    return '$startStr – $endStr';
  }
}

class _DayRangeChip extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DayRangeChip({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        final index = _dayRangeOptions.indexOf(value);
        onChanged(_dayRangeOptions[(index + 1) % _dayRangeOptions.length]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Last $value days', style: theme.textTheme.labelLarge),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Fixed leading width reserved for the avatar+name column, so day columns
/// in the header line up exactly with the squares in each habit row below.
const double _leadingWidth = 148;

class _DayHeaderRow extends StatelessWidget {
  final List<DateTime> days;

  const _DayHeaderRow({required this.days});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const weekdayLetters = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final today = DateOnly.today();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          const SizedBox(width: _leadingWidth),
          for (final day in days)
            Expanded(
              child: Column(
                children: [
                  Text(
                    weekdayLetters[day.weekday - 1],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: DateOnly.isSameDay(day, today)
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: DateOnly.isSameDay(day, today)
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HabitGridRow extends ConsumerWidget {
  final Habit habit;
  final List<DateTime> days;

  const _HabitGridRow({required this.habit, required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = hexToColor(habit.color);
    final repo = ref.read(habitRepositoryProvider);
    final completionsAsync = ref.watch(habitCompletionsProvider(habit.id));

    final byDate = completionsAsync.maybeWhen(
      data: (rows) => {for (final r in rows) r.date: r},
      orElse: () => <String, CompletionRow>{},
    );

    bool isGoodDay(DateTime date) {
      final entry = byDate[DateOnly.format(date)];
      if (habit.type.isBuild) {
        return entry != null && entry.value >= habit.targetPerDay;
      }
      return entry == null || !entry.isSlip;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: _leadingWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 8),
              child: Row(
                children: [
                  HabitAvatar(icon: habit.icon, colorHex: habit.color, size: 32),
                  const SizedBox(width: 10),
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
            ),
          ),
          for (final day in days)
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => repo.toggleToday(habit: habit, date: day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isGoodDay(day) ? accent : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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