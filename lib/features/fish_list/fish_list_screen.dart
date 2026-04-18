import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/zone_provider.dart';
import '../../shared/utils/season_checker.dart';
import '../../shared/widgets/fish_card.dart';
import '../../shared/widgets/zone_selector.dart';
import 'fish_list_provider.dart';

class FishListScreen extends ConsumerWidget {
  const FishListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fishAsync = ref.watch(filteredFishProvider);
    final activeFilter = ref.watch(environmentFilterProvider);
    final zone = ref.watch(zoneProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fangstguide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Indstillinger',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const ZoneSelector(),
          _FilterRow(activeFilter: activeFilter),
          Expanded(
            child: fishAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fejl: $e')),
              data: (fish) {
                var displayed = fish;

                // Apply "Fredet nu" filter here since it needs season logic
                if (activeFilter == EnvironmentFilter.closedNow) {
                  displayed = fish.where((f) {
                    final result = checkSeason(f, zone, DateTime.now());
                    return result.status == SeasonStatus.closed;
                  }).toList();
                }

                if (displayed.isEmpty) {
                  return const Center(
                    child: Text('Ingen arter matcher filteret.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: displayed.length,
                  itemBuilder: (context, index) {
                    final f = displayed[index];
                    return FishCard(
                      fish: f,
                      onTap: () => context.push('/fish/${f.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  final EnvironmentFilter activeFilter;

  const _FilterRow({required this.activeFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const filterLabels = {
      EnvironmentFilter.all: 'Alle',
      EnvironmentFilter.fresh: 'Ferskvand',
      EnvironmentFilter.salt: 'Saltvand',
      EnvironmentFilter.closedNow: 'Fredet nu',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filterLabels.entries.map<Widget>((entry) {
            final selected = activeFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => ref
                    .read(environmentFilterProvider.notifier)
                    .state = entry.key,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
