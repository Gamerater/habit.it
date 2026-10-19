import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/habit_type.dart';
import 'color_palette.dart';

/// The color of one day on a Today-card heatmap or week strip, so every
/// card size colors days by exactly the same rule:
/// - the habit's color when the day counts as good (done / goal met / clean),
/// - a tint of it for a day that didn't, darker the closer a Count/Measure
///   habit got to its goal,
/// - a neutral gray for days that can't be tracked (before the habit existed,
///   or still to come).
Color heatmapDayColor({
  required ThemeData theme,
  required Color accent,
  required HabitType type,
  required int targetPerDay,
  required Map<String, ({int value, bool isSlip})> completionsByDate,
  required DateTime date,
  required DateTime today,
  required DateTime createdDay,
}) {
  if (date.isAfter(today) || date.isBefore(createdDay)) {
    return theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
  }

  final entry = completionsByDate[DateOnly.format(date)];
  final isGood = type.isBuild
      ? (entry != null && entry.value >= targetPerDay)
      : (entry == null || !entry.isSlip);

  return isGood
      ? accent
      : partialProgressColor(accent, value: entry?.value ?? 0, target: targetPerDay);
}