import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Indstillinger')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Mørkt tema'),
            value: settings.darkMode,
            onChanged: (v) => ref.read(settingsProvider.notifier).setDarkMode(v),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Privatlivspolitik'),
            onTap: () => launchUrl(
              Uri.parse('https://fangstguide.dk/privacy'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Datakilde'),
            subtitle: Text('lfst.dk · Saltvand 2026, Ferskvand 2025'),
          ),
        ],
      ),
    );
  }
}
