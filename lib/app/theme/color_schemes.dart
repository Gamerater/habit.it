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
  tertiary: AppColors.coral,
  onTertiary: Colors.white,
  tertiaryContainer: AppColors.coral.withValues(alpha: 0.16),
  onTertiaryContainer: AppColors.coral,
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
  tertiary: AppColors.coral,
  onTertiary: Colors.white,
  tertiaryContainer: AppColors.coral.withValues(alpha: 0.2),
  onTertiaryContainer: const Color(0xFFFFAF9C),
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

/// --- Lux Emerald ("Emerald & Slate") -----------------------------------
///
/// Role mapping, since the spec names "Tertiary / Brand Accent" for what
/// plays the same job the Default theme gives to `secondary` (the FAB /
/// one-pop-of-color accent): Amber Bronze is used for BOTH `secondary` and
/// `tertiary` here, so existing code that reads `colorScheme.secondary`
/// (FAB, etc.) and new code that explicitly reads `colorScheme.tertiary`
/// (streak/milestone icons, per the styling rules) land on the same color
/// without needing per-palette branching elsewhere.
class LuxColors {
  static const Color emeraldLight = Color(0xFF2D6A4F);
  static const Color emeraldLightPressed = Color(0xFF1F4D39);
  static const Color sageContainer = Color(0xFFD8F3DC);
  static const Color amberBronze = Color(0xFFB57333);

  static const Color creamSilk = Color(0xFFF9F8F6);
  static const Color pureLinen = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color dividerLight = Color(0xFFE2E8F0);

  static const Color emeraldDark = Color(0xFF52B788);
  static const Color emeraldDarkOn = Color(0xFF0B2A1E);
  static const Color emeraldGlowContainer = Color(0xFF1B4332);
  static const Color brightAmber = Color(0xFFE5984A);
  static const Color brightAmberOn = Color(0xFF2B1800);

  static const Color deepObsidian = Color(0xFF0F1115);
  static const Color charcoalSlate = Color(0xFF1A1D24);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color dividerDark = Color(0xFF2E323D);
}

final ColorScheme luxEmeraldLightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: LuxColors.emeraldLight,
  onPrimary: Colors.white,
  primaryContainer: LuxColors.emeraldLight.withValues(alpha: 0.14),
  onPrimaryContainer: LuxColors.emeraldLightPressed,
  secondary: LuxColors.amberBronze,
  onSecondary: Colors.white,
  secondaryContainer: LuxColors.sageContainer,
  onSecondaryContainer: LuxColors.textPrimaryLight,
  tertiary: LuxColors.amberBronze,
  onTertiary: Colors.white,
  tertiaryContainer: LuxColors.amberBronze.withValues(alpha: 0.16),
  onTertiaryContainer: LuxColors.amberBronze,
  surface: LuxColors.creamSilk,
  onSurface: LuxColors.textPrimaryLight,
  surfaceContainerHigh: LuxColors.pureLinen,
  surfaceContainerHighest: LuxColors.pureLinen,
  onSurfaceVariant: LuxColors.textSecondaryLight,
  outline: LuxColors.dividerLight,
  outlineVariant: LuxColors.dividerLight,
  error: const Color(0xFFD14343),
  onError: Colors.white,
);

final ColorScheme luxEmeraldDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: LuxColors.emeraldDark,
  onPrimary: LuxColors.emeraldDarkOn,
  primaryContainer: LuxColors.emeraldDark.withValues(alpha: 0.22),
  onPrimaryContainer: const Color(0xFFA8E0C5),
  secondary: LuxColors.brightAmber,
  onSecondary: LuxColors.brightAmberOn,
  secondaryContainer: LuxColors.emeraldGlowContainer,
  onSecondaryContainer: LuxColors.textPrimaryDark,
  tertiary: LuxColors.brightAmber,
  onTertiary: LuxColors.brightAmberOn,
  tertiaryContainer: LuxColors.brightAmber.withValues(alpha: 0.2),
  onTertiaryContainer: const Color(0xFFFFD9AC),
  surface: LuxColors.deepObsidian,
  onSurface: LuxColors.textPrimaryDark,
  surfaceContainerHigh: LuxColors.charcoalSlate,
  surfaceContainerHighest: LuxColors.charcoalSlate,
  onSurfaceVariant: LuxColors.textSecondaryDark,
  outline: LuxColors.dividerDark,
  outlineVariant: LuxColors.dividerDark,
  error: const Color(0xFFE57373),
  onError: Colors.black,
);