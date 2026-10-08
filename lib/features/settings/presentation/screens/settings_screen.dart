import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme_settings_screen.dart';

/// The only "monetization" entry point in the whole app: a link out to
/// support the developer. No paywall, no IAPs — see PROJECT_PLAN.md.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('General'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            title: Text('Daily Check-In Reminders'),
            trailing: Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('Theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
            ),
          ),
          const ListTile(
            title: Text('Archived Habits'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            title: Text('Data Import / Export'),
            trailing: Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('Show Onboarding'),
            trailing: const Icon(Icons.chevron_right),
            // extra: true marks this as a replay, so finishing just closes
            // it instead of re-marking onboarding as completed.
            onTap: () => context.push('/onboarding', extra: true),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.redAccent),
            title: const Text('Support this project ❤️'),
            subtitle: const Text('Everything here is free — a tip helps a lot'),
            onTap: () {
              // TODO: launch GitHub Sponsors / Buy Me a Coffee / Ko-fi URL
              // via url_launcher.
            },
          ),
        ],
      ),
    );
  }
}