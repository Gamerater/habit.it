import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/habit_type.dart';
import 'color_palette.dart';

const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A year of history as a GitHub-contributions-style grid: columns are
/// weeks (Monday at the top, Sunday at the bottom), scrolls horizontally,
/// auto-scrolled to today on open, with month labels above the column
/// where each month starts.
class YearHeatmap extends StatefulWidget {
  final HabitType type;
  final int targetPerDay;
  final String colorHex;
  final Map<String, ({int value, bool isSlip})> completionsByDate;

  const YearHeatmap({
    super.key,
    required this.type,
    required this.targetPerDay,
    required this.colorHex,
    required this.completionsByDate,
  });

  @override
  State<YearHeatmap> createState() => _YearHeatmapState();
}

class _YearHeatmapState extends State<YearHeatmap> {
  final _scrollController = ScrollController();
  static const double _cell = 14;
  static const double _spacing = 4;
  static const double _columnWidth = _cell + _spacing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(widget.colorHex);
    final outline = Theme.of(context).colorScheme.outlineVariant;
    final theme = Theme.of(context);
    final today = DateOnly.today();

    // Align the grid start to the Monday on/before (today - 364 days) so
    // every column is a clean Monday-to-Sunday week.
    final roughStart = today.subtract(const Duration(days: 364));
    final gridStart = roughStart.subtract(Duration(days: roughStart.weekday - 1));

    final totalDays = today.difference(gridStart).inDays + 1;
    final columnCount = (totalDays / 7).ceil();

    // Build columns of 7 (Mon..Sun); null for days after today (partial
    // trailing week) so they render as blank instead of "not done".
    final columns = <List<DateTime?>>[];
    for (int c = 0; c < columnCount; c++) {
      final column = <DateTime?>[];
      for (int r = 0; r < 7; r++) {
        final date = gridStart.add(Duration(days: c * 7 + r));
        column.add(date.isAfter(today) ? null : date);
      }
      columns.add(column);
    }

    bool isGoodDay(DateTime date) {
      final entry = widget.completionsByDate[DateOnly.format(date)];
      if (widget.type.isBuild) {
        return entry != null && entry.value >= widget.targetPerDay;
      }
      return entry == null || !entry.isSlip;
    }

    String? monthLabelFor(int columnIndex) {
      final firstDayOfColumn = columns[columnIndex].firstWhere(
        (d) => d != null,
        orElse: () => null,
      );
      if (firstDayOfColumn == null) return null;
      if (firstDayOfColumn.day > 7) return null; // only label a month once
      if (columnIndex == 0) return _monthNames[firstDayOfColumn.month - 1];

      final prevColumnDay = columns[columnIndex - 1].firstWhere(
        (d) => d != null,
        orElse: () => null,
      );
      if (prevColumnDay == null || prevColumnDay.month != firstDayOfColumn.month) {
        return _monthNames[firstDayOfColumn.month - 1];
      }
      return null;
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 16,
              width: columnCount * _columnWidth,
              child: Stack(
                children: [
                  for (int c = 0; c < columnCount; c++)
                    if (monthLabelFor(c) != null)
                      Positioned(
                        left: c * _columnWidth,
                        child: Text(
                          monthLabelFor(c)!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final column in columns)
                  Padding(
                    padding: const EdgeInsets.only(right: _spacing),
                    child: Column(
                      children: [
                        for (final date in column)
                          Padding(
                            padding: const EdgeInsets.only(bottom: _spacing),
                            child: Container(
                              width: _cell,
                              height: _cell,
                              decoration: BoxDecoration(
                                color: date == null
                                    ? Colors.transparent
                                    : (isGoodDay(date) ? accent : Colors.transparent),
                                borderRadius: BorderRadius.circular(3),
                                border: date != null && !isGoodDay(date)
                                    ? Border.all(color: outline, width: 1)
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}