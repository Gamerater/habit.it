import 'amount_format.dart';
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

  /// Yes/No, Count, or Measure. Only build habits use anything but yes/no.
  final TrackingMethod trackingMethod;

  /// For Count/Measure habits, what tapping the button does.
  final TrackingMode trackingMode;

  /// The daily goal, in stored units (see amount_format.dart): a plain count
  /// for Count habits, thousandths for Measure habits. Always 1 for yes/no.
  final int targetPerDay;

  /// Amount added per tap in [TrackingMode.stepByStep], in stored units.
  final int tapIncrement;

  /// Unit label for Count/Measure habits, e.g. "L", "km", "glasses".
  final String? unit;

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
    this.trackingMethod = TrackingMethod.yesNo,
    this.trackingMode = TrackingMode.stepByStep,
    this.targetPerDay = 1,
    this.tapIncrement = 1,
    this.unit,
    this.streakGoal,
    this.sortOrder = 0,
    required this.createdAt,
    this.archivedAt,
    this.categoryIds = const [],
  });

  bool get isArchived => archivedAt != null;

  /// True for build habits tracked by Count or Measure — the ones that log
  /// amounts toward a goal rather than a simple done/not-done.
  bool get tracksAmount => type.isBuild && trackingMethod != TrackingMethod.yesNo;

  /// How many stored units make up one displayed unit (1 for counts, 1000
  /// for measures).
  int get valueScale => trackingMethod == TrackingMethod.measure ? measureScale : 1;

  /// Formats a stored amount for display, without the unit.
  String formatAmount(int scaled) => formatScaledAmount(scaled, valueScale);

  /// The unit, trimmed; empty when none was set.
  String get unitLabel => (unit ?? '').trim();

  /// A stored amount with its unit, e.g. "2.5 L" or "3 glasses".
  String formatAmountWithUnit(int scaled) {
    final amount = formatAmount(scaled);
    return unitLabel.isEmpty ? amount : '$amount $unitLabel';
  }

  Habit copyWith({
    String? name,
    String? description,
    String? icon,
    String? color,
    HabitType? type,
    TrackingMethod? trackingMethod,
    TrackingMode? trackingMode,
    int? targetPerDay,
    int? tapIncrement,
    String? unit,
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
      trackingMethod: trackingMethod ?? this.trackingMethod,
      trackingMode: trackingMode ?? this.trackingMode,
      targetPerDay: targetPerDay ?? this.targetPerDay,
      tapIncrement: tapIncrement ?? this.tapIncrement,
      unit: unit ?? this.unit,
      streakGoal: streakGoal ?? this.streakGoal,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }
}