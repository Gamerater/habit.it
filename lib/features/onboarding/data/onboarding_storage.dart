import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the user has already seen onboarding, so it only
/// auto-shows on first launch. (Settings > Show Onboarding can replay it
/// any time without touching this flag.)
class OnboardingStorage {
  static const _completedKey = 'onboarding_completed';

  /// If storage can't be read for any reason, treat onboarding as completed —
  /// failing to remember a preference should never trap someone in a
  /// first-run screen on every launch.
  static Future<bool> isCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_completedKey) ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedKey, true);
    } catch (_) {
      // Non-fatal: worst case the user sees onboarding once more.
    }
  }
}