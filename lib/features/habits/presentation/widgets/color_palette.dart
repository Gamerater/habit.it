import 'package:flutter/material.dart';

/// The full habit color palette, as hex strings persisted straight to the DB.
/// 21 colors, ROYGBIV-ish ramp plus a neutral row — enough range to tell
/// habits apart at a glance without overwhelming choice.
const List<String> habitColorPalette = [
  '#F2545B', '#F2874B', '#F2B84B', '#F2D93F', '#A8D94B', '#4BD98A', '#2FD9B8',
  '#2FC7D9', '#2FA8D9', '#3F7FF2', '#6E6EF2', '#9B6EF2', '#C46EF2',
  '#E36EF2', '#F26EBE', '#F26E8C', '#9AA3AD', '#7C8894', '#5F6B77',
  '#4A545E', '#8C7B6B',
];

Color hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

/// Opacity for a day that has some progress but hasn't reached the goal:
/// 0 progress is the faint resting tint, and it ramps up with the fraction
/// of the goal reached, topping out just under the solid "goal met" color so
/// a nearly-done day is still distinguishable from a finished one.
///
/// Only Count/Measure habits can have partial days; for yes/no and quit
/// habits [value] is never between 0 and [target], so this just returns the
/// resting tint and nothing looks different.
double partialProgressAlpha({required int value, required int target}) {
  const resting = 0.1;
  if (target <= 0 || value <= 0) return resting;
  final fraction = (value / target).clamp(0.0, 1.0).toDouble();
  return 0.28 + 0.52 * fraction;
}

/// The color for a tracked day that did NOT meet the goal, shaded by how far
/// along it got. See [partialProgressAlpha].
Color partialProgressColor(Color accent, {required int value, required int target}) {
  return accent.withValues(alpha: partialProgressAlpha(value: value, target: target));
}

/// A rounded-square swatch grid with a ring around the selected color.
/// Used on the Add/Edit Habit screen.
class ColorPaletteGrid extends StatelessWidget {
  final String selectedHex;
  final ValueChanged<String> onSelected;

  const ColorPaletteGrid({
    super.key,
    required this.selectedHex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: habitColorPalette.map((hex) {
        final isSelected = hex.toUpperCase() == selectedHex.toUpperCase();
        final color = hexToColor(hex);
        return GestureDetector(
          onTap: () => onSelected(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 2.5,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}