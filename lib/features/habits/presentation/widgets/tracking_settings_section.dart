import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/amount_format.dart';
import '../../domain/habit_type.dart';

/// The "how is this habit tracked" settings on the Add/Edit screen: Yes/No,
/// Count (toward a daily goal), or Measure (an amount with a unit), plus the
/// goal, unit, and what a tap does. The screen owns the state and passes it
/// in, since it all has to be validated and saved together.
class TrackingSettingsSection extends StatelessWidget {
  final TrackingMethod method;
  final TrackingMode tapMode;
  final TextEditingController goalController;
  final TextEditingController unitController;
  final TextEditingController incrementController;
  final ValueChanged<TrackingMethod> onMethodChanged;
  final ValueChanged<TrackingMode> onTapModeChanged;

  const TrackingSettingsSection({
    super.key,
    required this.method,
    required this.tapMode,
    required this.goalController,
    required this.unitController,
    required this.incrementController,
    required this.onMethodChanged,
    required this.onTapModeChanged,
  });

  static const _countUnits = ['times', 'glasses', 'pages', 'reps', 'sets'];
  static const _measureUnits = ['L', 'mL', 'km', 'mi', 'min', 'h', 'kg', 'g'];

  bool get _isMeasure => method == TrackingMethod.measure;
  int get _scale => _isMeasure ? measureScale : 1;

  List<TextInputFormatter> get _numberFormatters => [
        FilteringTextInputFormatter.allow(RegExp(_isMeasure ? r'[0-9.,]' : r'[0-9]')),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Tracking method'),
        SegmentedButton<TrackingMethod>(
          showSelectedIcon: false,
          segments: [
            for (final m in TrackingMethod.values)
              ButtonSegment(value: m, label: Text(m.label)),
          ],
          selected: {method},
          onSelectionChanged: (s) => onMethodChanged(s.first),
        ),
        const SizedBox(height: 8),
        Text(
          method.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: method == TrackingMethod.yesNo
              ? const SizedBox(width: double.infinity)
              : _amountSettings(context),
        ),
      ],
    );
  }

  Widget _amountSettings(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = _isMeasure ? _measureUnits : _countUnits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const _Label('Daily goal'),
        TextField(
          controller: goalController,
          keyboardType: TextInputType.numberWithOptions(decimal: _isMeasure),
          inputFormatters: _numberFormatters,
          decoration: InputDecoration(
            hintText: _isMeasure ? 'e.g. 2' : 'e.g. 8',
            suffixText: '/ day',
          ),
        ),
        const SizedBox(height: 20),
        _Label(_isMeasure ? 'Unit' : 'Unit (optional)'),
        TextField(
          controller: unitController,
          maxLength: 16,
          decoration: InputDecoration(
            hintText: _isMeasure ? 'e.g. L, km, min' : 'e.g. glasses, pages',
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            for (final unit in suggestions)
              ActionChip(
                label: Text(unit),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  unitController.text = unit;
                  unitController.selection = TextSelection.collapsed(offset: unit.length);
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        const _Label('When I tap the button'),
        SegmentedButton<TrackingMode>(
          showSelectedIcon: false,
          segments: [
            for (final m in TrackingMode.values)
              ButtonSegment(value: m, label: Text(m.label)),
          ],
          selected: {tapMode},
          onSelectionChanged: (s) => onTapModeChanged(s.first),
        ),
        const SizedBox(height: 8),
        Text(
          tapMode == TrackingMode.stepByStep
              ? 'Each tap adds the amount below to today. Press and hold the button '
                  'any time to type an exact total.'
              : 'Each tap opens a box where you type the day\'s total.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (tapMode == TrackingMode.stepByStep) ...[
          const SizedBox(height: 20),
          const _Label('Amount added per tap'),
          ListenableBuilder(
            listenable: unitController,
            builder: (context, _) {
              final unit = unitController.text.trim();
              return TextField(
                controller: incrementController,
                keyboardType: TextInputType.numberWithOptions(decimal: _isMeasure),
                inputFormatters: _numberFormatters,
                decoration: InputDecoration(
                  hintText: _isMeasure ? 'e.g. 0.25' : 'e.g. 1',
                  suffixText: unit.isEmpty ? null : unit,
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: Listenable.merge([goalController, incrementController, unitController]),
          builder: (context, _) => _SummaryCard(text: _summaryText()),
        ),
      ],
    );
  }

  /// A plain-language readout of what the current settings mean, so the
  /// combination of goal / unit / per-tap amount is easy to sanity-check.
  String _summaryText() {
    final goal = parseScaledAmount(goalController.text, _scale);
    if (goal == null || goal <= 0) {
      return 'Set a daily goal to say when each day counts as done.';
    }

    final unit = unitController.text.trim();
    String fmt(int value) {
      final amount = formatScaledAmount(value, _scale);
      return unit.isEmpty ? amount : '$amount $unit';
    }

    var text = 'Goal: ${fmt(goal)} per day.';
    if (tapMode == TrackingMode.stepByStep) {
      final increment = parseScaledAmount(incrementController.text, _scale);
      if (increment != null && increment > 0) {
        final taps = (goal + increment - 1) ~/ increment; // rounded up
        text += ' Each tap adds ${fmt(increment)}, so ${taps == 1 ? '1 tap' : '$taps taps'} '
            'to reach it.';
      }
    }
    return '$text Heatmap days get darker the closer you get to the goal.';
  }
}

class _SummaryCard extends StatelessWidget {
  final String text;

  const _SummaryCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}