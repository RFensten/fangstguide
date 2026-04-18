class ClosedSeason {
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;
  final String zone; // "all" | "nordsø_skagerrak" | "kattegat_bælter_østersø" | "ferskvand"

  const ClosedSeason({
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
    required this.zone,
  });

  factory ClosedSeason.fromJson(Map<String, dynamic> json) => ClosedSeason(
        startMonth: json['start_month'] as int,
        startDay: json['start_day'] as int,
        endMonth: json['end_month'] as int,
        endDay: json['end_day'] as int,
        zone: json['zone'] as String,
      );

  Map<String, dynamic> toJson() => {
        'start_month': startMonth,
        'start_day': startDay,
        'end_month': endMonth,
        'end_day': endDay,
        'zone': zone,
      };
}
