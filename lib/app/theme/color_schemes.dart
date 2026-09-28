import 'package:flutter/material.dart';

/// Hand-picked color tokens — deliberately NOT ColorScheme.fromSeed(), which
/// auto-generates the washed-out pastel "every Flutter app" look. Every
/// value here is chosen, not algorithmically derived.
///
/// Roles:
/// - teal: navigation, success/done states, structural UI
/// - coral: the one "action" accent — used sparingly (the add button,
///   streak highlights) so it actually stands out instead of being one of
///   many same-weight colors
class AppColors {
  static const Color teal = Color(0xFF0F8A78);
  static const Color tealDark = Color(0xFF0B6D5F);
  static const Color coral = Color(0xFFFF6A4D);

  // Light mode
  static const Color paper = Color(0xFFFAF8F4); // warm, not minty
  static const Color paperElevated = Color(0xFFF1ECE3);
  static const Color inkLight = Color(0xFF1B1B18);
  static const Color mutedLight = Color(0xFF6B6459);

  // Dark mode
  static const Color night = Color(0xFF15181A);
  static const Color nightElevated = Color(0xFF1E2225);
  static const Color inkDark = Color(0xFFEDEEEC);
  static const Color mutedDark = Color(0xFF9B9C96);
}

final ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.teal,
  onPrimary: Colors.white,
  primaryContainer: AppColors.teal.withValues(alpha: 0.14),
  onPrimaryContainer: AppColors.tealDark,
  secondary: AppColors.coral,
  onSecondary: Colors.white,
  secondaryContainer: AppColors.coral.withValues(alpha: 0.16),
  onSecondaryContainer: AppColors.coral,
  surface: AppColors.paper,
  onSurface: AppColors.inkLight,
  surfaceContainerHigh: AppColors.paperElevated,
  surfaceContainerHighest: AppColors.paperElevated,
  onSurfaceVariant: AppColors.mutedLight,
  outline: const Color(0xFFDAD3C6),
  outlineVariant: const Color(0xFFE7E1D6),
  error: const Color(0xFFD14343),
  onError: Colors.white,
);

final ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xFF3FBFA8),
  onPrimary: const Color(0xFF00332B),
  primaryContainer: AppColors.teal.withValues(alpha: 0.22),
  onPrimaryContainer: const Color(0xFF7EE0CB),
  secondary: AppColors.coral,
  onSecondary: Colors.white,
  secondaryContainer: AppColors.coral.withValues(alpha: 0.2),
  onSecondaryContainer: const Color(0xFFFFAF9C),
  surface: AppColors.night,
  onSurface: AppColors.inkDark,
  surfaceContainerHigh: AppColors.nightElevated,
  surfaceContainerHighest: AppColors.nightElevated,
  onSurfaceVariant: AppColors.mutedDark,
  outline: const Color(0xFF35393C),
  outlineVariant: const Color(0xFF2A2E31),
  error: const Color(0xFFE57373),
  onError: Colors.black,
);