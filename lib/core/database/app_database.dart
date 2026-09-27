import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/habits_table.dart';
import 'tables/completions_table.dart';
import 'tables/categories_table.dart';
import 'tables/reminders_table.dart';

part 'app_database.g.dart';

/// The single local SQLite database for the app. Everything is local-first —
/// no backend, no account required (see PROJECT_PLAN.md).
///
/// Run code generation after editing any table:
///   dart run build_runner build --delete-conflicting-outputs
@DriftDatabase(
  tables: [Habits, Completions, Categories, HabitCategories, Reminders],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Bump this and add a MigrationStrategy step whenever a table changes
  // shape after the app has shipped.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'habit_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
