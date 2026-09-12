import '../core/utils/json_parsing.dart';
import '../core/utils/supabase_datetime.dart';

class ManualActivityEntry {
  final String id;
  final String userId;
  final DateTime loggedAt;
  final String name;
  final int caloriesKcal;

  const ManualActivityEntry({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.name,
    required this.caloriesKcal,
  });

  factory ManualActivityEntry.fromJson(Map<String, dynamic> json) {
    return ManualActivityEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      loggedAt: SupabaseDateTime.parse(json['logged_at'] as String),
      name: json['name'] as String? ?? '',
      caloriesKcal: parseJsonInt(json['calories_kcal']),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'name': name,
        'calories_kcal': caloriesKcal,
        'logged_at': loggedAt.toUtc().toIso8601String(),
      };
}
