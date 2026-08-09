class WaterEntry {
  final String id;
  final String userId;
  final DateTime loggedAt;
  final int amountMl;

  const WaterEntry({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.amountMl,
  });

  factory WaterEntry.fromJson(Map<String, dynamic> json) {
    return WaterEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      amountMl: json['amount_ml'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'amount_ml': amountMl,
        'logged_at': loggedAt.toUtc().toIso8601String(),
      };
}
