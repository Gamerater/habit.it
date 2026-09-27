import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/habit_repository.dart';
import '../../domain/habit.dart';

/// Single shared database instance for the app's lifetime.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(ref.watch(appDatabaseProvider));
});

/// Live list of active habits — rebuilds automatically whenever the
/// underlying table changes (Drift streams are reactive by default).
final activeHabitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitRepositoryProvider).watchActiveHabits();
});

final archivedHabitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitRepositoryProvider).watchArchivedHabits();
});
