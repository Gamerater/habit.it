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

/// How a habit's daily completion is tracked.
enum TrackingMode {
  /// Each tap increments by 1 until [Habit.targetPerDay] is reached.
  stepByStep,

  /// The user enters an arbitrary numeric value for the day
  /// (e.g. "8 glasses of water").
  customValue;
}
