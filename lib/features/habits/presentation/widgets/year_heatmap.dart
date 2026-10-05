import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/habit_type.dart';
import 'color_palette.dart';

const double _cell = 7;
const double _spacing = 1.5;
const double _gutterWidth = 20;
const List<String> _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _weekdayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// A true calendar-year heatmap — Jan 1 through Dec 31 (365 dots, or 366 on
/// a leap year), weeks stacked as rows reading top-to-bottom rather than
/// GitHub's left-to-right week columns. Navigate between years the same way
/// MonthCalendar navigates months.
class YearHeatmap extends StatefulWidget {
  final HabitType type;
  final int targetPerDay;
  final String colorHex;
  final Map<String, ({int value, bool isSlip})> completionsByDate;
  final DateTime habitCreatedAt;

  const YearHeatmap({
    super.key,
    required this.type,
    required this.targetPerDay,
    required this.colorHex,
    required this.completionsByDate,
    required this.habitCreatedAt,
  });

  @override
  State<YearHeatmap> createState() => _YearHeatmapState();
}

class _YearHeatmapState extends State<YearHeatmap> {
  late int _visibleYear = DateOnly.today().year;

  bool _isGoodDay(DateTime date) {
    final entry = widget.completionsByDate[DateOnly.format(date)];
    if (widget.type.isBuild) {
      return entry != null && entry.value >= widget.targetPerDay;
    }
    return entry == null || !entry.isSlip;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = hexToColor(widget.colorHex);
    final today = DateOnly.today();

    final createdDay = DateTime(
      widget.habitCreatedAt.year,
      widget.habitCreatedAt.month,
      widget.habitCreatedAt.day,
    );

    final jan1 = DateTime(_visibleYear, 1, 1);
    final dec31 = DateTime(_visibleYear, 12, 31);
    final isLeapYear = dec31.difference(jan1).inDays + 1 == 366;

    // Pad back to the Monday on/before Jan 1 so weeks align Mon..Sun, and
    // forward enough rows to cover through Dec 31.
    final gridStart = jan1.subtract(Duration(days: jan1.weekday - 1));
    final daySpan = dec31.difference(gridStart).inDays + 1;
    final rowCount = (daySpan / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_visibleYear${isLeapYear ? ' · 366 days' : ' · 365 days'}',
              style: theme.textTheme.labelLarge,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavButton(
                  icon: Icons.chevron_left,
                  onTap: () => setState(() => _visibleYear--),
                ),
                const SizedBox(width: 4),
                _NavButton(
                  icon: Icons.chevron_right,
                  onTap: _visibleYear >= today.year
                      ? null
                      : () => setState(() => _visibleYear++),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 3),
        // Weekday header: blank gutter (for month labels) + M T W T F S S.
        Row(
          children: [
            const SizedBox(width: _gutterWidth),
            for (final label in _weekdayHeaders)
              SizedBox(
                width: _cell + _spacing,
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        for (int row = 0; row < rowCount; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: _spacing),
            child: Row(
              children: [
                SizedBox(
                  width: _gutterWidth,
                  child: Text(
                    _monthLabelForRow(row, gridStart),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 8,
                    ),
                  ),
                ),
                for (int col = 0; col < 7; col++)
                  Padding(
                    padding: const EdgeInsets.only(right: _spacing),
                    child: _buildCell(
                      gridStart.add(Duration(days: row * 7 + col)),
                      today: today,
                      createdDay: createdDay,
                      accent: accent,
                      theme: theme,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _monthLabelForRow(int row, DateTime gridStart) {
    for (int col = 0; col < 7; col++) {
      final date = gridStart.add(Duration(days: row * 7 + col));
      if (date.year == _visibleYear && date.day == 1) {
        return _monthAbbreviations[date.month - 1];
      }
    }
    return '';
  }

  Widget _buildCell(
    DateTime date, {
    required DateTime today,
    required DateTime createdDay,
    required Color accent,
    required ThemeData theme,
  }) {
    // Only grid-alignment padding (the stub days before Jan 1 that fill out
    // the first week) is truly invisible — every real day of the year gets
    // a visible dot of some kind, so the grid always reads as a complete
    // calendar shape instead of looking broken/incomplete.
    final outOfYear = date.year != _visibleYear;
    if (outOfYear) {
      return SizedBox(width: _cell, height: _cell);
    }

    final isFuture = date.isAfter(today);
    final isBeforeCreation = date.isBefore(createdDay);

    Color color;
    if (isFuture || isBeforeCreation) {
      // Visible but neutral — "not tracked" rather than "good" or "missed".
      color = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    } else if (_isGoodDay(date)) {
      color = accent;
    } else {
      color = accent.withValues(alpha: 0.15);
    }

    return Container(
      width: _cell,
      height: _cell,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_cell * 0.3),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}