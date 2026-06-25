import 'body_metric.dart';
import 'exercise.dart';
import 'profile.dart';
import 'workout.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/exercise_load.dart';
import '../core/utils/milestones.dart';
import '../core/utils/muscle_inference.dart';
import '../core/utils/player_level.dart';
import '../core/utils/workout_calorie_estimator.dart';

class ExerciseSummaryLine {
  final String exerciseId;
  final String exerciseName;
  final int completedSets;
  final int totalReps;
  final double? bestWeightKg;
  final double volumeKg;
  final double? previousBestWeightKg;
  final int? previousTotalReps;
  final double? previousVolumeKg;
  final bool isNewPersonalRecord;

  const ExerciseSummaryLine({
    required this.exerciseId,
    required this.exerciseName,
    required this.completedSets,
    required this.totalReps,
    this.bestWeightKg,
    this.volumeKg = 0,
    this.previousBestWeightKg,
    this.previousTotalReps,
    this.previousVolumeKg,
    this.isNewPersonalRecord = false,
  });

  bool get hasPreviousComparison =>
      previousBestWeightKg != null ||
      previousTotalReps != null ||
      previousVolumeKg != null;

  bool get improvedBestWeight =>
      bestWeightKg != null &&
      previousBestWeightKg != null &&
      bestWeightKg! > previousBestWeightKg!;

  bool get improvedVolume =>
      previousVolumeKg != null && volumeKg > previousVolumeKg!;
}

class WorkoutSummaryData {
  final Workout workout;
  final int durationMinutes;
  final double totalVolumeKg;
  final int totalReps;
  final double? maxWeightKg;
  final List<ExerciseSummaryLine> exercises;
  final List<String> trainedMuscleGroups;
  final List<PersonalRecord> newPersonalRecords;
  final Workout? previousSameRoutine;
  final int? previousTotalReps;
  final double? previousTotalVolumeKg;
  final double? previousMaxWeightKg;
  final int? previousDurationMinutes;
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
    this.trainedMuscleGroups = const [],
    this.newPersonalRecords = const [],
    this.previousSameRoutine,
    this.previousTotalReps,
    this.previousTotalVolumeKg,
    this.previousMaxWeightKg,
    this.previousDurationMinutes,
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

  bool get hasNewPersonalRecords => newPersonalRecords.isNotEmpty;

  bool get hasTrainedMuscles => trainedMuscleGroups.isNotEmpty;

  double? get volumeImprovementPercent {
    final previous = previousTotalVolumeKg;
    if (previous == null || previous <= 0 || !isVolumeRecord) return null;
    return ((totalVolumeKg - previous) / previous) * 100;
  }

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
    List<PersonalRecord> newPersonalRecords = const [],
  }) {
    final catalog = exerciseCatalog ?? const [];
    final totalVolumeKg = workout.exercises.fold<double>(
      0,
      (sum, ex) => sum +
          ex.totalVolume(
            perArmWeight: ExerciseLoad.perArmWeightForExerciseId(ex.exerciseId, catalog),
            unilateral: ExerciseLoad.unilateralForExerciseId(ex.exerciseId, catalog),
            loadMode: ExerciseLoad.loadModeForExerciseId(ex.exerciseId, catalog),
          ),
    );
    final totalReps = _totalReps(workout);
    final maxWeightKg = _maxWeightKg(workout);
    final prExerciseIds = newPersonalRecords.map((r) => r.exerciseId).toSet();
    final exercises = _exerciseLines(
      workout: workout,
      previousSameRoutine: previousSameRoutine,
      exerciseCatalog: catalog,
      prExerciseIds: prExerciseIds,
    );
    final trainedMuscleGroups = _trainedMuscleGroups(workout, catalog);

    final prevReps = previousSameRoutine != null ? _totalReps(previousSameRoutine) : null;
    final prevVolume = previousSameRoutine?.exercises.fold<double>(
      0,
      (s, e) => s +
          e.totalVolume(
            perArmWeight: ExerciseLoad.perArmWeightForExerciseId(e.exerciseId, catalog),
            unilateral: ExerciseLoad.unilateralForExerciseId(e.exerciseId, catalog),
            loadMode: ExerciseLoad.loadModeForExerciseId(e.exerciseId, catalog),
          ),
    );
    final prevMax = previousSameRoutine != null ? _maxWeightKg(previousSameRoutine) : null;
    final prevDuration = previousSameRoutine?.durationMinutes;

    final calorieEstimate = WorkoutCalorieEstimator.estimateForWorkout(
      workout: workout,
      durationMinutes: durationMinutes,
      totalVolumeKg: totalVolumeKg,
      profile: profile,
      bodyMetrics: bodyMetrics,
    );

    return WorkoutSummaryData(
      workout: workout,
      durationMinutes: durationMinutes,
      totalVolumeKg: totalVolumeKg,
      totalReps: totalReps,
      maxWeightKg: maxWeightKg,
      exercises: exercises,
      trainedMuscleGroups: trainedMuscleGroups,
      newPersonalRecords: newPersonalRecords,
      previousSameRoutine: previousSameRoutine,
      previousTotalReps: prevReps,
      previousTotalVolumeKg: prevVolume,
      previousMaxWeightKg: prevMax,
      previousDurationMinutes: prevDuration,
      isVolumeRecord: prevVolume != null && totalVolumeKg > prevVolume,
      isRepsRecord: prevReps != null && totalReps > prevReps,
      isMaxWeightRecord: prevMax != null && maxWeightKg != null && maxWeightKg > prevMax,
      xpAward: xpAward,
      calorieEstimate: calorieEstimate,
      newMilestoneUnlocks: newMilestoneUnlocks,
    );
  }

  static List<String> _trainedMuscleGroups(Workout workout, List<Exercise> catalog) {
    final groups = <String>{};
    for (final ex in workout.exercises) {
      if (!ex.sets.any((s) => s.completed)) continue;
      groups.addAll(
        MuscleInference.resolve(
          exerciseName: ex.exerciseName,
          exerciseId: ex.exerciseId,
          catalog: catalog,
        ),
      );
    }

    final order = AppConstants.muscleGroups;
    final sorted = groups.toList()
      ..sort((a, b) {
        final ai = order.indexOf(a);
        final bi = order.indexOf(b);
        return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
      });
    return sorted;
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

  static List<ExerciseSummaryLine> _exerciseLines({
    required Workout workout,
    Workout? previousSameRoutine,
    required List<Exercise> exerciseCatalog,
    required Set<String> prExerciseIds,
  }) {
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

      final volume = ex.totalVolume(
        perArmWeight: ExerciseLoad.perArmWeightForExerciseId(ex.exerciseId, exerciseCatalog),
        unilateral: ExerciseLoad.unilateralForExerciseId(ex.exerciseId, exerciseCatalog),
        loadMode: ExerciseLoad.loadModeForExerciseId(ex.exerciseId, exerciseCatalog),
      );

      final prevEx = _findPreviousExercise(previousSameRoutine, ex.exerciseId);
      double? prevBest;
      int? prevReps;
      double? prevVolume;
      if (prevEx != null) {
        final prevCompleted = prevEx.sets.where((s) => s.completed).toList();
        prevReps = prevCompleted.fold<int>(0, (sum, s) => sum + s.reps);
        for (final set in prevCompleted) {
          final w = set.weight;
          if (w != null && (prevBest == null || w > prevBest)) prevBest = w;
        }
        prevVolume = prevEx.totalVolume(
          perArmWeight: ExerciseLoad.perArmWeightForExerciseId(
            prevEx.exerciseId,
            exerciseCatalog,
          ),
          unilateral: ExerciseLoad.unilateralForExerciseId(
            prevEx.exerciseId,
            exerciseCatalog,
          ),
          loadMode: ExerciseLoad.loadModeForExerciseId(
            prevEx.exerciseId,
            exerciseCatalog,
          ),
        );
      }

      lines.add(ExerciseSummaryLine(
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        completedSets: completed.length,
        totalReps: reps,
        bestWeightKg: best,
        volumeKg: volume,
        previousBestWeightKg: prevBest,
        previousTotalReps: prevReps,
        previousVolumeKg: prevVolume,
        isNewPersonalRecord: prExerciseIds.contains(ex.exerciseId),
      ));
    }
    return lines;
  }

  static WorkoutExercise? _findPreviousExercise(Workout? previous, String exerciseId) {
    if (previous == null) return null;
    for (final ex in previous.exercises) {
      if (ex.exerciseId == exerciseId) return ex;
    }
    return null;
  }
}
