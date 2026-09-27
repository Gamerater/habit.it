import '../../features/habits/domain/habit_type.dart';
import 'date_utils.dart';

/// Minimal shape needed to compute a streak, decoupled from the Drift row.
class CompletionEntry {
  final DateTime date;
  final int value;
  final bool isSlip;

  const CompletionEntry({
    required this.date,
    this.value = 1,
    this.isSlip = false,
  });
}

class StreakCalculator {
  /// Returns the current streak length in days, counting backward from
  /// [asOf] (defaults to today).
  ///
  /// - Build habits: consecutive days ending today/asOf with `value` meeting
  ///   [targetPerDay]. A day breaks the streak once it's fully in the past
  ///   with no qualifying completion.
  /// - Quit habits: consecutive clean days. A day with no entry counts as
  ///   clean by default; a day with `isSlip == true` breaks the streak.
  static int currentStreak({
    required HabitType type,
    required List<CompletionEntry> entries,
    required int targetPerDay,
    DateTime? asOf,
  }) {
    final today = asOf ?? DateOnly.today();
    final byDate = {
      for (final e in entries) DateOnly.format(e.date): e,
    };

    var streak = 0;
    var cursor = today;

    while (true) {
      final key = DateOnly.format(cursor);
      final entry = byDate[key];

      final dayCounts = type.isBuild
          ? (entry != null && entry.value >= targetPerDay)
          : (entry == null || !entry.isSlip);

      if (!dayCounts) break;

      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
