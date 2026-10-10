import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/habit_type.dart';
import 'color_palette.dart';

const double _targetCell = 14;
const double _spacing = 3;
const int _minWeeks = 8;
const int _maxWeeks = 26;

/// Week-aligned heatmap for habit cards: weeks run left to right as columns,
/// and the 7 rows are Monday through Sunday — the same layout as the year
/// view — so a row always means the same weekday, and the rightmost column is
/// the current week.
///
/// The number of weeks isn't fixed: it's however many fit the available width
/// at roughly [_targetCell] pixels per cell (17 on a typical phone), and the
/// cell size is then stretched to fill the width exactly. That keeps cells —
/// and therefore card height — about the same on narrow and wide screens.
///
/// Day colors follow the other heatmaps: the habit's color for a good day, a
/// faint tint of it for a day that wasn't, and a neutral gray for days that
/// can't be tracked (before the habit existed, or still in the future).
class WeekHeatmap extends StatelessWidget {
  final HabitType type;
  final int targetPerDay;
  final String colorHex;
  final Map<String, ({int value, bool isSlip})> completionsByDate;
  final DateTime habitCreatedAt;

  const WeekHeatmap({
    super.key,
    required this.type,
    required this.targetPerDay,
    required this.colorHex,
    required this.completionsByDate,
    required this.habitCreatedAt,
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

    Color colorFor(DateTime date) {
      if (date.isAfter(today) || date.isBefore(createdDay)) {
        return theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
      }
      final entry = completionsByDate[DateOnly.format(date)];
      final isGood = type.isBuild
          ? (entry != null && entry.value >= targetPerDay)
          : (entry == null || !entry.isSlip);
      return isGood ? accent : accent.withValues(alpha: 0.1);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;

        final weeks = math.max(
          _minWeeks,
          math.min(_maxWeeks, ((width + _spacing) / (_targetCell + _spacing)).floor()),
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

        return Row(
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
                        color: colorFor(
                          DateTime(
                            gridStart.year,
                            gridStart.month,
                            gridStart.day + c * 7 + r,
                          ),
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
      },
    );
  }
}