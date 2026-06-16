enum AiProvider { none, openai, gemini }

class UserProfile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String unitSystem;
  final double? bodyWeight;
  final String? fitnessGoal;
  final String? experienceLevel;
  final AiProvider aiProvider;
  final bool hasAiKey;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.unitSystem = 'kg',
    this.bodyWeight,
    this.fitnessGoal,
    this.experienceLevel,
    this.aiProvider = AiProvider.none,
    this.hasAiKey = false,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, {bool hasAiKey = false}) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      unitSystem: json['unit_system'] as String? ?? 'kg',
      bodyWeight: (json['body_weight'] as num?)?.toDouble(),
      fitnessGoal: json['fitness_goal'] as String?,
      experienceLevel: json['experience_level'] as String?,
      aiProvider: _parseProvider(json['ai_provider'] as String?),
      hasAiKey: hasAiKey,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static AiProvider _parseProvider(String? value) {
    switch (value) {
      case 'openai':
        return AiProvider.openai;
      case 'gemini':
        return AiProvider.gemini;
      default:
        return AiProvider.none;
    }
  }

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'unit_system': unitSystem,
        'body_weight': bodyWeight,
        'fitness_goal': fitnessGoal,
        'experience_level': experienceLevel,
        'ai_provider': aiProvider.name == 'none' ? null : aiProvider.name,
      };
}

class BodyMeasurement {
  final String id;
  final String userId;
  final String type;
  final double value;
  final String unit;
  final DateTime measuredAt;

  const BodyMeasurement({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    this.unit = 'kg',
    required this.measuredAt,
  });

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'weight',
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      measuredAt: DateTime.parse(json['measured_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => ({
        'type': type,
        'value': value,
        'unit': unit,
        'measured_at': measuredAt.toIso8601String(),
      });
}

class PersonalRecord {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final double oneRepMax;
  final DateTime achievedAt;

  const PersonalRecord({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.oneRepMax,
    required this.achievedAt,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String? ?? '',
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int? ?? 1,
      oneRepMax: (json['one_rep_max'] as num?)?.toDouble() ?? 0,
      achievedAt: DateTime.parse(json['achieved_at'] as String),
    );
  }

  static double calculate1RM(double weight, int reps) {
    if (reps <= 1) return weight;
    return weight * (1 + reps / 30.0);
  }
}
