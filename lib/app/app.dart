import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_settings_provider.dart';

class HabitTrackerApp extends ConsumerWidget {
  /// The router to run. main() supplies one that starts on onboarding for
  /// first-time users; when omitted (e.g. in tests) it falls back to the
  /// default router that starts on Today.
  final GoRouter? router;

  const HabitTrackerApp({super.key, this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);

    return MaterialApp.router(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forPalette(settings.palette, Brightness.light),
      darkTheme: AppTheme.forPalette(settings.palette, Brightness.dark),
      themeMode: settings.mode,
      routerConfig: router ?? appRouter,
    );
  }
}