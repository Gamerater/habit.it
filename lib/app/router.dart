import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/tracking/presentation/screens/today_screen.dart';
import '../features/habits/presentation/screens/habit_list_screen.dart';
import '../features/habits/presentation/screens/add_edit_habit_screen.dart';
import '../features/insights/presentation/screens/insights_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'widgets/app_bottom_nav.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/today',
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
      path: '/habits/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddEditHabitScreen(),
    ),
  ],
);

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