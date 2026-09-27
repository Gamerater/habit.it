import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/habit.dart';
import '../domain/habit_type.dart';

const _uuid = Uuid();

class HabitRepository {
  final AppDatabase _db;

  HabitRepository(this._db);

  /// Live stream of active (non-archived) habits, ordered for display.
  Stream<List<Habit>> watchActiveHabits() {
    final query = _db.select(_db.habits)
      ..where((h) => h.archivedAt.isNull())
      ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]);

    return query.watch().asyncMap((rows) async {
      final habits = <Habit>[];
      for (final row in rows) {
        habits.add(await _toDomain(row));
      }
      return habits;
    });
  }

  Stream<List<Habit>> watchArchivedHabits() {
    final query = _db.select(_db.habits)
      ..where((h) => h.archivedAt.isNotNull())
      ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]);

    return query.watch().asyncMap((rows) async {
      final habits = <Habit>[];
      for (final row in rows) {
        habits.add(await _toDomain(row));
      }
      return habits;
    });
  }

  Future<Habit> _toDomain(HabitRow row) async {
    final links = await (_db.select(_db.habitCategories)
          ..where((c) => c.habitId.equals(row.id)))
        .get();

    return Habit(
      id: row.id,
      name: row.name,
      description: row.description,
      icon: row.icon,
      color: row.color,
      type: row.type == 'quit' ? HabitType.quit : HabitType.build,
      trackingMode: row.trackingMode == 'customValue'
          ? TrackingMode.customValue
          : TrackingMode.stepByStep,
      targetPerDay: row.targetPerDay,
      streakGoal: row.streakGoal,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      archivedAt: row.archivedAt,
      categoryIds: links.map((l) => l.categoryId).toList(),
    );
  }

  Future<String> createHabit({
    required String name,
    String? description,
    required String icon,
    required String color,
    required HabitType type,
    TrackingMode trackingMode = TrackingMode.stepByStep,
    int targetPerDay = 1,
    int? streakGoal,
    List<String> categoryIds = const [],
  }) async {
    final id = _uuid.v4();

    await _db.into(_db.habits).insert(
          HabitsCompanion.insert(
            id: id,
            name: name,
            description: Value(description),
            icon: icon,
            color: color,
            type: type.isQuit ? 'quit' : 'build',
            trackingMode: Value(
              trackingMode == TrackingMode.customValue
                  ? 'customValue'
                  : 'stepByStep',
            ),
            targetPerDay: Value(targetPerDay),
            streakGoal: Value(streakGoal),
          ),
        );

    for (final categoryId in categoryIds) {
      await _db.into(_db.habitCategories).insert(
            HabitCategoriesCompanion.insert(
              habitId: id,
              categoryId: categoryId,
            ),
          );
    }

    return id;
  }

  Future<void> archiveHabit(String habitId, {bool archived = true}) async {
    await (_db.update(_db.habits)..where((h) => h.id.equals(habitId))).write(
      HabitsCompanion(
        archivedAt: Value(archived ? DateTime.now() : null),
      ),
    );
  }

  Future<void> deleteHabit(String habitId) async {
    await (_db.delete(_db.habits)..where((h) => h.id.equals(habitId))).go();
  }

  /// Marks (or updates) today's — or any given day's — completion for a habit.
  Future<void> setCompletion({
    required String habitId,
    required DateTime date,
    int value = 1,
    bool isSlip = false,
  }) async {
    final dateKey = DateOnly.format(date);
    final existing = await (_db.select(_db.completions)
          ..where((c) => c.habitId.equals(habitId) & c.date.equals(dateKey)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.completions).insert(
            CompletionsCompanion.insert(
              id: _uuid.v4(),
              habitId: habitId,
              date: dateKey,
              value: Value(value),
              isSlip: Value(isSlip),
            ),
          );
    } else {
      await (_db.update(_db.completions)..where((c) => c.id.equals(existing.id)))
          .write(
        CompletionsCompanion(
          value: Value(value),
          isSlip: Value(isSlip),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Stream<List<CompletionRow>> watchCompletions(String habitId) {
    return (_db.select(_db.completions)
          ..where((c) => c.habitId.equals(habitId)))
        .watch();
  }
}