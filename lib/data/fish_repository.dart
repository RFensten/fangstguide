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
  Future<List<Fish>>? _localFuture;
  bool _hasRefreshed = false;

  /// Hvornår regeldata sidst er opdateret (fra JSON'ens 'updated'-felt).
  DateTime? _dataUpdated;
  DateTime? get dataUpdated => _dataUpdated;

  /// Indlæser data lokalt (Hive-cache eller bundlet asset) — rører aldrig
  /// netværket, så UI kan vises med det samme.
  Future<List<Fish>> loadLocal() => _localFuture ??= _loadLocal();

  Future<List<Fish>> _loadLocal() async {
    final cached = Hive.box('settings').get(_cacheKey) as String?;
    if (cached != null) {
      try {
        return _parse(cached);
      } catch (_) {
        // Korrupt cache — fald tilbage til den bundlede version
      }
    }
    final raw = await rootBundle.loadString('assets/fish_data.json');
    return _parse(raw);
  }

  /// Henter den nyeste version fra remote i baggrunden.
  /// Returnerer den nye liste hvis data har ændret sig, ellers null.
  /// Kører højst én gang pr. app-session.
  Future<List<Fish>?> refreshFromRemote() async {
    if (_hasRefreshed) return null;
    _hasRefreshed = true;
    try {
      final response = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final raw = utf8.decode(response.bodyBytes);
      final box = Hive.box('settings');
      if (box.get(_cacheKey) == raw) return null; // uændret

      // Parse FØR vi cacher, så ugyldig remote-data aldrig forgifter cachen
      final parsed = _parse(raw);
      await box.put(_cacheKey, raw);
      _localFuture = Future.value(parsed);
      return parsed;
    } catch (_) {
      // Netværks- eller parsefejl — behold den lokale version
      return null;
    }
  }

  List<Fish> _parse(String raw) {
    final decoded = jsonDecode(raw);
    final List list;
    if (decoded is Map<String, dynamic>) {
      // Nyt format: {"updated": "2026-01-01", "fish": [...]}
      final updated = decoded['updated'] as String?;
      _dataUpdated = updated != null ? DateTime.tryParse(updated) : null;
      list = decoded['fish'] as List;
    } else {
      // Gammelt format: rå liste uden metadata
      list = decoded as List;
    }
    return list.map((e) => Fish.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final fishRepositoryProvider = Provider<FishRepository>((_) => FishRepository());

/// Stale-while-revalidate: lokal data vises straks, og hvis remote har
/// ændringer, opdateres listen bagefter.
final fishListProvider = StreamProvider<List<Fish>>((ref) async* {
  final repo = ref.watch(fishRepositoryProvider);
  yield await repo.loadLocal();
  final fresh = await repo.refreshFromRemote();
  if (fresh != null) yield fresh;
});

/// Dato for hvornår regeldata sidst er opdateret — til "Gældende pr."-visning.
final dataUpdatedProvider = Provider<DateTime?>((ref) {
  ref.watch(fishListProvider); // genberegn når data (gen)indlæses
  return ref.watch(fishRepositoryProvider).dataUpdated;
});

final fishByIdProvider = FutureProvider.family<Fish?, String>((ref, id) async {
  final fish = await ref.watch(fishListProvider.future);
  for (final f in fish) {
    if (f.id == id) return f;
  }
  return null;
});
