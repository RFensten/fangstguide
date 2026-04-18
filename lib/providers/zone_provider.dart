import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum FishingZone {
  nordsoeSkagerrak,
  kattegatBaelterOestersoe,
  ferskvand;

  String get displayName => switch (this) {
        FishingZone.nordsoeSkagerrak => 'Nordsø/Skagerrak',
        FishingZone.kattegatBaelterOestersoe => 'Kattegat/Bælter/Østersø',
        FishingZone.ferskvand => 'Ferskvand',
      };

  String get jsonKey => switch (this) {
        FishingZone.nordsoeSkagerrak => 'nordsø_skagerrak',
        FishingZone.kattegatBaelterOestersoe => 'kattegat_bælter_østersø',
        FishingZone.ferskvand => 'ferskvand',
      };
}

const _zoneBoxKey = 'settings';
const _zoneHiveKey = 'selected_zone';

class ZoneNotifier extends StateNotifier<FishingZone> {
  ZoneNotifier() : super(_loadSavedZone());

  static FishingZone _loadSavedZone() {
    final box = Hive.box(_zoneBoxKey);
    final saved = box.get(_zoneHiveKey) as String?;
    return FishingZone.values.firstWhere(
      (z) => z.name == saved,
      orElse: () => FishingZone.kattegatBaelterOestersoe,
    );
  }

  void setZone(FishingZone zone) {
    Hive.box(_zoneBoxKey).put(_zoneHiveKey, zone.name);
    state = zone;
  }
}

final zoneProvider = StateNotifierProvider<ZoneNotifier, FishingZone>(
  (_) => ZoneNotifier(),
);
