import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_palette.dart';

class ThemeSettings {
  final AppThemePalette palette;
  final ThemeMode mode;

  const ThemeSettings({
    this.palette = AppThemePalette.defaultTheme,
    this.mode = ThemeMode.system,
  });

  ThemeSettings copyWith({AppThemePalette? palette, ThemeMode? mode}) {
    return ThemeSettings(
      palette: palette ?? this.palette,
      mode: mode ?? this.mode,
    );
  }
}

class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  static const _paletteKey = 'theme_palette';
  static const _modeKey = 'theme_mode';

  ThemeSettingsNotifier() : super(const ThemeSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final paletteName = prefs.getString(_paletteKey);
    final modeName = prefs.getString(_modeKey);

    state = ThemeSettings(
      palette: AppThemePalette.values.firstWhere(
        (p) => p.name == paletteName,
        orElse: () => AppThemePalette.defaultTheme,
      ),
      mode: ThemeMode.values.firstWhere(
        (m) => m.name == modeName,
        orElse: () => ThemeMode.system,
      ),
    );
  }

  Future<void> setPalette(AppThemePalette palette) async {
    state = state.copyWith(palette: palette);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, palette.name);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }
}

final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  (ref) => ThemeSettingsNotifier(),
);