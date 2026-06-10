import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fish_repository.dart';
import '../../data/models/fish.dart';
import '../../providers/zone_provider.dart';
import '../../shared/utils/season_checker.dart';

enum EnvironmentFilter { all, salt, fresh, closedNow }

final environmentFilterProvider =
    StateProvider<EnvironmentFilter>((_) => EnvironmentFilter.all);

final searchQueryProvider = StateProvider<String>((_) => '');

final filteredFishProvider = FutureProvider<List<Fish>>((ref) async {
  final all = await ref.watch(fishListProvider.future);
  final filter = ref.watch(environmentFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final zone = ref.watch(zoneProvider);

  var fish = switch (filter) {
    EnvironmentFilter.all => all,
    EnvironmentFilter.salt =>
      all.where((f) => f.environment.contains('salt')).toList(),
    EnvironmentFilter.fresh =>
      all.where((f) => f.environment.contains('fresh')).toList(),
    EnvironmentFilter.closedNow => all
        .where((f) =>
            checkSeason(f, zone, DateTime.now()).status == SeasonStatus.closed)
        .toList(),
  };

  if (query.isNotEmpty) {
    fish = fish
        .where((f) =>
            f.nameDa.toLowerCase().contains(query) ||
            f.nameLatin.toLowerCase().contains(query))
        .toList();
  }

  return fish;
});
