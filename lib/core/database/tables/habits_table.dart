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

  /// "stepByStep" or "customValue" — see [TrackingMode].
  TextColumn get trackingMode =>
      text().withDefault(const Constant('stepByStep'))();

  /// How many completions/units count as "done" for the day.
  IntColumn get targetPerDay => integer().withDefault(const Constant(1))();

  /// Optional streak goal shown as a milestone (e.g. 30 days).
  IntColumn get streakGoal => integer().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Null while active; set when the habit is archived (not deleted).
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}