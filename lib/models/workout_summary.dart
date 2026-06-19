import 'workout.dart';
import '../core/utils/milestones.dart';
import '../core/utils/player_level.dart';
import '../core/utils/exercise_load.dart';
import '../core/utils/workout_calorie_estimator.dart';
import 'body_metric.dart';
import 'exercise.dart';
import 'profile.dart';

class ExerciseSummaryLine {
  final String exerciseId;
  final String exerciseName;
  final int completedSets;
  final int totalReps;
  final double? bestWeightKg;

  const ExerciseSummaryLine({
    required this.exerciseId,
    required this.exerciseName,
    required this.completedSets,
    required this.totalReps,
    this.bestWeightKg,
  });
}

class WorkoutSummaryData {
  final Workout workout;
  final int durationMinutes;
  final double totalVolumeKg;
  final int totalReps;
  final double? maxWeightKg;
  final List<ExerciseSummaryLine> exercises;
  final Workout? previousSameRoutine;
  final int? previousTotalReps;
  final double? previousTotalVolumeKg;
  final double? previousMaxWeightKg;
  final bool isVolumeRecord;
  final bool isRepsRecord;
  final bool isMaxWeightRecord;
  final XpAwardResult? xpAward;
  final WorkoutCalorieEstimate calorieEstimate;
  final List<MilestoneUnlock> newMilestoneUnlocks;

  const WorkoutSummaryData({
    required this.workout,
    required this.durationMinutes,
    required this.totalVolumeKg,
    required this.totalReps,
    required this.maxWeightKg,
    required this.exercises,
    this.previousSameRoutine,
    this.previousTotalReps,
    this.previousTotalVolumeKg,
    this.previousMaxWeightKg,
    this.isVolumeRecord = false,
    this.isRepsRecord = false,
    this.isMaxWeightRecord = false,
    this.xpAward,
    this.calorieEstimate = const WorkoutCalorieEstimate.unavailable(),
    this.newMilestoneUnlocks = const [],
  });

  bool get hasCalorieEstimate => calorieEstimate.isAvailable;

  bool get hasPreviousComparison => previousSameRoutine != null;

  bool get leveledUp => xpAward?.leveledUp ?? false;

  bool get hasAchievements => leveledUp || newMilestoneUnlocks.isNotEmpty;

  List<String> get brokenRecords {
    final records = <String>[];
    if (isVolumeRecord) records.add('Volumen');
    if (isRepsRecord) records.add('Repeticiones');
    if (isMaxWeightRecord) records.add('Peso máximo');
    return records;
  }
}

abstract final class WorkoutSummaryBuilder {
  static WorkoutSummaryData build({
    required Workout workout,
    required int durationMinutes,
    Workout? previousSameRoutine,
    XpAwardResult? xpAward,
    List<Exercise>? exerciseCatalog,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    List<MilestoneUnlock> newMilestoneUnlocks = const [],
  }) {
    final totalVolumeKg = workout.exercises.fold<double>(
      0,
      (sum, ex) => sum +
          ex.totalVolume(
            perArmWeight: ExerciseLoad.perArmWeightForExerciseId(
              ex.exerciseId,
              exerciseCatalog ?? const [],
            ),
          ),
    );
    final totalReps = _totalReps(workout);
    final maxWeightKg = _maxWeightKg(workout);
    final exercises = _exerciseLines(workout);

    final prevReps = previousSameRoutine != null ? _totalReps(previousSameRoutine) : null;
    final prevVolume = previousSameRoutine?.exercises.fold<double>(
      0,
      (s, e) => s +
          e.totalVolume(
            perArmWeight: ExerciseLoad.perArmWeightForExerciseId(
              e.exerciseId,
              exerciseCatalog ?? const [],
            ),
          ),
    );
    final prevMax = previousSameRoutine != null ? _maxWeightKg(previousSameRoutine) : null;

    final completedSets = workout.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.sets.where((s) => s.completed).length,
    );
    final cardioDurationSeconds = workout.exercises
        .expand((ex) => ex.sets)
        .where((s) => s.completed && s.isCardio)
        .map((s) => s.durationSeconds ?? 0)
        .fold<int>(0, (sum, seconds) => sum + seconds);

    final calorieEstimate = WorkoutCalorieEstimator.estimate(
      durationMinutes: durationMinutes,
      totalVolumeKg: totalVolumeKg,
      completedSets: completedSets,
      totalReps: totalReps,
      profile: profile,
      bodyMetrics: bodyMetrics,
      cardioDurationSeconds: cardioDurationSeconds,
    );

    return WorkoutSummaryData(
      workout: workout,
      durationMinutes: durationMinutes,
      totalVolumeKg: totalVolumeKg,
      totalReps: totalReps,
      maxWeightKg: maxWeightKg,
      exercises: exercises,
      previousSameRoutine: previousSameRoutine,
      previousTotalReps: prevReps,
      previousTotalVolumeKg: prevVolume,
      previousMaxWeightKg: prevMax,
      isVolumeRecord: prevVolume != null && totalVolumeKg > prevVolume,
      isRepsRecord: prevReps != null && totalReps > prevReps,
      isMaxWeightRecord: prevMax != null &&
          maxWeightKg != null &&
          maxWeightKg > prevMax,
      xpAward: xpAward,
      calorieEstimate: calorieEstimate,
      newMilestoneUnlocks: newMilestoneUnlocks,
    );
  }

  static int _totalReps(Workout workout) {
    return workout.exercises.fold<int>(0, (sum, ex) {
      return sum +
          ex.sets
              .where((s) => s.completed)
              .fold<int>(0, (setSum, s) => setSum + s.reps);
    });
  }

  static double? _maxWeightKg(Workout workout) {
    double? max;
    for (final ex in workout.exercises) {
      for (final set in ex.sets.where((s) => s.completed && s.weight != null)) {
        final w = set.weight!;
        if (max == null || w > max) max = w;
      }
    }
    return max;
  }

  static List<ExerciseSummaryLine> _exerciseLines(Workout workout) {
    final lines = <ExerciseSummaryLine>[];
    for (final ex in workout.exercises) {
      final completed = ex.sets.where((s) => s.completed).toList();
      if (completed.isEmpty) continue;

      double? best;
      var reps = 0;
      for (final set in completed) {
        reps += set.reps;
        final w = set.weight;
        if (w != null && (best == null || w > best)) best = w;
      }

      lines.add(ExerciseSummaryLine(
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        completedSets: completed.length,
        totalReps: reps,
        bestWeightKg: best,
      ));
    }
    return lines;
  }
}
