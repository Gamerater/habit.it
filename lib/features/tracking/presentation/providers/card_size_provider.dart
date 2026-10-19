import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How much each habit card on the Today screen shows.
enum HabitCardSize {
  /// A compact row: name, streak, and a one-week strip. Fits the most habits.
  small,

  /// The standard card: description, a heatmap of recent weeks, and a
  /// one-line streak / last-7-days footer.
  medium,

  /// Everything: larger heatmap with month labels, category tags, and a
  /// stats row.
  large;

  String get label {
    switch (this) {
      case HabitCardSize.small:
        return 'Small';
      case HabitCardSize.medium:
        return 'Medium';
      case HabitCardSize.large:
        return 'Large';
    }
  }

  String get description {
    switch (this) {
      case HabitCardSize.small:
        return 'Name, streak, last 7 days';
      case HabitCardSize.medium:
        return 'Heatmap and streak';
      case HabitCardSize.large:
        return 'Full detail and stats';
    }
  }

  IconData get icon {
    switch (this) {
      case HabitCardSize.small:
        return Icons.density_small;
      case HabitCardSize.medium:
        return Icons.density_medium;
      case HabitCardSize.large:
        return Icons.density_large;
    }
  }

  static HabitCardSize fromName(String? name) {
    return HabitCardSize.values.firstWhere(
      (s) => s.name == name,
      orElse: () => HabitCardSize.medium,
    );
  }
}

/// Remembers the chosen card size across launches.
class CardSizeStorage {
  static const _key = 'today_card_size';

  /// Falls back to medium if the saved value can't be read, so a storage
  /// hiccup can never stop the Today screen from showing.
  static Future<HabitCardSize> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return HabitCardSize.fromName(prefs.getString(_key));
    } catch (_) {
      return HabitCardSize.medium;
    }
  }

  static Future<void> save(HabitCardSize size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, size.name);
    } catch (_) {
      // Non-fatal: the choice just won't survive a restart.
    }
  }
}

/// The size saved on this device. main() reads it before the first frame and
/// overrides this, so the Today screen starts at the right size instead of
/// flashing the default and then jumping to the saved one.
final initialCardSizeProvider = Provider<HabitCardSize>((ref) => HabitCardSize.medium);

class CardSizeNotifier extends StateNotifier<HabitCardSize> {
  CardSizeNotifier(HabitCardSize initial) : super(initial);

  Future<void> setSize(HabitCardSize size) async {
    if (size == state) return;
    state = size;
    await CardSizeStorage.save(size);
  }
}

final cardSizeProvider = StateNotifierProvider<CardSizeNotifier, HabitCardSize>(
  (ref) => CardSizeNotifier(ref.read(initialCardSizeProvider)),
);