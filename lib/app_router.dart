import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/fish_list/fish_list_screen.dart';
import 'features/fish_detail/fish_detail_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/measure_check/measure_check_screen.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const FishListScreen()),
        GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
        GoRoute(path: '/measure', builder: (_, __) => const MeasureCheckScreen()),
      ],
    ),
    GoRoute(
      path: '/fish/:id',
      builder: (_, state) =>
          FishDetailScreen(fishId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'measure',
          builder: (_, state) =>
              MeasureCheckScreen(preselectedFishId: state.pathParameters['id']),
        ),
      ],
    ),
    GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  static int _indexFor(String location) {
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/measure')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFor(location),
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
            case 1:
              context.go('/calendar');
            case 2:
              context.go('/measure');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.set_meal_outlined),
            selectedIcon: Icon(Icons.set_meal),
            label: 'Fisk',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Icon(Icons.straighten_outlined),
            selectedIcon: Icon(Icons.straighten),
            label: 'Mål',
          ),
        ],
      ),
    );
  }
}
