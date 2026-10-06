/// The available color palettes. Each has its own light and dark
/// ColorScheme — see color_schemes.dart.
enum AppThemePalette {
  defaultTheme,
  luxEmerald;

  String get label {
    switch (this) {
      case AppThemePalette.defaultTheme:
        return 'Current Theme';
      case AppThemePalette.luxEmerald:
        return 'Emerald & Slate (Lux)';
    }
  }

  String get description {
    switch (this) {
      case AppThemePalette.defaultTheme:
        return 'Teal & coral — the app\'s original look';
      case AppThemePalette.luxEmerald:
        return 'Muted emerald, soft sage, and amber bronze';
    }
  }
}