import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/premium_provider.dart';
import '../../providers/zone_provider.dart';
import '../../shared/utils/season_checker.dart';
import '../../shared/widgets/fish_card.dart';
import '../../shared/widgets/zone_selector.dart';
import 'fish_list_provider.dart';

class FishListScreen extends ConsumerStatefulWidget {
  const FishListScreen({super.key});

  @override
  ConsumerState<FishListScreen> createState() => _FishListScreenState();
}

class _FishListScreenState extends ConsumerState<FishListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fishAsync = ref.watch(filteredFishProvider);
    final activeFilter = ref.watch(environmentFilterProvider);
    final zone = ref.watch(zoneProvider);
    final isPremium = ref.watch(premiumProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fangstguide'),
        actions: [
          if (!isPremium)
            TextButton.icon(
              onPressed: () => context.push('/paywall'),
              icon: const Icon(Icons.lock_open_outlined, size: 18),
              label: const Text('Premium'),
            ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Søg efter art...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          _FilterRow(activeFilter: activeFilter),
          Expanded(
            child: fishAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fejl: $e')),
              data: (fish) {
                var displayed = fish;

                if (activeFilter == EnvironmentFilter.closedNow) {
                  displayed = displayed.where((f) {
                    final result = checkSeason(f, zone, DateTime.now());
                    return result.status == SeasonStatus.closed;
                  }).toList();
                }

                if (_query.isNotEmpty) {
                  displayed = displayed.where((f) =>
                      f.nameDa.toLowerCase().contains(_query) ||
                      f.nameLatin.toLowerCase().contains(_query),
                  ).toList();
                }

                if (displayed.isEmpty) {
                  return const Center(
                    child: Text('Ingen arter matcher søgningen.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: displayed.length,
                  itemBuilder: (context, index) {
                    final f = displayed[index];
                    final locked = !isPremium && !f.freeTier;
                    return _FishListItem(
                      fish: f,
                      locked: locked,
                      onTap: () => locked
                          ? context.push('/paywall')
                          : context.push('/fish/${f.id}'),
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

class _FishListItem extends StatelessWidget {
  final dynamic fish;
  final bool locked;
  final VoidCallback onTap;

  const _FishListItem({
    required this.fish,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!locked) {
      return FishCard(fish: fish, onTap: onTap);
    }

    return Stack(
      children: [
        Opacity(
          opacity: 0.45,
          child: FishCard(fish: fish, onTap: onTap),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outlined,
                          size: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Premium',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
