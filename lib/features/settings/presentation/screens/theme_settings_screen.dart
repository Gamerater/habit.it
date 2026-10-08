import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme_palette.dart';
import '../../../../app/theme/theme_settings_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Theme', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppThemePalette>(
                value: settings.palette,
                isExpanded: true,
                // Each item has two lines (title + description), taller
                // than the default fixed 48px item height DropdownButton
                // normally enforces - null lets each item size naturally.
                itemHeight: null,
                items: [
                  for (final palette in AppThemePalette.values)
                    DropdownMenuItem(
                      value: palette,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(palette.label, style: theme.textTheme.bodyMedium),
                            Text(
                              palette.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                onChanged: (palette) {
                  if (palette != null) notifier.setPalette(palette);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Appearance', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ThemeMode>(
                value: settings.mode,
                isExpanded: true,
                itemHeight: null,
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Follow System Settings'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Light Mode'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Dark Mode'),
                    ),
                  ),
                ],
                onChanged: (mode) {
                  if (mode != null) notifier.setMode(mode);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}