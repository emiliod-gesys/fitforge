import '../core/constants/app_constants.dart';
import '../core/hyrox/hyrox_standards.dart';
import '../core/runner/runner_standards.dart';
import 'exercise_logging.dart';

class RoutineSetTarget {
  final int reps;
  final double? weight;

  const RoutineSetTarget({
    required this.reps,
    this.weight,
  });

  factory RoutineSetTarget.fromJson(dynamic json) {
    if (json is! Map) {
      return const RoutineSetTarget(reps: AppConstants.defaultReps);
    }
    final map = Map<String, dynamic>.from(json);
    return RoutineSetTarget(
      reps: map['reps'] as int? ?? AppConstants.defaultReps,
      weight: (map['weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'reps': reps,
        if (weight != null) 'weight': weight,
      };

  RoutineSetTarget copyWith({int? reps, double? weight, bool clearWeight = false}) {
    return RoutineSetTarget(
      reps: reps ?? this.reps,
      weight: clearWeight ? null : (weight ?? this.weight),
    );
  }
}

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
  final ExerciseLoggingType loggingType;
  final int? targetDurationSeconds;
  final double? targetDistanceMeters;
  final double? targetInclinePercent;
  final int? targetSteps;
  final bool? perArmWeight;
  final List<RoutineSetTarget> targetSetDetails;

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
    this.loggingType = ExerciseLoggingType.strength,
    this.targetDurationSeconds,
    this.targetDistanceMeters,
    this.targetInclinePercent,
    this.targetSteps,
    this.perArmWeight,
    this.targetSetDetails = const [],
  });

  bool get isCardio => loggingType == ExerciseLoggingType.cardio;

  List<RoutineSetTarget> get resolvedSetDetails {
    if (targetSetDetails.isNotEmpty) return targetSetDetails;
    return List.generate(
      targetSets,
      (_) => RoutineSetTarget(reps: targetReps, weight: targetWeight),
    );
  }

  RoutineExercise withSyncedLegacyFields() {
    final details = resolvedSetDetails;
    if (details.isEmpty) return this;
    return RoutineExercise(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      orderIndex: orderIndex,
      targetSets: details.length,
      targetReps: details.first.reps,
      targetWeight: details.first.weight,
      restSeconds: restSeconds,
      imageUrl: imageUrl,
      loggingType: loggingType,
      targetDurationSeconds: targetDurationSeconds,
      targetDistanceMeters: targetDistanceMeters,
      targetInclinePercent: targetInclinePercent,
      targetSteps: targetSteps,
      perArmWeight: perArmWeight,
      targetSetDetails: details,
    );
  }

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    final details = <RoutineSetTarget>[];
    final rawDetails = json['target_set_details'];
    if (rawDetails is List) {
      for (final item in rawDetails) {
        details.add(RoutineSetTarget.fromJson(item));
      }
    }

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
      loggingType: ExerciseLoggingType.fromJson(json['logging_type'] as String?),
      targetDurationSeconds: json['target_duration_seconds'] as int?,
      targetDistanceMeters: (json['target_distance_meters'] as num?)?.toDouble(),
      targetInclinePercent: (json['target_incline_percent'] as num?)?.toDouble(),
      targetSteps: json['target_steps'] as int?,
      perArmWeight: json['per_arm_weight'] as bool?,
      targetSetDetails: details,
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
        'logging_type': loggingType.toJson(),
        if (targetDurationSeconds != null) 'target_duration_seconds': targetDurationSeconds,
        if (targetDistanceMeters != null) 'target_distance_meters': targetDistanceMeters,
        if (targetInclinePercent != null) 'target_incline_percent': targetInclinePercent,
        if (targetSteps != null) 'target_steps': targetSteps,
        if (perArmWeight != null) 'per_arm_weight': perArmWeight,
        if (targetSetDetails.isNotEmpty)
          'target_set_details': targetSetDetails.map((s) => s.toJson()).toList(),
      };

  RoutineExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    int? orderIndex,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    int? restSeconds,
    String? imageUrl,
    ExerciseLoggingType? loggingType,
    int? targetDurationSeconds,
    double? targetDistanceMeters,
    double? targetInclinePercent,
    int? targetSteps,
    bool? perArmWeight,
    List<RoutineSetTarget>? targetSetDetails,
  }) {
    return RoutineExercise(
      id: id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      orderIndex: orderIndex ?? this.orderIndex,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      imageUrl: imageUrl ?? this.imageUrl,
      loggingType: loggingType ?? this.loggingType,
      targetDurationSeconds: targetDurationSeconds ?? this.targetDurationSeconds,
      targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
      targetInclinePercent: targetInclinePercent ?? this.targetInclinePercent,
      targetSteps: targetSteps ?? this.targetSteps,
      perArmWeight: perArmWeight ?? this.perArmWeight,
      targetSetDetails: targetSetDetails ?? this.targetSetDetails,
    );
  }
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
  final bool isFavorite;
  final bool isHyroxSystem;
  final HyroxLevel? hyroxLevel;
  final bool isRunnerSystem;
  final RunnerType? runnerType;

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
    this.isFavorite = false,
    this.isHyroxSystem = false,
    this.hyroxLevel,
    this.isRunnerSystem = false,
    this.runnerType,
  });

  factory Routine.fromJson(Map<String, dynamic> json, {List<RoutineExercise>? exercises}) {
    final hyroxLevelRaw = json['hyrox_level'] as String?;
    final runnerTypeRaw = json['runner_type'] as String?;
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
      isFavorite: json['is_favorite'] as bool? ?? false,
      isHyroxSystem: json['is_hyrox_system'] as bool? ?? false,
      hyroxLevel: hyroxLevelRaw == null ? null : HyroxLevel.fromCode(hyroxLevelRaw),
      isRunnerSystem: json['is_runner_system'] as bool? ?? false,
      runnerType: RunnerType.fromCode(runnerTypeRaw),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'target_muscles': targetMuscles,
        'is_ai_generated': isAiGenerated,
        if (isFavorite) 'is_favorite': isFavorite,
        if (isHyroxSystem) 'is_hyrox_system': true,
        if (hyroxLevel != null) 'hyrox_level': hyroxLevel!.code,
        if (isRunnerSystem) 'is_runner_system': true,
        if (runnerType != null) 'runner_type': runnerType!.code,
      };

  Routine copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? targetMuscles,
    List<RoutineExercise>? exercises,
    bool? isAiGenerated,
    bool? isFavorite,
    bool? isHyroxSystem,
    HyroxLevel? hyroxLevel,
    bool? isRunnerSystem,
    RunnerType? runnerType,
  }) {
    return Routine(
      id: id ?? this.id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      isFavorite: isFavorite ?? this.isFavorite,
      isHyroxSystem: isHyroxSystem ?? this.isHyroxSystem,
      hyroxLevel: hyroxLevel ?? this.hyroxLevel,
      isRunnerSystem: isRunnerSystem ?? this.isRunnerSystem,
      runnerType: runnerType ?? this.runnerType,
    );
  }

  /// Copia para guardar en la biblioteca del usuario actual (nuevos ids).
  Routine copyForCurrentUser() {
    return Routine(
      id: '',
      userId: '',
      name: name,
      description: description,
      targetMuscles: List<String>.from(targetMuscles),
      exercises: exercises
          .map(
            (e) => RoutineExercise(
              id: '',
              exerciseId: e.exerciseId,
              exerciseName: e.exerciseName,
              orderIndex: e.orderIndex,
              targetSets: e.targetSets,
              targetReps: e.targetReps,
              targetWeight: e.targetWeight,
              restSeconds: e.restSeconds,
              imageUrl: e.imageUrl,
              loggingType: e.loggingType,
              targetDurationSeconds: e.targetDurationSeconds,
              targetDistanceMeters: e.targetDistanceMeters,
              targetInclinePercent: e.targetInclinePercent,
              targetSteps: e.targetSteps,
              perArmWeight: e.perArmWeight,
              targetSetDetails: e.targetSetDetails,
            ),
          )
          .toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isAiGenerated: false,
      isFavorite: false,
      isHyroxSystem: false,
      hyroxLevel: null,
      isRunnerSystem: false,
      runnerType: null,
    );
  }
}
