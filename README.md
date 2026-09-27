# Habit.It

A habit tracker app inspired by HabitKit.

Inspired by the general concept of build/quit habit tracking with a visual streak grid (as popularized by apps like HabitKit), independently designed and built from scratch. **No paywall, no subscriptions, no in-app purchases** — every feature is free. The only monetization surface is an optional "Support this project" link in Settings.

## Tech stack

- Flutter (iOS + Android from one codebase)
- Riverpod — state management
- Drift (SQLite) — local, offline-first database
- go_router — navigation
- flutter_local_notifications — reminders
- home_widget — home screen widgets
- fl_chart — insights/charts

## Getting started

> This scaffold contains the Dart/Flutter source only — no `ios/`, `android/`, `web/` platform folders (those are large, machine-generated, and best created fresh on your machine).

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel).
2. Generate the platform folders by running `flutter create .` **from inside this project's root folder** (the one with `pubspec.yaml`). This adds `ios/`, `android/`, etc. without touching the `lib/` folder already here — say yes if it asks to overwrite anything only if you're unsure, but it shouldn't need to touch `lib/`.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate Drift's database code (required — `app_database.g.dart` is not checked in):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Project structure

Feature-first: each feature (habits, tracking, insights, settings, categories) has its own `data/`, `domain/`, and `presentation/` folders under `lib/features/`. Shared code (database, utils, shared widgets) lives under `lib/core/`. See `PROJECT_PLAN.md` section 3 for the full layout and rationale.

## Current status

This is an early scaffold: the data layer (Drift tables + repository + streak calculator) and basic navigation shell (Today / Habits / Insights / Settings) are in place, with a minimal working "add habit" + "check off today" flow. Icon/emoji picker, reminders, categories, charts, widgets, and import/export are stubbed as next steps — see the roadmap in `PROJECT_PLAN.md`.

## Contributing

Issues and PRs welcome once this hits a public repo. Please open an issue before large changes so I can align on direction first.

## License

This projects is under an MIT license so anyone is free to use it.
