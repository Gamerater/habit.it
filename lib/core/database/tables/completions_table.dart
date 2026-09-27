import 'package:drift/drift.dart';
import 'habits_table.dart';

/// One row per (habit, date). For "build" habits, [value] counts progress
/// toward [Habits.targetPerDay]. For "quit" habits, [isSlip] marks a day the
/// user broke the streak; days with no row are treated as clean by default.
@DataClassName('CompletionRow')
class Completions extends Table {
  TextColumn get id => text()();

  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// Stored as a date-only string (yyyy-MM-dd) so equality/lookups are exact
  /// regardless of time-of-day or timezone drift.
  TextColumn get date => text()();

  IntColumn get value => integer().withDefault(const Constant(1))();

  BoolColumn get isSlip => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, date},
      ];
}