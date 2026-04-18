import 'closed_season.dart';
import 'local_rule.dart';

class MinimumSize {
  final double? nordsoen;
  final double? skagerrakKattegat;
  final double? baelterOestersoe;
  final double? ferskvand;

  const MinimumSize({
    this.nordsoen,
    this.skagerrakKattegat,
    this.baelterOestersoe,
    this.ferskvand,
  });

  factory MinimumSize.fromJson(Map<String, dynamic> json) => MinimumSize(
        nordsoen: (json['nordsoen'] as num?)?.toDouble(),
        skagerrakKattegat: (json['skagerrak_kattegat'] as num?)?.toDouble(),
        baelterOestersoe: (json['bælter_østersø'] as num?)?.toDouble(),
        ferskvand: (json['ferskvand'] as num?)?.toDouble(),
      );
}

class Fish {
  final String id;
  final String nameDa;
  final String nameLatin;
  final List<String> environment;
  final String imageAsset;
  final bool freeTier;
  final MinimumSize minimumSizeCm;
  final List<ClosedSeason> closedSeason;
  final int? dailyLimit;
  final String? notes;
  final List<LocalRule> localRules;

  const Fish({
    required this.id,
    required this.nameDa,
    required this.nameLatin,
    required this.environment,
    required this.imageAsset,
    required this.freeTier,
    required this.minimumSizeCm,
    required this.closedSeason,
    this.dailyLimit,
    this.notes,
    required this.localRules,
  });

  factory Fish.fromJson(Map<String, dynamic> json) => Fish(
        id: json['id'] as String,
        nameDa: json['name_da'] as String,
        nameLatin: json['name_latin'] as String,
        environment: List<String>.from(json['environment'] as List),
        imageAsset: json['image_asset'] as String,
        freeTier: json['free_tier'] as bool,
        minimumSizeCm: MinimumSize.fromJson(
            json['minimum_size_cm'] as Map<String, dynamic>),
        closedSeason: (json['closed_season'] as List)
            .map((e) => ClosedSeason.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyLimit: json['daily_limit'] as int?,
        notes: json['notes'] as String?,
        localRules: (json['local_rules'] as List)
            .map((e) => LocalRule.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Fish copyWith({
    String? id,
    String? nameDa,
    String? nameLatin,
    List<String>? environment,
    String? imageAsset,
    bool? freeTier,
    MinimumSize? minimumSizeCm,
    List<ClosedSeason>? closedSeason,
    int? dailyLimit,
    String? notes,
    List<LocalRule>? localRules,
  }) =>
      Fish(
        id: id ?? this.id,
        nameDa: nameDa ?? this.nameDa,
        nameLatin: nameLatin ?? this.nameLatin,
        environment: environment ?? this.environment,
        imageAsset: imageAsset ?? this.imageAsset,
        freeTier: freeTier ?? this.freeTier,
        minimumSizeCm: minimumSizeCm ?? this.minimumSizeCm,
        closedSeason: closedSeason ?? this.closedSeason,
        dailyLimit: dailyLimit ?? this.dailyLimit,
        notes: notes ?? this.notes,
        localRules: localRules ?? this.localRules,
      );
}
