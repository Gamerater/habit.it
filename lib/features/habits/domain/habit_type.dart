/// The two first-class habit types this app supports.
///
/// [build] habits start "unmarked" each day and you check them off when done.
/// [quit] habits start "completed" by default (streak-friendly) and you only
/// mark a day when you slip, so the streak represents consecutive clean days.
enum HabitType {
  build,
  quit;

  bool get isBuild => this == HabitType.build;
  bool get isQuit => this == HabitType.quit;
}

/// What a build habit's daily progress is measured in.
///
/// Quit habits are always [yesNo] — they're tracked by marking slips.
enum TrackingMethod {
  /// Done or not done.
  yesNo,

  /// A whole-number count toward a daily goal (e.g. 8 glasses).
  count,

  /// An amount with a unit toward a daily goal (e.g. 2.5 L, 5 km).
  measure;

  /// Parses the value stored in the database, falling back to [yesNo] for
  /// anything unrecognized (including rows from before this column existed).
  static TrackingMethod fromName(String? name) {
    return TrackingMethod.values.firstWhere(
      (m) => m.name == name,
      orElse: () => TrackingMethod.yesNo,
    );
  }

  String get label {
    switch (this) {
      case TrackingMethod.yesNo:
        return 'Yes / No';
      case TrackingMethod.count:
        return 'Count';
      case TrackingMethod.measure:
        return 'Measure';
    }
  }

  String get description {
    switch (this) {
      case TrackingMethod.yesNo:
        return 'Mark each day done or not done.';
      case TrackingMethod.count:
        return 'Count toward a daily goal, like 8 glasses of water.';
      case TrackingMethod.measure:
        return 'Log amounts with a unit, like 2 L of water or 5 km.';
    }
  }
}

/// What happens when you tap a Count or Measure habit's button.
///
/// (Persisted in the existing `trackingMode` column, whose original
/// "stepByStep" / "customValue" names are kept so older data still reads.)
enum TrackingMode {
  /// Each tap adds a fixed amount (the habit's tap increment).
  stepByStep,

  /// Each tap opens a dialog to enter the day's total.
  customValue;

  String get label {
    switch (this) {
      case TrackingMode.stepByStep:
        return 'Add an amount';
      case TrackingMode.customValue:
        return 'Enter total';
    }
  }
}