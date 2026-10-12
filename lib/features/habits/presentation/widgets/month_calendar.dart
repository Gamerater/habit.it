import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/habit_type.dart';
import 'color_palette.dart';

const List<String> _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _weekdayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// How many days back (today inclusive) can be backfilled — lets someone
/// catch up on a missed day without allowing unlimited retroactive editing
/// of very old history.
const int editableWindowDays = 14;

/// A full month calendar: tap a day to toggle its completion, long-press to
/// add/edit a note. A day is editable when it's today or up to
/// [editableWindowDays] days in the past, AND on/after the habit's creation
/// date — whichever floor is later wins. Future days are never editable.
class MonthCalendar extends StatefulWidget {
  final HabitType type;
  final int targetPerDay;
  final String colorHex;
  final Map<String, ({int value, bool isSlip})> completionsByDate;
  final Set<String> datesWithNotes;
  final DateTime habitCreatedAt;

  /// What a tap does, for the hint under the calendar ("toggle it" for
  /// yes/no habits, "set its total" for Count/Measure).
  final String tapVerb;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<DateTime> onDayLongPress;

  const MonthCalendar({
    super.key,
    required this.type,
    required this.targetPerDay,
    required this.colorHex,
    required this.completionsByDate,
    required this.datesWithNotes,
    required this.habitCreatedAt,
    this.tapVerb = 'toggle it',
    required this.onDayTap,
    required this.onDayLongPress,
  });

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final today = DateOnly.today();
    _visibleMonth = DateTime(today.year, today.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  bool _isGoodDay(DateTime date) {
    final entry = widget.completionsByDate[DateOnly.format(date)];
    if (widget.type.isBuild) {
      return entry != null && entry.value >= widget.targetPerDay;
    }
    return entry == null || !entry.isSlip;
  }

  /// For Count/Measure habits: the tint strength for a day that has some
  /// progress but hasn't reached the goal, or null when there's nothing
  /// partial to show (no entry, a slip, or the goal already met).
  double? _partialAlphaFor(DateTime date) {
    final entry = widget.completionsByDate[DateOnly.format(date)];
    if (entry == null || entry.isSlip) return null;
    if (entry.value <= 0 || entry.value >= widget.targetPerDay) return null;
    return partialProgressAlpha(value: entry.value, target: widget.targetPerDay);
  }

  bool _isBeforeCreation(DateTime date) {
    final createdDay = DateTime(
      widget.habitCreatedAt.year,
      widget.habitCreatedAt.month,
      widget.habitCreatedAt.day,
    );
    return date.isBefore(createdDay);
  }

  /// Only today and the previous [editableWindowDays - 1] days are editable.
  bool _isTooFarInPast(DateTime date, DateTime today) {
    final earliestEditable = today.subtract(const Duration(days: editableWindowDays - 1));
    return date.isBefore(earliestEditable);
  }

  bool _isDisabled(DateTime date, DateTime today) {
    return date.isAfter(today) || _isBeforeCreation(date) || _isTooFarInPast(date, today);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = hexToColor(widget.colorHex);
    final today = DateOnly.today();

    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final gridStart = firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));
    final days = List.generate(42, (i) => gridStart.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeekdayHeaderRow(theme),
        for (int row = 0; row < 6; row++)
          Row(
            children: [
              for (int col = 0; col < 7; col++)
                Expanded(
                  child: _DayCell(
                    date: days[row * 7 + col],
                    inCurrentMonth: days[row * 7 + col].month == _visibleMonth.month,
                    isToday: DateOnly.isSameDay(days[row * 7 + col], today),
                    isDisabled: _isDisabled(days[row * 7 + col], today),
                    isGood: _isGoodDay(days[row * 7 + col]),
                    partialAlpha: _partialAlphaFor(days[row * 7 + col]),
                    hasNote: widget.datesWithNotes.contains(
                      DateOnly.format(days[row * 7 + col]),
                    ),
                    accent: accent,
                    onTap: () => widget.onDayTap(days[row * 7 + col]),
                    onLongPress: () => widget.onDayLongPress(days[row * 7 + col]),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => setState(() {
                _visibleMonth = DateTime(today.year, today.month);
              }),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                '${_monthAbbreviations[_visibleMonth.month - 1]} ${_visibleMonth.year}',
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap a day to ${widget.tapVerb} (up to $editableWindowDays days back). Press and hold to add a note.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaderRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          for (final label in _weekdayHeaders)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool inCurrentMonth;
  final bool isToday;
  final bool isDisabled;
  final bool isGood;
  final double? partialAlpha;
  final bool hasNote;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DayCell({
    required this.date,
    required this.inCurrentMonth,
    required this.isToday,
    required this.isDisabled,
    required this.isGood,
    required this.partialAlpha,
    required this.hasNote,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = !isDisabled && isGood;

    // A Count/Measure day with partial progress is tinted in proportion to
    // how much of the goal was reached. Past ~55% the tint is strong enough
    // that the number needs the same contrast treatment as a finished day.
    final partial = (!isDisabled && !isGood) ? partialAlpha : null;
    final strongFill = highlight || (partial != null && partial >= 0.55);

    final textColor = isDisabled
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
        : (strongFill
            ? (ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
                ? Colors.white
                : Colors.black)
            : theme.colorScheme.onSurface.withValues(alpha: inCurrentMonth ? 1 : 0.35));

    return Padding(
      padding: const EdgeInsets.all(3),
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        onLongPress: isDisabled ? null : onLongPress,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: highlight
                  ? accent.withValues(alpha: 0.85)
                  : (partial != null ? accent.withValues(alpha: partial) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: isToday ? Border.all(color: accent, width: 2) : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text('${date.day}', style: TextStyle(color: textColor, fontSize: 14)),
                if (hasNote)
                  Positioned(
                    bottom: 5,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: strongFill ? Colors.white : accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}