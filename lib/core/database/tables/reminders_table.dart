import 'package:drift/drift.dart';
import 'habits_table.dart';

/// A habit can have multiple reminders (this app doesn't gate that behind
/// a paywall — see PROJECT_PLAN.md, Monetization Policy).
class Reminders extends Table {
  TextColumn get id => text()();

  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// Minutes since midnight, e.g. 8:30am = 510. Avoids timezone/DateTime
  /// ambiguity for a purely local "time of day" value.
  IntColumn get minuteOfDay => integer()();

  /// Bitmask, Monday = bit 0 ... Sunday = bit 6. 127 = every day.
  IntColumn get daysOfWeekMask => integer().withDefault(const Constant(127))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
