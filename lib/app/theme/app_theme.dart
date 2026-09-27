import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_schemes.dart';

/// Type identity: Sora for display/headline text (a geometric sans with
/// more personality — used for titles, streak numbers, big moments) and
/// Inter for body/UI text (quiet, highly legible, disappears into the
/// background). Two clearly distinct families rather than one default.
class AppTheme {
  static ThemeData get light => _build(lightColorScheme);
  static ThemeData get dark => _build(darkColorScheme);

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    final displayFont = GoogleFonts.sora();
    final bodyFont = GoogleFonts.inter();

    final displayStyled = base.textTheme
        .copyWith(
          displayLarge: displayFont.copyWith(fontWeight: FontWeight.w700),
          displayMedium: displayFont.copyWith(fontWeight: FontWeight.w700),
          headlineLarge: displayFont.copyWith(fontWeight: FontWeight.w700),
          headlineMedium: displayFont.copyWith(fontWeight: FontWeight.w600),
          headlineSmall: displayFont.copyWith(fontWeight: FontWeight.w600),
          titleLarge: displayFont.copyWith(fontWeight: FontWeight.w600),
          titleMedium: displayFont.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final bodyTextTheme = GoogleFonts.interTextTheme(base.textTheme);

    final mergedTextTheme = bodyTextTheme.copyWith(
      displayLarge: displayStyled.displayLarge,
      displayMedium: displayStyled.displayMedium,
      headlineLarge: displayStyled.headlineLarge,
      headlineMedium: displayStyled.headlineMedium,
      headlineSmall: displayStyled.headlineSmall,
      titleLarge: displayStyled.titleLarge,
      titleMedium: displayStyled.titleMedium,
    );

    return base.copyWith(
      textTheme: mergedTextTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: displayFont.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: bodyFont.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
      ),
    );
  }
}