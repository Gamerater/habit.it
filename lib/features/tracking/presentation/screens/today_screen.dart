import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/streak_calculator.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../habits/domain/habit.dart';
import '../../../habits/domain/habit_type.dart';
import '../../../habits/presentation/providers/habits_provider.dart';
import '../../../habits/presentation/widgets/amount_dialog.dart';
import '../../../habits/presentation/widgets/color_palette.dart';
import '../../../habits/presentation/widgets/day_strip.dart';
import '../../../habits/presentation/widgets/habit_avatar.dart';
import '../../../habits/presentation/widgets/habit_options_sheet.dart';
import '../../../habits/presentation/widgets/week_heatmap.dart';
import '../providers/card_size_provider.dart';

/// Main tracking screen: one card per habit with a button to log today.
/// How much each card shows is the user's choice (Small / Medium / Large,
/// from the menu in the top bar, remembered between launches):
/// - Small: a compact row — name, streak, and a one-week strip.
/// - Medium: description, a heatmap of recent weeks, streak footer.
/// - Large: bigger heatmap with month labels, category tags, a stats row.
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
    final cardSize = ref.watch(cardSizeProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          _CardSizeMenu(
            current: cardSize,
            onSelected: (size) => ref.read(cardSizeProvider.notifier).setSize(size),
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
                        separatorBuilder: (_, __) => SizedBox(height: cardSize.listGap),
                        itemBuilder: (context, i) => _HabitCard(
                          habit: filtered[i],
                          size: cardSize,
                        ),
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

/// Measurements that change with the card size. Smaller cards are tighter
/// all round — padding, corner radius, and the gap between cards — so the
/// small size reads as a dense list rather than a shrunken big card.
extension on HabitCardSize {
  double get cardPadding => switch (this) {
        HabitCardSize.small => 12.0,
        HabitCardSize.medium => 16.0,
        HabitCardSize.large => 18.0,
      };

  double get cardRadius => switch (this) {
        HabitCardSize.small => 16.0,
        HabitCardSize.medium => 20.0,
        HabitCardSize.large => 22.0,
      };

  double get listGap => switch (this) {
        HabitCardSize.small => 8.0,
        HabitCardSize.medium => 14.0,
        HabitCardSize.large => 16.0,
      };
}

/// The top-bar menu for picking the card size. The current size is
/// highlighted, and each option says what it shows so the choice is clear
/// without trying them all.
class _CardSizeMenu extends StatelessWidget {
  final HabitCardSize current;
  final ValueChanged<HabitCardSize> onSelected;

  const _CardSizeMenu({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopupMenuButton<HabitCardSize>(
      icon: const Icon(Icons.view_agenda_outlined),
      tooltip: 'Card size',
      initialValue: current,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final size in HabitCardSize.values)
          PopupMenuItem<HabitCardSize>(
            value: size,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  size.icon,
                  size: 22,
                  color: size == current ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      size.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: size == current ? FontWeight.w700 : FontWeight.w500,
                        color: size == current ? scheme.primary : null,
                      ),
                    ),
                    Text(
                      size.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Everything a card body needs, computed once per card so the three size
/// layouts only differ in how they arrange it.
class _CardData {
  final Habit habit;
  final Map<String, ({int value, bool isSlip})> byDate;
  final int streak;
  final int recentGood;
  final int recentTotal;
  final int totalDone;
  final Widget trackButton;

  const _CardData({
    required this.habit,
    required this.byDate,
    required this.streak,
    required this.recentGood,
    required this.recentTotal,
    required this.totalDone,
    required this.trackButton,
  });
}

class _HabitCard extends ConsumerWidget {
  final Habit habit;
  final HabitCardSize size;

  const _HabitCard({required this.habit, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = DateOnly.today();

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

    // Lifetime total for the large card's stats row. Build habits: days that
    // met the goal. Quit habits: every day since creation that wasn't a slip
    // (days default to clean). UTC dates keep the day count exact across a
    // daylight-saving change.
    int totalDone;
    if (habit.type.isBuild) {
      totalDone = rows.where((r) => !r.isSlip && r.value >= habit.targetPerDay).length;
    } else {
      final span = DateTime.utc(today.year, today.month, today.day)
              .difference(DateTime.utc(
                habit.createdAt.year,
                habit.createdAt.month,
                habit.createdAt.day,
              ))
              .inDays +
          1;
      final clean = span - rows.where((r) => r.isSlip).length;
      totalDone = clean < 0 ? 0 : clean;
    }

    final data = _CardData(
      habit: habit,
      byDate: byDate,
      streak: streak,
      recentGood: recent.good,
      recentTotal: recent.total,
      totalDone: totalDone,
      trackButton: _TrackButton(
        habit: habit,
        value: entry?.value ?? 0,
        isDone: isDone,
        compact: size == HabitCardSize.small,
      ),
    );

    final Widget body = switch (size) {
      HabitCardSize.small => _SmallCardBody(data: data),
      HabitCardSize.medium => _MediumCardBody(data: data),
      HabitCardSize.large => _LargeCardBody(data: data),
    };

    return GestureDetector(
      onTap: () => context.push('/habits/detail', extra: habit),
      onLongPress: () => showHabitOptionsSheet(context, ref, habit),
      child: Container(
        padding: EdgeInsets.all(size.cardPadding),
        decoration: BoxDecoration(
          // Deliberately identical in both states: tinting the whole card
          // when a habit was checked looked heavy and inconsistent across
          // themes. Completion is shown by the track button alone.
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(size.cardRadius),
          border: Border.all(color: theme.dividerColor),
        ),
        child: body,
      ),
    );
  }
}

/// The button on the right of every card. A check for yes/no habits; a
/// progress pill for Count/Measure habits (see [_AmountButton]).
class _TrackButton extends ConsumerWidget {
  final Habit habit;
  final int value;
  final bool isDone;

  /// Used by the small card, where horizontal space is tight.
  final bool compact;

  const _TrackButton({
    required this.habit,
    required this.value,
    required this.isDone,
    required this.compact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(habitRepositoryProvider);
    final today = DateOnly.today();

    if (habit.tracksAmount) {
      return _AmountButton(
        habit: habit,
        value: value,
        isDone: isDone,
        compact: compact,
        // "Add an amount" habits add their increment on tap; "enter total"
        // habits ask. Long-press always opens the total dialog, which is
        // also how you fix a mistaken tap or clear the day.
        onTap: () {
          if (habit.trackingMode == TrackingMode.stepByStep) {
            repo.addToDay(habitId: habit.id, date: today, delta: habit.tapIncrement);
          } else {
            promptForDayTotal(context, ref, habit, today, value);
          }
        },
        onLongPress: () => promptForDayTotal(context, ref, habit, today, value),
      );
    }

    return GestureDetector(
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
    );
  }
}

/// Small: one dense row. Name on top; underneath, a one-week strip and the
/// streak count. No description, no footer — the point is to fit many habits
/// on screen and still see at a glance how this week is going.
class _SmallCardBody extends StatelessWidget {
  final _CardData data;

  const _SmallCardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = data.habit;

    return Row(
      children: [
        HabitAvatar(icon: habit.icon, colorHex: habit.color, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                habit.name,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  DayStrip(
                    type: habit.type,
                    targetPerDay: habit.targetPerDay,
                    colorHex: habit.color,
                    completionsByDate: data.byDate,
                    habitCreatedAt: habit.createdAt,
                  ),
                  if (data.streak > 0) ...[
                    const SizedBox(width: 10),
                    Flexible(child: _MiniStreak(streak: data.streak)),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        data.trackButton,
      ],
    );
  }
}

/// A flame and a number, scaled down rather than overflowing if the row is
/// too tight (a wide Count/Measure pill on a narrow phone).
class _MiniStreak extends StatelessWidget {
  final int streak;

  const _MiniStreak({required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 14, color: theme.colorScheme.tertiary),
          const SizedBox(width: 3),
          Text(
            '$streak',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Medium: the standard card — description, a heatmap of recent weeks, and a
/// one-line streak / last-7-days footer.
class _MediumCardBody extends StatelessWidget {
  final _CardData data;

  const _MediumCardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = data.habit;

    return Column(
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
            data.trackButton,
          ],
        ),
        const SizedBox(height: 14),
        // Week-aligned: 7 rows (Mon–Sun), weeks across, current week on the
        // right. No fixed height, so there's no dead space under the dots.
        SizedBox(
          width: double.infinity,
          child: WeekHeatmap(
            type: habit.type,
            targetPerDay: habit.targetPerDay,
            colorHex: habit.color,
            completionsByDate: data.byDate,
            habitCreatedAt: habit.createdAt,
          ),
        ),
        const SizedBox(height: 12),
        _CardFooter(
          isQuit: habit.type.isQuit,
          streak: data.streak,
          good: data.recentGood,
          total: data.recentTotal,
        ),
      ],
    );
  }
}

/// Large: everything. A bigger avatar and a two-line description, the
/// habit's category tags, a larger heatmap with month labels, and a stats row
/// (streak, last 7 days, lifetime total) in place of the one-line footer.
class _LargeCardBody extends ConsumerWidget {
  final _CardData data;

  const _LargeCardBody({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final habit = data.habit;

    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final tags = categories.where((c) => habit.categoryIds.contains(c.id)).toList();

    final statStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HabitAvatar(icon: habit.icon, colorHex: habit.color, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (habit.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      habit.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            data.trackButton,
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final category in tags) _CategoryTag(category: category)],
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: WeekHeatmap(
            type: habit.type,
            targetPerDay: habit.targetPerDay,
            colorHex: habit.color,
            completionsByDate: data.byDate,
            habitCreatedAt: habit.createdAt,
            targetCell: 18,
            showMonthLabels: true,
          ),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatBlock(
                label: 'Current streak',
                value: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 18,
                      color: data.streak > 0
                          ? scheme.tertiary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text('${data.streak}', style: statStyle),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _StatBlock(
                label: 'Last 7 days',
                value: Text('${data.recentGood}/${data.recentTotal}', style: statStyle),
              ),
            ),
            Expanded(
              child: _StatBlock(
                label: habit.type.isQuit ? 'Clean days' : 'Days done',
                value: Text('${data.totalDone}', style: statStyle),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final Widget value;
  final String label;

  const _StatBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        value,
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final Category category;

  const _CategoryTag({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hexToColor(category.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        category.name,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The Today-card button for Count/Measure habits: a pill showing progress
/// toward the goal ("3/8", "1.5/2 L") whose background fills as you go, and
/// turns solid with a check once the goal is met.
class _AmountButton extends StatelessWidget {
  final Habit habit;
  final int value;
  final bool isDone;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Narrower pill whose label shrinks to fit instead of truncating — for
  /// the small card, where the pill shares a row with the week strip.
  final bool compact;

  const _AmountButton({
    required this.habit,
    required this.value,
    required this.isDone,
    required this.onTap,
    required this.onLongPress,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final goal = habit.targetPerDay;
    final fraction = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0).toDouble();
    final adds = habit.trackingMode == TrackingMode.stepByStep;
    final label = '${habit.formatAmount(value)}/${habit.formatAmountWithUnit(goal)}';

    final foreground = isDone ? scheme.onPrimary : scheme.onSurface;
    final icon = isDone ? Icons.check : (adds ? Icons.add : Icons.edit_outlined);

    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelLarge?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 36,
          constraints: BoxConstraints(minWidth: 36, maxWidth: compact ? 110 : 150),
          decoration: BoxDecoration(
            color: isDone ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isDone ? scheme.primary : scheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isDone && fraction > 0)
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: ColoredBox(color: scheme.primary.withValues(alpha: 0.22)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: foreground),
                    const SizedBox(width: 4),
                    Flexible(
                      child: compact
                          ? FittedBox(fit: BoxFit.scaleDown, child: labelText)
                          : labelText,
                    ),
                  ],
                ),
              ),
            ],
          ),
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