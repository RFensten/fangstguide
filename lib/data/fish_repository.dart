import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/fish.dart';

class FishRepository {
  List<Fish>? _cache;

  Future<List<Fish>> getAllFish() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/fish_data.json');
    final list = jsonDecode(raw) as List;
    _cache = list.map((e) => Fish.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
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
