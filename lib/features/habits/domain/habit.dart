import 'habit_type.dart';

/// Plain domain model the UI works with. Kept separate from the generated
/// Drift row class so the presentation layer never depends on codegen types.
class Habit {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final HabitType type;
  final TrackingMode trackingMode;
  final int targetPerDay;
  final int? streakGoal;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? archivedAt;
  final List<String> categoryIds;

  const Habit({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    required this.type,
    this.trackingMode = TrackingMode.stepByStep,
    this.targetPerDay = 1,
    this.streakGoal,
    this.sortOrder = 0,
    required this.createdAt,
    this.archivedAt,
    this.categoryIds = const [],
  });

  bool get isArchived => archivedAt != null;

  Habit copyWith({
    String? name,
    String? description,
    String? icon,
    String? color,
    HabitType? type,
    TrackingMode? trackingMode,
    int? targetPerDay,
    int? streakGoal,
    int? sortOrder,
    DateTime? archivedAt,
    List<String>? categoryIds,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      trackingMode: trackingMode ?? this.trackingMode,
      targetPerDay: targetPerDay ?? this.targetPerDay,
      streakGoal: streakGoal ?? this.streakGoal,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }
}
