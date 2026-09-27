/// Small helpers for working with date-only values, since completions are
/// keyed by calendar day rather than a precise DateTime.
class DateOnly {
  /// Normalizes to yyyy-MM-dd, stripping time-of-day and timezone.
  static String format(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime parse(String yyyyMMdd) {
    final parts = yyyyMMdd.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Inclusive list of dates from [start] to [end].
  static List<DateTime> range(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(last)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }
}
