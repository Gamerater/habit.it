import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/habit_type.dart';
import 'color_palette.dart';
import 'heat_color.dart';

/// A one-week heatmap: the last [days] days (7 by default) as a row of small
/// squares, oldest to newest, with today on the right and outlined so it's
/// easy to find. Used by the small Today card, where a full heatmap won't fit.
/// Colors come from [heatmapDayColor], so it always agrees with the larger
/// heatmaps.
class DayStrip extends StatelessWidget {
  final HabitType type;
  final int targetPerDay;
  final String colorHex;
  final Map<String, ({int value, bool isSlip})> completionsByDate;
  final DateTime habitCreatedAt;
  final int days;
  final double cell;
  final double spacing;

  const DayStrip({
    super.key,
    required this.type,
    required this.targetPerDay,
    required this.colorHex,
    required this.completionsByDate,
    required this.habitCreatedAt,
    this.days = 7,
    this.cell = 9,
    this.spacing = 3,
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < days; i++) ...[
          if (i > 0) SizedBox(width: spacing),
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
                date: DateTime(today.year, today.month, today.day - (days - 1 - i)),
                today: today,
                createdDay: createdDay,
              ),
              borderRadius: BorderRadius.circular(cell * 0.3),
              border: i == days - 1
                  ? Border.all(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      width: 1,
                    )
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}