import 'package:flutter/material.dart';

/// Deliberately different accent identity from typical habit-tracker purples:
/// a teal primary with a warm coral secondary/accent. Swap these freely —
/// they're centralized here so re-theming the whole app is a one-file change.
class AppColors {
  static const Color primary = Color(0xFF16A394); // teal
  static const Color secondary = Color(0xFFFF7A59); // coral
  static const Color surfaceDark = Color(0xFF121417);
  static const Color surfaceLight = Color(0xFFFAFAF9);
}

final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.light,
).copyWith(secondary: AppColors.secondary);

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.dark,
).copyWith(secondary: AppColors.secondary);
