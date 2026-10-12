import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/amount_format.dart';
import '../../domain/habit.dart';
import '../providers/habits_provider.dart';

/// "Today", "Yesterday", or a short date like "Oct 3" — for dialog titles.
String dayLabel(DateTime date) {
  final today = DateOnly.today();
  if (DateOnly.isSameDay(date, today)) return 'Today';
  if (DateOnly.isSameDay(date, DateTime(today.year, today.month, today.day - 1))) {
    return 'Yesterday';
  }
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

/// Asks the user for a day's total on a Count/Measure habit and saves it.
/// Used by the Today card (long-press, or tap in "enter total" mode) and by
/// the detail calendar. A cleared/zero total removes the day's entry.
Future<void> promptForDayTotal(
  BuildContext context,
  WidgetRef ref,
  Habit habit,
  DateTime date,
  int current,
) async {
  final result = await showAmountTotalDialog(
    context,
    habit: habit,
    title: dayLabel(date),
    current: current,
  );
  if (result == null) return; // cancelled

  await ref.read(habitRepositoryProvider).setAmount(
        habitId: habit.id,
        date: date,
        value: result,
      );
}

/// Returns the entered total in stored units (0 means "clear the day"), or
/// null if the dialog was cancelled.
Future<int?> showAmountTotalDialog(
  BuildContext context, {
  required Habit habit,
  required String title,
  required int current,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _AmountTotalDialog(habit: habit, title: title, current: current),
  );
}

class _AmountTotalDialog extends StatefulWidget {
  final Habit habit;
  final String title;
  final int current;

  const _AmountTotalDialog({
    required this.habit,
    required this.title,
    required this.current,
  });

  @override
  State<_AmountTotalDialog> createState() => _AmountTotalDialogState();
}

class _AmountTotalDialogState extends State<_AmountTotalDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current > 0 ? widget.habit.formatAmount(widget.current) : '',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = parseScaledAmount(_controller.text, widget.habit.valueScale);
    if (parsed == null) {
      setState(() => _error = 'Enter a valid number');
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = widget.habit;
    final allowsDecimals = habit.valueScale > 1;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: allowsDecimals),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(allowsDecimals ? r'[0-9.,]' : r'[0-9]'),
              ),
            ],
            decoration: InputDecoration(
              hintText: 'Total for the day',
              suffixText: habit.unitLabel.isEmpty ? null : habit.unitLabel,
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
          Text(
            'Goal: ${habit.formatAmountWithUnit(habit.targetPerDay)} per day',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(0),
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}