import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fish_repository.dart';
import '../../data/models/fish.dart';

enum EnvironmentFilter { all, salt, fresh, closedNow }

final environmentFilterProvider =
    StateProvider<EnvironmentFilter>((_) => EnvironmentFilter.all);

final filteredFishProvider = FutureProvider<List<Fish>>((ref) async {
  final all = await ref.watch(fishListProvider.future);
  final filter = ref.watch(environmentFilterProvider);

  return switch (filter) {
    EnvironmentFilter.all => all,
    EnvironmentFilter.salt =>
      all.where((f) => f.environment.contains('salt')).toList(),
    EnvironmentFilter.fresh =>
      all.where((f) => f.environment.contains('fresh')).toList(),
    EnvironmentFilter.closedNow => all, // Filtered in UI using season checker
  };
});
