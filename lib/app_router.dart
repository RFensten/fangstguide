import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

class _DisclaimerDialog extends StatefulWidget {
  final String disclaimerKey;
  const _DisclaimerDialog({required this.disclaimerKey});

  @override
  State<_DisclaimerDialog> createState() => _DisclaimerDialogState();
}

class _DisclaimerDialogState extends State<_DisclaimerDialog> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vigtig information'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Oplysningerne i Fangstguide er vejledende og kan indeholde '
              'fejl eller være forældede. Appen påtager sig intet ansvar for '
              'handlinger foretaget på baggrund af appens indhold.\n\n'
              'Tjek altid de gældende regler på lfst.dk før du fisker. '
              'Det er dit eget ansvar at overholde fiskerilovgivningen.',
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _checked,
                  onChanged: (v) => setState(() => _checked = v ?? false),
                ),
                const Expanded(
                  child: Text('Jeg har læst og forstået ovenstående'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _checked
              ? () {
                  Hive.box('settings').put(widget.disclaimerKey, true);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Accepter'),
        ),
      ],
    );
  }
}

class _AppShell extends StatefulWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  static const _disclaimerKey = 'disclaimer_accepted';

  @override
  void initState() {
    super.initState();
    final accepted = Hive.box('settings').get(_disclaimerKey) as bool? ?? false;
    if (!accepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDisclaimer());
    }
  }

  Future<void> _showDisclaimer() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DisclaimerDialog(disclaimerKey: _disclaimerKey),
    );
  }

  static int _indexFor(String location) {
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/measure')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: widget.child,
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
