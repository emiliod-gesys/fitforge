import 'exercise_logging.dart';

enum AiProvider { none, openai, gemini }

enum Gender {
  male,
  female,
  nonBinary,
  preferNotToSay;

  static Gender? fromCode(String? value) {
    switch (value) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'non_binary':
        return Gender.nonBinary;
      case 'prefer_not_to_say':
        return Gender.preferNotToSay;
      default:
        return null;
    }
  }

  String get code {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.nonBinary:
        return 'non_binary';
      case Gender.preferNotToSay:
        return 'prefer_not_to_say';
    }
  }
}

class UserProfile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String unitSystem;
  final double? bodyWeight;
  final int? age;
  final Gender? gender;
  final double? heightCm;
  final String preferredLanguage;
  final String? fitnessGoal;
  final String? experienceLevel;
  final AiProvider aiProvider;
  final bool hasAiKey;
  final int totalXp;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.unitSystem = 'kg',
    this.bodyWeight,
    this.age,
    this.gender,
    this.heightCm,
    this.preferredLanguage = 'es',
    this.fitnessGoal,
    this.experienceLevel,
    this.aiProvider = AiProvider.none,
    this.hasAiKey = false,
    this.totalXp = 0,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, {bool hasAiKey = false}) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      unitSystem: json['unit_system'] as String? ?? 'kg',
      bodyWeight: (json['body_weight'] as num?)?.toDouble(),
      age: json['age'] as int?,
      gender: Gender.fromCode(json['gender'] as String?),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      preferredLanguage: json['preferred_language'] as String? ?? 'es',
      fitnessGoal: json['fitness_goal'] as String?,
      experienceLevel: json['experience_level'] as String?,
      aiProvider: _parseProvider(json['ai_provider'] as String?),
      hasAiKey: hasAiKey,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
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
        'age': age,
        'gender': gender?.code,
        'height_cm': heightCm,
        'preferred_language': preferredLanguage,
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
  final double? weight;
  final int reps;
  final double? oneRepMax;
  final DateTime achievedAt;
  final PersonalRecordType recordType;
  final int? durationSeconds;
  final double? distanceMeters;
  final double? inclinePercent;
  final int? steps;

  const PersonalRecord({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    this.weight,
    this.reps = 1,
    this.oneRepMax,
    required this.achievedAt,
    this.recordType = PersonalRecordType.strength,
    this.durationSeconds,
    this.distanceMeters,
    this.inclinePercent,
    this.steps,
  });

  bool get isCardio => recordType != PersonalRecordType.strength;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      reps: json['reps'] as int? ?? 1,
      oneRepMax: (json['one_rep_max'] as num?)?.toDouble(),
      achievedAt: DateTime.parse(json['achieved_at'] as String),
      recordType: PersonalRecordType.fromJson(json['record_type'] as String?),
      durationSeconds: json['duration_seconds'] as int?,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      inclinePercent: (json['incline_percent'] as num?)?.toDouble(),
      steps: json['steps'] as int?,
    );
  }

  static double calculate1RM(double weight, int reps) {
    if (reps <= 1) return weight;
    return weight * (1 + reps / 30.0);
  }
}
