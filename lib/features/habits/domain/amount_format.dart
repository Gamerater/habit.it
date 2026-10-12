/// Count and Measure habits store their daily progress as plain integers so
/// everything that already compares `value >= targetPerDay` — heatmaps,
/// streaks, the calendar — keeps working untouched.
///
/// Counts are stored as-is (3 glasses -> 3). Measures keep up to three
/// decimal places by storing thousandths (2.5 L -> 2500), and the habit's
/// goal and tap increment are scaled the same way. These helpers convert
/// between what the user types/sees and what's stored.
const int measureScale = 1000;

const int _maxWhole = 1000000000;

/// Formats a stored amount for display: `2500` with scale 1000 -> "2.5",
/// `2000` -> "2", `3` with scale 1 -> "3". Done with integer math so there's
/// no floating-point noise like "2.4999999".
String formatScaledAmount(int scaled, int scale) {
  if (scale <= 1) return '$scaled';

  final whole = scaled ~/ scale;
  final fraction = scaled % scale;
  if (fraction == 0) return '$whole';

  final digits = scale.toString().length - 1; // 1000 -> 3 decimal places
  final trimmed = fraction.toString().padLeft(digits, '0').replaceFirst(RegExp(r'0+$'), '');
  return '$whole.$trimmed';
}

/// Parses what the user typed into a stored amount, or null if it isn't a
/// valid non-negative number. Accepts a comma as the decimal separator.
/// With scale 1 only whole numbers are valid.
int? parseScaledAmount(String input, int scale) {
  final text = input.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;

  if (scale <= 1) {
    final whole = int.tryParse(text);
    if (whole == null || whole < 0 || whole > _maxWhole) return null;
    return whole;
  }

  final parsed = double.tryParse(text);
  if (parsed == null || !parsed.isFinite || parsed < 0 || parsed > _maxWhole) {
    return null;
  }
  return (parsed * scale).round();
}