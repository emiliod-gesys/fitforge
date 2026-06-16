class RoutineExercise {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final int orderIndex;
  final int targetSets;
  final int targetReps;
  final double? targetWeight;
  final int restSeconds;
  final String? imageUrl;

  const RoutineExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.orderIndex,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight,
    this.restSeconds = 90,
    this.imageUrl,
  });

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    return RoutineExercise(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String? ?? '',
      orderIndex: json['order_index'] as int? ?? 0,
      targetSets: json['target_sets'] as int? ?? 3,
      targetReps: json['target_reps'] as int? ?? 10,
      targetWeight: (json['target_weight'] as num?)?.toDouble(),
      restSeconds: json['rest_seconds'] as int? ?? 90,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'order_index': orderIndex,
        'target_sets': targetSets,
        'target_reps': targetReps,
        'target_weight': targetWeight,
        'rest_seconds': restSeconds,
        'image_url': imageUrl,
      };
}

class Routine {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<String> targetMuscles;
  final List<RoutineExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAiGenerated;

  const Routine({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.targetMuscles = const [],
    this.exercises = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isAiGenerated = false,
  });

  factory Routine.fromJson(Map<String, dynamic> json, {List<RoutineExercise>? exercises}) {
    return Routine(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      targetMuscles: List<String>.from(json['target_muscles'] ?? []),
      exercises: exercises ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'target_muscles': targetMuscles,
        'is_ai_generated': isAiGenerated,
      };
}
