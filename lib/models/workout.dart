import '../core/utils/supabase_datetime.dart';
import '../core/utils/exercise_load.dart';
import 'exercise_logging.dart';

class WorkoutSet {
  final String id;
  final int setNumber;
  final double? weight;
  final int reps;
  final int? rir;
  final bool completed;
  final Duration? restTaken;
  final int? durationSeconds;
  final double? distanceMeters;
  final double? inclinePercent;
  final int? steps;
  final ExerciseLoggingType loggingType;

  const WorkoutSet({
    required this.id,
    required this.setNumber,
    this.weight,
    this.reps = 0,
    this.rir,
    this.completed = false,
    this.restTaken,
    this.durationSeconds,
    this.distanceMeters,
    this.inclinePercent,
    this.steps,
    this.loggingType = ExerciseLoggingType.strength,
  });

  bool get isCardio => loggingType == ExerciseLoggingType.cardio;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'] as String,
      setNumber: json['set_number'] as int? ?? 1,
      weight: (json['weight'] as num?)?.toDouble(),
      reps: json['reps'] as int? ?? 0,
      rir: json['rir'] as int?,
      completed: json['completed'] as bool? ?? false,
      restTaken: json['rest_seconds'] != null
          ? Duration(seconds: json['rest_seconds'] as int)
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      inclinePercent: (json['incline_percent'] as num?)?.toDouble(),
      steps: json['steps'] as int?,
      loggingType: ExerciseLoggingType.fromJson(json['logging_type'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'set_number': setNumber,
        'weight': weight,
        'reps': reps,
        'rir': rir,
        'completed': completed,
        'rest_seconds': restTaken?.inSeconds,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (distanceMeters != null) 'distance_meters': distanceMeters,
        if (inclinePercent != null) 'incline_percent': inclinePercent,
        if (steps != null) 'steps': steps,
        'logging_type': loggingType.toJson(),
      };

  WorkoutSet copyWith({
    double? weight,
    int? reps,
    int? rir,
    bool? completed,
    int? durationSeconds,
    double? distanceMeters,
    double? inclinePercent,
    int? steps,
    ExerciseLoggingType? loggingType,
  }) {
    return WorkoutSet(
      id: id,
      setNumber: setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      completed: completed ?? this.completed,
      restTaken: restTaken,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      inclinePercent: inclinePercent ?? this.inclinePercent,
      steps: steps ?? this.steps,
      loggingType: loggingType ?? this.loggingType,
    );
  }
}

class WorkoutExercise {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final String? imageUrl;
  final int orderIndex;
  final List<WorkoutSet> sets;
  final String? notes;

  const WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    this.imageUrl,
    required this.orderIndex,
    this.sets = const [],
    this.notes,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json, {List<WorkoutSet>? sets}) {
    return WorkoutExercise(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
      sets: sets ?? [],
      notes: json['notes'] as String?,
    );
  }

  double totalVolume({bool? perArmWeight, bool? unilateral, ExerciseLoadMode? loadMode}) => sets
      .where((s) => s.completed)
      .fold(
        0.0,
        (sum, s) => sum +
            ExerciseLoad.setVolumeKg(
              s,
              exerciseName: exerciseName,
              perArmWeight: perArmWeight,
              unilateral: unilateral,
              loadMode: loadMode,
            ),
      );
}

class Workout {
  final String id;
  final String userId;
  final String? routineId;
  final String? routineName;
  final String name;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationMinutes;
  final int? activeCaloriesKcal;
  final List<WorkoutExercise> exercises;
  final String? notes;
  final double totalVolume;

  const Workout({
    required this.id,
    required this.userId,
    this.routineId,
    this.routineName,
    required this.name,
    required this.startedAt,
    this.completedAt,
    this.durationMinutes = 0,
    this.activeCaloriesKcal,
    this.exercises = const [],
    this.notes,
    this.totalVolume = 0,
  });

  factory Workout.fromJson(Map<String, dynamic> json, {List<WorkoutExercise>? exercises}) {
    return Workout(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      routineId: json['routine_id'] as String?,
      routineName: json['routine_name'] as String?,
      name: json['name'] as String? ?? 'Entrenamiento',
      startedAt: SupabaseDateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? SupabaseDateTime.parse(json['completed_at'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      activeCaloriesKcal: json['active_calories_kcal'] as int?,
      exercises: exercises ?? [],
      notes: json['notes'] as String?,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get isActive => completedAt == null;

  Map<String, dynamic> toJson() => {
        'routine_id': routineId,
        'name': name,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'duration_minutes': durationMinutes,
        if (activeCaloriesKcal != null) 'active_calories_kcal': activeCaloriesKcal,
        'notes': notes,
        'total_volume': totalVolume,
      };
}
