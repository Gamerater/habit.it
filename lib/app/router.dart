import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/tracking/presentation/screens/today_screen.dart';
import '../features/habits/presentation/screens/habit_list_screen.dart';
import '../features/habits/presentation/screens/add_edit_habit_screen.dart';
import '../features/habits/presentation/screens/habit_detail_screen.dart';
import '../features/habits/domain/habit.dart';
import '../features/insights/presentation/screens/insights_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'widgets/app_bottom_nav.dart';

/// Builds the app's router. main() passes '/onboarding' as the starting
/// location on first launch and '/today' afterwards. Each call gets its own
/// root navigator key, so the default [appRouter] below can't conflict with
/// the one main() actually runs.
GoRouter createAppRouter({String initialLocation = '/today'}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => _AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/today', builder: (context, state) => const TodayScreen()),
          GoRoute(path: '/habits', builder: (context, state) => const HabitListScreen()),
          GoRoute(
            path: '/insights',
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        // Replays from Settings pass `extra: true` so finishing just closes
        // the screen instead of re-marking onboarding as completed.
        builder: (context, state) => OnboardingScreen(isReplay: state.extra == true),
      ),
      GoRoute(
        path: '/habits/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddEditHabitScreen(),
      ),
      GoRoute(
        path: '/habits/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AddEditHabitScreen(existingHabit: state.extra as Habit),
      ),
      GoRoute(
        path: '/habits/detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => HabitDetailScreen(habit: state.extra as Habit),
      ),
    ],
  );
}

/// Default router (starts on Today) — used when HabitTrackerApp isn't given
/// one explicitly, e.g. in widget tests.
final GoRouter appRouter = createAppRouter();

/// Bottom navigation shell: Today / Habits / Insights / Settings.
/// This is new relative to HabitKit, which doesn't have a dedicated nav bar.
class _AppShell extends StatelessWidget {
  final String location;
  final Widget child;

  const _AppShell({required this.location, required this.child});

  static const _tabs = ['/today', '/habits', '/insights', '/settings'];

  int get _currentIndex {
    final index = _tabs.indexWhere((t) => location.startsWith(t));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => context.go(_tabs[index]),
        items: const [
          AppNavItem(
            icon: Icons.check_circle_outline,
            activeIcon: Icons.check_circle,
            label: 'Today',
          ),
          AppNavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'Habits',
          ),
          AppNavItem(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights,
            label: 'Insights',
          ),
          AppNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}