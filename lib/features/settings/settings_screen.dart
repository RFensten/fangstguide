import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/fish_repository.dart';
import '../../providers/settings_provider.dart';
import '../../shared/utils/date_utils.dart' as du;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final dataUpdated = ref.watch(dataUpdatedProvider);

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
            leading: const Icon(Icons.mail_outline),
            title: const Text('Support'),
            subtitle: const Text('rasmus.fensten@gmail.com'),
            onTap: () => launchUrl(
              Uri.parse('mailto:rasmus.fensten@gmail.com?subject=Fangstguide support'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Datakilde'),
            subtitle: Text(dataUpdated != null
                ? 'lfst.dk · Gældende pr. ${du.formatDanishDateWithYear(dataUpdated)}'
                : 'lfst.dk'),
          ),
        ],
      ),
    );
  }
}
