class LocalRule {
  final String location;
  final String note;

  const LocalRule({required this.location, required this.note});

  factory LocalRule.fromJson(Map<String, dynamic> json) => LocalRule(
        location: json['location'] as String,
        note: json['note'] as String,
      );
}
