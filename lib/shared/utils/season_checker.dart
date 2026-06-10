import '../../data/models/fish.dart';
import '../../data/models/closed_season.dart';
import '../../providers/zone_provider.dart';

enum SeasonStatus { open, closed, checkSize }

class SeasonResult {
  final SeasonStatus status;
  // The date the season reopens (only set when status == closed)
  final DateTime? reopensOn;

  const SeasonResult(this.status, {this.reopensOn});
}

SeasonResult checkSeason(Fish fish, FishingZone zone, DateTime date) {
  // Totalfredet: daily_limit == 0 eller helårsfredning i zonen
  final isTotallyProtected = _isTotallyProtected(fish, zone);
  if (isTotallyProtected) {
    return const SeasonResult(SeasonStatus.closed);
  }

  final inClosedSeason = _isInClosedSeason(fish, zone, date);
  if (inClosedSeason) {
    final reopens = _nextReopening(fish, zone, date);
    return SeasonResult(SeasonStatus.closed, reopensOn: reopens);
  }

  final minSize = minimumSizeForZone(fish, zone);
  if (minSize != null && minSize > 0) {
    return const SeasonResult(SeasonStatus.checkSize);
  }

  return const SeasonResult(SeasonStatus.open);
}

// Returns true if the fish is fully protected: daily_limit == 0,
// or a full-year closed season covering the given zone.
bool _isTotallyProtected(Fish fish, FishingZone zone) {
  if (fish.dailyLimit == 0) return true;
  for (final cs in fish.closedSeason) {
    if (!zoneMatches(cs.zone, zone)) continue;
    if (cs.startMonth == 1 && cs.startDay == 1 &&
        cs.endMonth == 12 && cs.endDay == 31) {
      return true;
    }
  }
  return false;
}

bool _isInClosedSeason(Fish fish, FishingZone zone, DateTime date) {
  for (final cs in fish.closedSeason) {
    if (!zoneMatches(cs.zone, zone)) continue;
    if (_dateInRange(date, cs)) return true;
  }
  return false;
}

// Checks if [date] falls within the closed season [cs], handling year-crossing periods.
bool _dateInRange(DateTime date, ClosedSeason cs) {
  final month = date.month;
  final day = date.day;

  // Compare as day-of-year integers (ignoring actual year)
  final startOrd = cs.startMonth * 100 + cs.startDay;
  final endOrd = cs.endMonth * 100 + cs.endDay;
  final dateOrd = month * 100 + day;

  if (startOrd <= endOrd) {
    // Normal period: e.g. Apr 1 – Apr 30
    return dateOrd >= startOrd && dateOrd <= endOrd;
  } else {
    // Year-crossing period: e.g. Nov 16 – Jan 15
    return dateOrd >= startOrd || dateOrd <= endOrd;
  }
}

DateTime? _nextReopening(Fish fish, FishingZone zone, DateTime date) {
  DateTime? earliest;

  for (final cs in fish.closedSeason) {
    if (!zoneMatches(cs.zone, zone)) continue;
    if (!_dateInRange(date, cs)) continue;

    // Bemærk: day + 1 frem for .add(Duration(days: 1)) — sidstnævnte lægger
    // 24 timer til og rammer én dag forkert hen over sommertidsskift.
    DateTime candidate = DateTime(date.year, cs.endMonth, cs.endDay + 1);
    if (candidate.isBefore(date)) {
      candidate = DateTime(date.year + 1, cs.endMonth, cs.endDay + 1);
    }

    if (earliest == null || candidate.isBefore(earliest)) {
      earliest = candidate;
    }
  }

  return earliest;
}

/// Mindstemålet (cm) for [fish] i [zone], eller null hvis intet mindstemål.
double? minimumSizeForZone(Fish fish, FishingZone zone) =>
    switch (zone) {
      FishingZone.nordsoen => fish.minimumSizeCm.nordsoen,
      FishingZone.skagerrakKattegat => fish.minimumSizeCm.skagerrakKattegat,
      FishingZone.baelterOestersoe => fish.minimumSizeCm.baelterOestersoe,
      FishingZone.ferskvand => fish.minimumSizeCm.ferskvand,
    };

/// Om en fredningstids zonenøgle ([csZone]: "all" | "salt" | zone.jsonKey)
/// gælder for den valgte [zone].
bool zoneMatches(String csZone, FishingZone zone) {
  if (csZone == 'all') return true;
  if (csZone == 'salt') return zone != FishingZone.ferskvand;
  return csZone == zone.jsonKey;
}

// Convenience: returns whether a specific measured length is legal
enum MeasureResult { legal, tooSmall, closedSeason, noMinimumSize }

MeasureResult checkMeasure(
    Fish fish, FishingZone zone, DateTime date, double lengthCm) {
  final season = checkSeason(fish, zone, date);
  if (season.status == SeasonStatus.closed) return MeasureResult.closedSeason;

  final minSize = minimumSizeForZone(fish, zone);
  if (minSize == null || minSize == 0) return MeasureResult.noMinimumSize;
  return lengthCm >= minSize ? MeasureResult.legal : MeasureResult.tooSmall;
}
