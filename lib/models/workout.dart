class WorkoutSet {
  final String id;
  final int setNumber;
  final double? weight;
  final int reps;
  final int? rir;
  final bool completed;
  final Duration? restTaken;

  const WorkoutSet({
    required this.id,
    required this.setNumber,
    this.weight,
    this.reps = 0,
    this.rir,
    this.completed = false,
    this.restTaken,
  });

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
    );
  }

  Map<String, dynamic> toJson() => {
        'set_number': setNumber,
        'weight': weight,
        'reps': reps,
        'rir': rir,
        'completed': completed,
        'rest_seconds': restTaken?.inSeconds,
      };

  WorkoutSet copyWith({
    double? weight,
    int? reps,
    int? rir,
    bool? completed,
  }) {
    return WorkoutSet(
      id: id,
      setNumber: setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      completed: completed ?? this.completed,
      restTaken: restTaken,
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

  double get totalVolume =>
      sets.where((s) => s.completed).fold(0.0, (sum, s) => sum + (s.weight ?? 0) * s.reps);
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
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
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
        'notes': notes,
        'total_volume': totalVolume,
      };
}
