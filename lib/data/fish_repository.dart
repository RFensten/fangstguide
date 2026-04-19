import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'models/fish.dart';

const _remoteUrl =
    'https://rfensten.github.io/fangstguide/data/fish_data.json';
const _cacheKey = 'fish_data_cache';

class FishRepository {
  List<Fish>? _cache;

  Future<List<Fish>> getAllFish() async {
    if (_cache != null) return _cache!;
    _cache = await _loadFish();
    return _cache!;
  }

  Future<List<Fish>> _loadFish() async {
    // 1. Forsøg at hente fra remote
    try {
      final response =
          await http.get(Uri.parse(_remoteUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final raw = response.body;
        // Gem i Hive-cache til offline-brug
        await Hive.box('settings').put(_cacheKey, raw);
        return _parse(raw);
      }
    } catch (_) {
      // Netværksfejl — fortsæt til fallback
    }

    // 2. Brug Hive-cache fra sidst appen var online
    final cached = Hive.box('settings').get(_cacheKey) as String?;
    if (cached != null) return _parse(cached);

    // 3. Brug den bundlede version der fulgte med app-installationen
    final raw = await rootBundle.loadString('assets/fish_data.json');
    return _parse(raw);
  }

  List<Fish> _parse(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => Fish.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final fishRepositoryProvider = Provider<FishRepository>((_) => FishRepository());

final fishListProvider = FutureProvider<List<Fish>>((ref) async {
  return ref.watch(fishRepositoryProvider).getAllFish();
});

final fishByIdProvider = FutureProvider.family<Fish?, String>((ref, id) async {
  final fish = await ref.watch(fishListProvider.future);
  try {
    return fish.firstWhere((f) => f.id == id);
  } catch (_) {
    return null;
  }
});
