import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/habit_type.dart';
import 'color_palette.dart';

/// GitHub-contributions-style grid: one square per day, oldest to newest,
/// wrapped at [columns] per row. Filled = "counts as a good day" (done for
/// build habits, clean for quit habits); faint tint = not.
class HabitHeatmap extends StatelessWidget {
  final HabitType type;
  final int targetPerDay;
  final String colorHex;
  final Map<String, ({int value, bool isSlip})> completionsByDate;
  final DateTime habitCreatedAt;
  final int days;
  final int columns;

  const HabitHeatmap({
    super.key,
    required this.type,
    required this.targetPerDay,
    required this.colorHex,
    required this.completionsByDate,
    required this.habitCreatedAt,
    this.days = 35,
    this.columns = 7,
  });

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(colorHex);
    final today = DateOnly.today();

    final dates = List.generate(
      days,
      (i) => today.subtract(Duration(days: days - 1 - i)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 4.0;
        final rows = (days / columns).ceil();

        final widthBasedSize =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final heightBasedSize = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - spacing * (rows - 1)) / rows
            : widthBasedSize;
        final cellSize = widthBasedSize < heightBasedSize
            ? widthBasedSize
            : heightBasedSize;

        return Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final date in dates)
                _Cell(
                  size: cellSize,
                  state: _stateFor(date),
                  accent: accent,
                ),
            ],
          ),
        );
      },
    );
  }

  _CellState _stateFor(DateTime date) {
    final createdDay = DateTime(
      habitCreatedAt.year,
      habitCreatedAt.month,
      habitCreatedAt.day,
    );
    if (date.isBefore(createdDay)) return _CellState.blank;

    final entry = completionsByDate[DateOnly.format(date)];
    final isGood = type.isBuild
        ? (entry != null && entry.value >= targetPerDay)
        : (entry == null || !entry.isSlip);
    return isGood ? _CellState.good : _CellState.notGood;
  }
}

enum _CellState { good, notGood, blank }

class _Cell extends StatelessWidget {
  final double size;
  final _CellState state;
  final Color accent;

  const _Cell({
    required this.size,
    required this.state,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _CellState.good => accent,
      _CellState.notGood => accent.withValues(alpha: 0.1),
      // Visible neutral placeholder rather than fully transparent, so a
      // recently-created habit's card doesn't look like a blank/broken grid.
      _CellState.blank => Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
    );
  }
}