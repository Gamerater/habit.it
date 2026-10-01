import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/habits_table.dart';
import 'tables/completions_table.dart';
import 'tables/categories_table.dart';
import 'tables/reminders_table.dart';
import 'tables/notes_table.dart';

part 'app_database.g.dart';

/// The single local SQLite database for the app. Everything is local-first —
/// no backend, no account required (see PROJECT_PLAN.md).
///
/// Run code generation after editing any table:
///   dart run build_runner build --delete-conflicting-outputs
@DriftDatabase(
  tables: [Habits, Completions, Categories, HabitCategories, Reminders, Notes],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Bump this and add a migration step whenever a table changes shape after
  // the app has real user data — onCreate alone only covers fresh installs.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(notes);
          }
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