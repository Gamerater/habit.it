import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/habit_type.dart';
import 'color_palette.dart';
import 'heat_color.dart';

const double _spacing = 3;
const int _minWeeks = 8;
const int _maxWeeks = 26;
const List<String> _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Week-aligned heatmap for habit cards: weeks run left to right as columns,
/// and the 7 rows are Monday through Sunday — the same layout as the year
/// view — so a row always means the same weekday, and the rightmost column is
/// the current week.
///
/// The number of weeks isn't fixed: it's however many fit the available width
/// at roughly [targetCell] pixels per cell (17 at the default on a typical
/// phone), and the cell size is then stretched to fill the width exactly.
/// That keeps cells — and therefore card height — about the same on narrow
/// and wide screens. Set [showMonthLabels] to add month names above the grid.
///
/// Day colors come from [heatmapDayColor], shared with the week strip.
class WeekHeatmap extends StatelessWidget {
  final HabitType type;
  final int targetPerDay;
  final String colorHex;
  final Map<String, ({int value, bool isSlip})> completionsByDate;
  final DateTime habitCreatedAt;

  /// Approximate cell size in logical pixels; larger means bigger cells and
  /// fewer weeks.
  final double targetCell;

  /// Draw month abbreviations above the column where each month starts.
  final bool showMonthLabels;

  const WeekHeatmap({
    super.key,
    required this.type,
    required this.targetPerDay,
    required this.colorHex,
    required this.completionsByDate,
    required this.habitCreatedAt,
    this.targetCell = 14,
    this.showMonthLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = hexToColor(colorHex);
    final today = DateOnly.today();
    final createdDay = DateTime(
      habitCreatedAt.year,
      habitCreatedAt.month,
      habitCreatedAt.day,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;

        final weeks = math.max(
          _minWeeks,
          math.min(_maxWeeks, ((width + _spacing) / (targetCell + _spacing)).floor()),
        );
        final cell = (width - _spacing * (weeks - 1)) / weeks;

        // Built with DateTime(y, m, d + n) rather than adding Durations,
        // which can land on the wrong date across a daylight-saving change.
        final currentMonday = DateTime(
          today.year,
          today.month,
          today.day - (today.weekday - 1),
        );
        final gridStart = DateTime(
          currentMonday.year,
          currentMonday.month,
          currentMonday.day - 7 * (weeks - 1),
        );
        DateTime dateAt(int column, int row) => DateTime(
              gridStart.year,
              gridStart.month,
              gridStart.day + column * 7 + row,
            );

        final grid = Row(
          children: [
            for (int c = 0; c < weeks; c++) ...[
              if (c > 0) const SizedBox(width: _spacing),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int r = 0; r < 7; r++) ...[
                    if (r > 0) const SizedBox(height: _spacing),
                    Container(
                      width: cell,
                      height: cell,
                      decoration: BoxDecoration(
                        color: heatmapDayColor(
                          theme: theme,
                          accent: accent,
                          type: type,
                          targetPerDay: targetPerDay,
                          completionsByDate: completionsByDate,
                          date: dateAt(c, r),
                          today: today,
                          createdDay: createdDay,
                        ),
                        borderRadius: BorderRadius.circular(cell * 0.3),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );

        if (!showMonthLabels) return grid;

        // One label above the column containing the 1st of each month. A
        // label that wouldn't fit before the right edge is skipped rather
        // than clipped mid-word.
        final labelStyle = theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: width,
              child: Stack(
                children: [
                  for (int c = 0; c < weeks; c++)
                    for (int r = 0; r < 7; r++)
                      if (dateAt(c, r).day == 1 && c * (cell + _spacing) + 24 <= width)
                        Positioned(
                          left: c * (cell + _spacing),
                          child: Text(
                            _monthAbbreviations[dateAt(c, r).month - 1],
                            style: labelStyle,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            grid,
          ],
        );
      },
    );
  }
}