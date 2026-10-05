import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/habit_type.dart';
import 'color_palette.dart';

const double _cell = 11;
const double _spacing = 3;
const double _columnWidth = _cell + _spacing;
const List<String> _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A true calendar-year heatmap matching HabitKit's layout: weeks as
/// columns running left (January) to right (December/today), 7 rows
/// (Mon..Sun), horizontally scrollable and auto-scrolled to the right edge
/// (most recent) by default — scroll left to go back toward January.
/// Compact by design: height is always exactly 7 rows regardless of how
/// many weeks exist, since the year dimension lives in scrollable width,
/// not page height.
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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _changeYear(int delta) {
    setState(() => _visibleYear += delta);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

    final gridStart = jan1.subtract(Duration(days: jan1.weekday - 1));
    final daySpan = dec31.difference(gridStart).inDays + 1;
    final columnCount = (daySpan / 7).ceil();

    bool isGoodDay(DateTime date) => _isGoodDay(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                _NavButton(icon: Icons.chevron_left, onTap: () => _changeYear(-1)),
                const SizedBox(width: 4),
                _NavButton(
                  icon: Icons.chevron_right,
                  onTap: _visibleYear >= today.year ? null : () => _changeYear(1),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 14,
                width: columnCount * _columnWidth,
                child: Stack(
                  children: [
                    for (int c = 0; c < columnCount; c++)
                      for (int r = 0; r < 7; r++)
                        if (gridStart.add(Duration(days: c * 7 + r)).year == _visibleYear &&
                            gridStart.add(Duration(days: c * 7 + r)).day == 1)
                          Positioned(
                            left: c * _columnWidth,
                            child: Text(
                              _monthAbbreviations[
                                  gridStart.add(Duration(days: c * 7 + r)).month - 1],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 9,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int c = 0; c < columnCount; c++)
                    Padding(
                      padding: const EdgeInsets.only(right: _spacing),
                      child: Column(
                        children: [
                          for (int r = 0; r < 7; r++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: _spacing),
                              child: Builder(builder: (context) {
                                final date = gridStart.add(Duration(days: c * 7 + r));
                                final outOfYear = date.year != _visibleYear;
                                final isFuture = date.isAfter(today);
                                final isBeforeCreation = date.isBefore(createdDay);

                                if (outOfYear) {
                                  return const SizedBox(width: _cell, height: _cell);
                                }

                                Color color;
                                if (isFuture || isBeforeCreation) {
                                  color = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
                                } else if (isGoodDay(date)) {
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
                              }),
                            ),
                        ],
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