import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../categories/domain/category.dart';
import '../domain/habit.dart';
import '../domain/habit_type.dart';

const _uuid = Uuid();

class HabitRepository {
  final AppDatabase _db;

  HabitRepository(this._db);

  /// Live stream of active (non-archived) habits, ordered for display.
  Stream<List<Habit>> watchActiveHabits() => _watchHabitsWithCategories(archived: false);

  Stream<List<Habit>> watchArchivedHabits() => _watchHabitsWithCategories(archived: true);

  /// Combines the habits table and the habit<->category join table into one
  /// reactive stream that re-emits when EITHER changes.
  ///
  /// This matters because a plain `select(habits).watch()` only tracks the
  /// `habits` table — Drift determines reactivity from the query's own SQL,
  /// and a separate category lookup done inside the stream's callback is
  /// invisible to it. That was the bug: editing a habit's categories only
  /// writes to `habit_categories`, never to `habits`, so nothing told the
  /// old stream to refresh. Listening to both tables directly and
  /// recombining on every emission from either fixes it properly.
  Stream<List<Habit>> _watchHabitsWithCategories({required bool archived}) {
    late final StreamController<List<Habit>> controller;
    StreamSubscription<List<HabitRow>>? habitsSub;
    StreamSubscription<List<HabitCategoryLink>>? linksSub;

    List<HabitRow>? latestHabits;
    List<HabitCategoryLink>? latestLinks;

    void emit() {
      final habits = latestHabits;
      final links = latestLinks;
      if (habits == null || links == null) return;

      final categoryIdsByHabit = <String, List<String>>{};
      for (final link in links) {
        categoryIdsByHabit.putIfAbsent(link.habitId, () => []).add(link.categoryId);
      }

      controller.add([
        for (final row in habits)
          Habit(
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
            categoryIds: categoryIdsByHabit[row.id] ?? const [],
          ),
      ]);
    }

    controller = StreamController<List<Habit>>.broadcast(
      onListen: () {
        final habitsQuery = _db.select(_db.habits)
          ..where((h) => archived ? h.archivedAt.isNotNull() : h.archivedAt.isNull())
          ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]);

        habitsSub = habitsQuery.watch().listen((rows) {
          latestHabits = rows;
          emit();
        });
        linksSub = _db.select(_db.habitCategories).watch().listen((rows) {
          latestLinks = rows;
          emit();
        });
      },
      onCancel: () {
        habitsSub?.cancel();
        linksSub?.cancel();
      },
    );

    return controller.stream;
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

  /// Updates an existing habit's fields in place. Categories are replaced
  /// wholesale via [setHabitCategories] rather than diffed, since the picker
  /// always returns the full final selection.
  Future<void> updateHabit({
    required String id,
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
    await (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        name: Value(name),
        description: Value(description),
        icon: Value(icon),
        color: Value(color),
        type: Value(type.isQuit ? 'quit' : 'build'),
        trackingMode: Value(
          trackingMode == TrackingMode.customValue ? 'customValue' : 'stepByStep',
        ),
        targetPerDay: Value(targetPerDay),
        streakGoal: Value(streakGoal),
      ),
    );
    await setHabitCategories(id, categoryIds);
  }

  /// Persists a new manual order after a drag-to-reorder — [orderedIds] is
  /// the full list of active habit ids in their new display order.
  Future<void> reorderHabits(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await (_db.update(_db.habits)..where((h) => h.id.equals(orderedIds[i])))
          .write(HabitsCompanion(sortOrder: Value(i)));
    }
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

  /// Toggles today's (or any [date]'s) state with one tap, matching what the
  /// big check-circle in the UI needs:
  /// - Build habit: not done -> done (value = targetPerDay); done -> undone
  ///   (row removed, so the day goes back to "not completed").
  /// - Quit habit: clean -> slipped; slipped -> clean again (row removed,
  ///   since "no row" already means clean by default).
  Future<void> toggleToday({required Habit habit, required DateTime date}) async {
    final dateKey = DateOnly.format(date);
    final existing = await (_db.select(_db.completions)
          ..where((c) => c.habitId.equals(habit.id) & c.date.equals(dateKey)))
        .getSingleOrNull();

    if (habit.type.isBuild) {
      if (existing != null && existing.value >= habit.targetPerDay) {
        await (_db.delete(_db.completions)..where((c) => c.id.equals(existing.id))).go();
      } else {
        await setCompletion(habitId: habit.id, date: date, value: habit.targetPerDay);
      }
    } else {
      if (existing != null && existing.isSlip) {
        await (_db.delete(_db.completions)..where((c) => c.id.equals(existing.id))).go();
      } else {
        await setCompletion(habitId: habit.id, date: date, isSlip: true, value: 0);
      }
    }
  }

  Stream<List<CompletionRow>> watchCompletions(String habitId) {
    return (_db.select(_db.completions)
          ..where((c) => c.habitId.equals(habitId)))
        .watch();
  }

  /// All completion rows for one calendar day, keyed by habit id — used to
  /// render today's checked/unchecked (or clean/slipped) state for every
  /// habit at once without a separate stream per habit.
  Stream<Map<String, CompletionRow>> watchCompletionsForDate(DateTime date) {
    final dateKey = DateOnly.format(date);
    final query = _db.select(_db.completions)
      ..where((c) => c.date.equals(dateKey));
    return query.watch().map((rows) => {for (final r in rows) r.habitId: r});
  }

  /// Live notes for a habit, keyed by date string — "press and hold a day to
  /// add a note" in the detail screen's calendar.
  Stream<Map<String, NoteRow>> watchNotes(String habitId) {
    final query = _db.select(_db.notes)..where((n) => n.habitId.equals(habitId));
    return query.watch().map((rows) => {for (final r in rows) r.date: r});
  }

  Future<void> setNote({
    required String habitId,
    required DateTime date,
    required String content,
  }) async {
    final dateKey = DateOnly.format(date);
    final existing = await (_db.select(_db.notes)
          ..where((n) => n.habitId.equals(habitId) & n.date.equals(dateKey)))
        .getSingleOrNull();

    if (content.trim().isEmpty) {
      if (existing != null) {
        await (_db.delete(_db.notes)..where((n) => n.id.equals(existing.id))).go();
      }
      return;
    }

    if (existing == null) {
      await _db.into(_db.notes).insert(
            NotesCompanion.insert(
              id: _uuid.v4(),
              habitId: habitId,
              date: dateKey,
              content: content.trim(),
            ),
          );
    } else {
      await (_db.update(_db.notes)..where((n) => n.id.equals(existing.id))).write(
        NotesCompanion(
          content: Value(content.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  // --- Categories -----------------------------------------------------

  Stream<List<Category>> watchCategories() {
    final query = _db.select(_db.categories)
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.watch().map(
          (List<CategoryRow> rows) => [
            for (final r in rows)
              Category(id: r.id, name: r.name, icon: r.icon, color: r.color),
          ],
        );
  }

  Future<String> createCategory({
    required String name,
    required String icon,
    required String color,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(id: id, name: name, icon: icon, color: color),
        );
    return id;
  }

  Future<void> deleteCategory(String categoryId) async {
    await (_db.delete(_db.categories)..where((c) => c.id.equals(categoryId))).go();
  }

  /// Replaces a habit's full set of category assignments with [categoryIds].
  Future<void> setHabitCategories(String habitId, List<String> categoryIds) async {
    await (_db.delete(_db.habitCategories)..where((hc) => hc.habitId.equals(habitId))).go();
    for (final categoryId in categoryIds) {
      await _db.into(_db.habitCategories).insert(
            HabitCategoriesCompanion.insert(habitId: habitId, categoryId: categoryId),
          );
    }
  }
}