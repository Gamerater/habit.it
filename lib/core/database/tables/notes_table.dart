import 'package:drift/drift.dart';
import 'habits_table.dart';

/// One optional note per (habit, date) — "what went well / what got in the
/// way" style journaling, added by long-pressing a day in the habit detail
/// calendar.
@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();

  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// Date-only string (yyyy-MM-dd), same convention as Completions.date.
  TextColumn get date => text()();

  TextColumn get content => text()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, date},
      ];
}