import 'package:flutter_test/flutter_test.dart';
import 'package:fangstguide/data/models/fish.dart';
import 'package:fangstguide/data/models/closed_season.dart';
import 'package:fangstguide/providers/zone_provider.dart';
import 'package:fangstguide/shared/utils/season_checker.dart';

Fish _makeFish({
  List<ClosedSeason> closedSeason = const [],
  double? minSizeFerskvand,
  double? minSizeNordsoe,
  double? minSizeKattegat,
  int? dailyLimit,
}) =>
    Fish(
      id: 'test',
      nameDa: 'Testfisk',
      nameLatin: 'Testus piscus',
      environment: const ['fresh'],
      imageAsset: 'assets/fish/test.svg',
      freeTier: true,
      minimumSizeCm: MinimumSize(
        ferskvand: minSizeFerskvand,
        nordsoeSkagerrak: minSizeNordsoe,
        kattegatBaelterOestersoe: minSizeKattegat,
      ),
      closedSeason: closedSeason,
      dailyLimit: dailyLimit,
      localRules: const [],
    );

ClosedSeason _cs(int sm, int sd, int em, int ed, {String zone = 'all'}) =>
    ClosedSeason(
        startMonth: sm, startDay: sd, endMonth: em, endDay: ed, zone: zone);

void main() {
  group('checkSeason — ingen fredning', () {
    test('åben uden minimumsstørrelse → open', () {
      final fish = _makeFish();
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 6, 1));
      expect(result.status, SeasonStatus.open);
    });

    test('åben med minimumsstørrelse → checkSize', () {
      final fish = _makeFish(minSizeFerskvand: 40);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 6, 1));
      expect(result.status, SeasonStatus.checkSize);
    });
  });

  group('checkSeason — normal fredningstid (ikke årsgrænse)', () {
    // Fredet 1. april – 30. april
    final cs = _cs(4, 1, 4, 30);

    test('dato inden fredning → open', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 3, 31));
      expect(result.status, SeasonStatus.open);
    });

    test('første dag i fredning → closed', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 4, 1));
      expect(result.status, SeasonStatus.closed);
    });

    test('midt i fredning → closed', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 4, 15));
      expect(result.status, SeasonStatus.closed);
    });

    test('sidste dag i fredning → closed', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 4, 30));
      expect(result.status, SeasonStatus.closed);
    });

    test('dagen efter fredning slutter → open', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 5, 1));
      expect(result.status, SeasonStatus.open);
    });

    test('genåbningsdato er korrekt (1. maj)', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 4, 15));
      expect(result.reopensOn, DateTime(2024, 5, 1));
    });
  });

  group('checkSeason — årsgrænse fredningstid (16. nov – 15. jan)', () {
    // Laks-lignende: fredet 16. nov – 15. jan
    final cs = _cs(11, 16, 1, 15);

    test('midt i (december) → closed', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 12, 1));
      expect(result.status, SeasonStatus.closed);
    });

    test('midt i (januar) → closed', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2025, 1, 10));
      expect(result.status, SeasonStatus.closed);
    });

    test('november inden fredning → open', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 11, 15));
      expect(result.status, SeasonStatus.open);
    });

    test('16. november → closed (første dag)', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 11, 16));
      expect(result.status, SeasonStatus.closed);
    });

    test('15. januar → closed (sidste dag)', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2025, 1, 15));
      expect(result.status, SeasonStatus.closed);
    });

    test('16. januar → open (dagen efter)', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2025, 1, 16));
      expect(result.status, SeasonStatus.open);
    });

    test('genåbningsdato fra december → 16. januar næste år', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 12, 1));
      expect(result.reopensOn, DateTime(2025, 1, 16));
    });

    test('genåbningsdato fra januar → 16. januar samme år', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2025, 1, 5));
      expect(result.reopensOn, DateTime(2025, 1, 16));
    });
  });

  group('checkSeason — totalfredet (1. jan – 31. dec)', () {
    final cs = _cs(1, 1, 12, 31);

    test('altid closed', () {
      final fish = _makeFish(closedSeason: [cs]);
      for (final month in [1, 4, 7, 10, 12]) {
        final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, month, 15));
        expect(result.status, SeasonStatus.closed,
            reason: 'Forventede closed i måned $month');
      }
    });

    test('ingen genåbningsdato ved totalfredet', () {
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 6, 1));
      expect(result.reopensOn, isNull);
    });
  });

  group('checkSeason — zone-specifik fredning', () {
    test('fredning kun for ferskvand → nordsø er åben', () {
      final cs = _cs(4, 1, 4, 30, zone: 'ferskvand');
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.nordsoeSkagerrak, DateTime(2024, 4, 15));
      expect(result.status, SeasonStatus.open);
    });

    test('fredning kun for ferskvand → ferskvand er fredet', () {
      final cs = _cs(4, 1, 4, 30, zone: 'ferskvand');
      final fish = _makeFish(closedSeason: [cs]);
      final result = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 4, 15));
      expect(result.status, SeasonStatus.closed);
    });

    test('minimumsstørrelse gælder kun for den rette zone', () {
      final fish = _makeFish(minSizeFerskvand: 40, minSizeNordsoe: null);
      final freshResult = checkSeason(fish, FishingZone.ferskvand, DateTime(2024, 6, 1));
      final saltResult = checkSeason(fish, FishingZone.nordsoeSkagerrak, DateTime(2024, 6, 1));
      expect(freshResult.status, SeasonStatus.checkSize);
      expect(saltResult.status, SeasonStatus.open);
    });
  });

  group('checkMeasure', () {
    test('over minimumsstørrelse og åben sæson → legal', () {
      final fish = _makeFish(minSizeFerskvand: 40);
      expect(
        checkMeasure(fish, FishingZone.ferskvand, DateTime(2024, 6, 1), 45),
        MeasureResult.legal,
      );
    });

    test('under minimumsstørrelse og åben sæson → tooSmall', () {
      final fish = _makeFish(minSizeFerskvand: 40);
      expect(
        checkMeasure(fish, FishingZone.ferskvand, DateTime(2024, 6, 1), 35),
        MeasureResult.tooSmall,
      );
    });

    test('præcis på minimumsstørrelse → legal', () {
      final fish = _makeFish(minSizeFerskvand: 40);
      expect(
        checkMeasure(fish, FishingZone.ferskvand, DateTime(2024, 6, 1), 40),
        MeasureResult.legal,
      );
    });

    test('fredet sæson → closedSeason uanset mål', () {
      final fish = _makeFish(
        minSizeFerskvand: 40,
        closedSeason: [_cs(4, 1, 4, 30)],
      );
      expect(
        checkMeasure(fish, FishingZone.ferskvand, DateTime(2024, 4, 15), 50),
        MeasureResult.closedSeason,
      );
    });

    test('ingen minimumsstørrelse → noMinimumSize', () {
      final fish = _makeFish();
      expect(
        checkMeasure(fish, FishingZone.ferskvand, DateTime(2024, 6, 1), 30),
        MeasureResult.noMinimumSize,
      );
    });

    test('minimumsstørrelse 0 → noMinimumSize', () {
      final fish = _makeFish(minSizeFerskvand: 0);
      expect(
        checkMeasure(fish, FishingZone.ferskvand, DateTime(2024, 6, 1), 30),
        MeasureResult.noMinimumSize,
      );
    });
  });
}
