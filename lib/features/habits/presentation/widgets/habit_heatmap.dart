import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/habit_type.dart';
import 'color_palette.dart';

/// GitHub-contributions-style grid: one square per day, most recent 42 days
/// (6 weeks), oldest to newest, wrapped 7-per-row. Filled = "counts as a
/// good day" (done for build habits, clean for quit habits); outline = not.
class HabitHeatmap extends StatelessWidget {
  final HabitType type;
  final int targetPerDay;
  final String colorHex;
  final Map<String, ({int value, bool isSlip})> completionsByDate;
  final int days;

  const HabitHeatmap({
    super.key,
    required this.type,
    required this.targetPerDay,
    required this.colorHex,
    required this.completionsByDate,
    this.days = 35,
  });

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(colorHex);
    final outline = Theme.of(context).colorScheme.outlineVariant;
    final today = DateOnly.today();

    final dates = List.generate(
      days,
      (i) => today.subtract(Duration(days: days - 1 - i)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 7;
        const spacing = 4.0;
        final rows = (days / columns).ceil();

        final widthBasedSize =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final heightBasedSize =
            (constraints.maxHeight - spacing * (rows - 1)) / rows;
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
                  filled: _isGoodDay(date),
                  accent: accent,
                  outline: outline,
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isGoodDay(DateTime date) {
    final entry = completionsByDate[DateOnly.format(date)];
    if (type.isBuild) {
      return entry != null && entry.value >= targetPerDay;
    }
    return entry == null || !entry.isSlip;
  }
}

class _Cell extends StatelessWidget {
  final double size;
  final bool filled;
  final Color accent;
  final Color outline;

  const _Cell({
    required this.size,
    required this.filled,
    required this.accent,
    required this.outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: filled ? null : Border.all(color: outline, width: 1),
      ),
    );
  }
}