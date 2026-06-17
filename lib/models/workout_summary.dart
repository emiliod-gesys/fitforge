import 'workout.dart';

class ExerciseSummaryLine {
  final String exerciseName;
  final int completedSets;
  final int totalReps;
  final double? bestWeightKg;

  const ExerciseSummaryLine({
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
  });

  bool get hasPreviousComparison => previousSameRoutine != null;

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
  }) {
    final totalVolumeKg = workout.exercises.fold<double>(
      0,
      (sum, ex) => sum + ex.totalVolume,
    );
    final totalReps = _totalReps(workout);
    final maxWeightKg = _maxWeightKg(workout);
    final exercises = _exerciseLines(workout);

    final prevReps = previousSameRoutine != null ? _totalReps(previousSameRoutine) : null;
    final prevVolume = previousSameRoutine != null
        ? previousSameRoutine.exercises.fold<double>(0, (s, e) => s + e.totalVolume)
        : null;
    final prevMax = previousSameRoutine != null ? _maxWeightKg(previousSameRoutine) : null;

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
        exerciseName: ex.exerciseName,
        completedSets: completed.length,
        totalReps: reps,
        bestWeightKg: best,
      ));
    }
    return lines;
  }
}
