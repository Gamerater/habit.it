import 'package:drift/drift.dart';

/// Persisted habit type as a plain string so the DB stays human-readable
/// and future-proof (no reliance on enum index ordering).
///
/// @DataClassName gives the generated row class an explicit name
/// (HabitRow) so it never collides with our own domain `Habit` model
/// in features/habits/domain/habit.dart.
@DataClassName('HabitRow')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get description => text().nullable()();

  /// Either an icon identifier (from our bundled icon set) or a raw emoji.
  TextColumn get icon => text()();

  /// Hex color, e.g. "#4F86F7".
  TextColumn get color => text()();

  /// "build" or "quit" — see [HabitType].
  TextColumn get type => text()();

  /// "yesNo", "count" or "measure" — see TrackingMethod. Existing rows get
  /// "yesNo" from the migration default, which is exactly how they behaved.
  TextColumn get trackingMethod =>
      text().withDefault(const Constant('yesNo'))();

  /// What a tap does for Count/Measure habits: "stepByStep" (add a fixed
  /// amount) or "customValue" (enter the day's total) — see TrackingMode.
  TextColumn get trackingMode =>
      text().withDefault(const Constant('stepByStep'))();

  /// The daily goal in stored units: a plain count for Count habits,
  /// thousandths for Measure habits (see domain/amount_format.dart).
  IntColumn get targetPerDay => integer().withDefault(const Constant(1))();

  /// Amount added per tap in "stepByStep" mode, in the same stored units.
  IntColumn get tapIncrement => integer().withDefault(const Constant(1))();

  /// Unit label for Count/Measure habits, e.g. "L", "km", "glasses".
  TextColumn get unit => text().nullable()();

  /// Optional streak goal shown as a milestone (e.g. 30 days).
  IntColumn get streakGoal => integer().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Null while active; set when the habit is archived (not deleted).
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}