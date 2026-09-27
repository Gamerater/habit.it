import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/date_utils.dart';
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

/// Live completions for one habit — used to compute streaks and render the
/// mini heatmap without re-fetching on every rebuild.
final habitCompletionsProvider =
    StreamProvider.family<List<CompletionRow>, String>((ref, habitId) {
  return ref.watch(habitRepositoryProvider).watchCompletions(habitId);
});

/// Today's completion state for every habit at once, keyed by habit id —
/// what the Today screen's check circles read from.
final todayCompletionsProvider =
    StreamProvider<Map<String, CompletionRow>>((ref) {
  return ref
      .watch(habitRepositoryProvider)
      .watchCompletionsForDate(DateOnly.today());
});