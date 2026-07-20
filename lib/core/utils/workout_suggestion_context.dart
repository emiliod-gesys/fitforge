import 'dart:convert';

import '../../models/exercise.dart';
import '../../models/exercise_history.dart';
import '../../models/exercise_logging.dart';
import '../../models/profile.dart';
import '../../models/workout.dart';
import 'exercise_history_utils.dart';
import 'gym_weight.dart';
import 'muscle_inference.dart';
import 'proactive_workout_ai_rules.dart';
import 'unit_converter.dart';

/// Contexto compacto para sugerencias de IA al iniciar un entrenamiento.
class WorkoutSuggestionExerciseContext {
  final String exerciseId;
  final String exerciseName;
  final bool isCardio;
  final int setCount;
  final int? historyAvgSetCount;
  final Map<String, dynamic>? latestSessionSummary;
  final Map<String, dynamic>? recentTopSet;
  final List<String> muscleGroups;
  final double recoveryPercent;
  final int? daysSinceLastSession;
  final bool isCompound;
  final bool warmupSetsAllowed;
  final List<WorkoutSuggestionHistorySession> history;

  const WorkoutSuggestionExerciseContext({
    required this.exerciseId,
    required this.exerciseName,
    required this.isCardio,
    required this.setCount,
    this.historyAvgSetCount,
    this.latestSessionSummary,
    this.recentTopSet,
    required this.muscleGroups,
    required this.recoveryPercent,
    this.daysSinceLastSession,
    this.isCompound = false,
    this.warmupSetsAllowed = false,
    this.history = const [],
  });

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'name': exerciseName,
        'is_cardio': isCardio,
        'is_compound': isCompound,
        'set_count': setCount,
        if (historyAvgSetCount != null) 'history_avg_set_count': historyAvgSetCount,
        if (latestSessionSummary != null) 'latest_session_summary': latestSessionSummary,
        if (recentTopSet != null) 'recent_top_set': recentTopSet,
        'muscles': muscleGroups,
        'recovery_pct': recoveryPercent.round(),
        if (daysSinceLastSession != null) 'days_since_last': daysSinceLastSession,
        'warmup_sets_allowed': warmupSetsAllowed,
        'history': history.map((h) => h.toJson()).toList(),
      };
}

class WorkoutSuggestionHistorySession {
  final String date;
  final List<Map<String, dynamic>> sets;

  const WorkoutSuggestionHistorySession({
    required this.date,
    required this.sets,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'sets': sets,
      };
}

abstract final class WorkoutSuggestionContextBuilder {
  static const historyLimit = 5;

  static List<WorkoutSuggestionExerciseContext> build({
    required List<WorkoutExercise> exercises,
    required UserProfile profile,
    required Map<String, double> muscleRecovery,
    required List<Exercise> catalog,
    required Map<String, List<ExerciseSessionHistory>> historyByExerciseId,
  }) {
    final now = DateTime.now();
    return exercises.map((ex) {
      final isCardio = ex.sets.any((s) => s.isCardio);
      final muscles = MuscleInference.resolve(
        exerciseName: ex.exerciseName,
        exerciseId: ex.exerciseId,
        catalog: catalog,
      );
      final recovery = _recoveryForMuscles(muscles, muscleRecovery);
      final history = historyByExerciseId[ex.exerciseId] ?? const [];
      final daysSince = history.isEmpty
          ? null
          : now.difference(history.first.date).inDays;
      final historyAvgSets = history.isEmpty
          ? null
          : (history.map((h) => h.sets.length).reduce((a, b) => a + b) / history.length)
              .round();

      final anchoring = ExerciseHistoryUtils.anchoringSession(history);
      final latestSummary = anchoring == null
          ? null
          : _sessionSummary(anchoring, isCardio);
      final workingWeight = latestSummary?['working_weight_kg'] as num?;
      final hasWorkingHistory =
          (workingWeight != null && workingWeight > 0) ||
              (history.isNotEmpty &&
                  history.any((session) =>
                      session.sets.any((set) => (set.weight ?? 0) > 0)));

      return WorkoutSuggestionExerciseContext(
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        isCardio: isCardio,
        setCount: ex.sets.length,
        historyAvgSetCount: historyAvgSets,
        latestSessionSummary: latestSummary,
        recentTopSet: _recentTopSet(history, isCardio),
        muscleGroups: muscles,
        recoveryPercent: recovery,
        daysSinceLastSession: daysSince,
        isCompound: !isCardio && _isCompoundLift(ex.exerciseName),
        warmupSetsAllowed: ProactiveWorkoutAiRules.warmupSetsAllowed(
          isCompound: !isCardio && _isCompoundLift(ex.exerciseName),
          isCardio: isCardio,
          recoveryPercent: recovery,
          hasWorkingHistory: hasWorkingHistory,
          fitnessGoal: profile.fitnessGoal,
        ),
        history: history
            .take(historyLimit)
            .map((session) => _historySession(session, isCardio))
            .toList(),
      );
    }).toList();
  }

  static String payloadJson({
    required UserProfile profile,
    required List<WorkoutSuggestionExerciseContext> exercises,
  }) {
    return jsonEncode({
      'goal': profile.fitnessGoal ?? 'Mantenimiento',
      'experience': profile.experienceLevel ?? 'Intermedio',
      'unit_system': profile.unitSystem,
      'weight_display_rules': {
        'lb_whole_numbers_only': UnitConverter.isLb(profile.unitSystem),
        'kg_half_kg_steps_only': !UnitConverter.isLb(profile.unitSystem),
        'hint': UnitConverter.isLb(profile.unitSystem)
            ? 'User sees whole lb only (no decimals). Pick weight_kg that converts to integer lb.'
            : 'User sees kg with .0 or .5 only. weight_kg must be a multiple of 0.5.',
      },
      'exercises': exercises.map((e) => e.toJson()).toList(),
    });
  }

  static double _recoveryForMuscles(
    List<String> muscles,
    Map<String, double> muscleRecovery,
  ) {
    if (muscles.isEmpty) return 100;
    var min = 100.0;
    for (final muscle in muscles) {
      final value = muscleRecovery[muscle];
      if (value != null && value < min) min = value;
    }
    return min;
  }

  static bool _isCompoundLift(String name) {
    final n = name.toLowerCase();
    const patterns = [
      'press',
      'sentadilla',
      'squat',
      'peso muerto',
      'deadlift',
      'remo',
      'row',
      'dominada',
      'pull-up',
      'pull up',
      'chin-up',
      'fondos',
      'dip',
    ];
    return patterns.any(n.contains);
  }

  static WorkoutSuggestionHistorySession _historySession(
    ExerciseSessionHistory session,
    bool isCardio,
  ) {
    final date = session.date.toIso8601String().split('T').first;
    final sets = session.sets.map((set) {
      if (isCardio || set.isCardio) {
        return {
          if (set.durationSeconds != null) 'duration_s': set.durationSeconds,
          if (set.distanceMeters != null) 'distance_m': set.distanceMeters,
          if (set.inclinePercent != null) 'incline': set.inclinePercent,
          if (set.steps != null) 'steps': set.steps,
        };
      }
      return {
        if (set.weight != null) 'w': set.weight,
        'r': set.reps,
        if (set.rir != null) 'rir': set.rir,
      };
    }).where((m) => m.isNotEmpty).toList();

    return WorkoutSuggestionHistorySession(date: date, sets: sets);
  }

  static Map<String, dynamic>? _sessionSummary(
    ExerciseSessionHistory session,
    bool isCardio,
  ) {
    if (session.sets.isEmpty) return null;

    if (isCardio || session.sets.any((set) => set.isCardio)) {
      final longest = session.sets
          .where((set) => (set.durationSeconds ?? 0) > 0)
          .fold<int>(0, (best, set) => set.durationSeconds! > best ? set.durationSeconds! : best);
      final farthest = session.sets
          .where((set) => (set.distanceMeters ?? 0) > 0)
          .fold<double>(0, (best, set) => set.distanceMeters! > best ? set.distanceMeters! : best);
      if (longest <= 0 && farthest <= 0) return null;
      return {
        'set_count': session.sets.length,
        if (longest > 0) 'max_duration_s': longest,
        if (farthest > 0) 'max_distance_m': farthest,
      };
    }

    final weighted = session.sets.where((set) => (set.weight ?? 0) > 0).toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    final heaviest = ExerciseHistoryUtils.sessionHeaviestWeightKg(session.sets);
    final working = ExerciseHistoryUtils.workingSets(session.sets);
    final workingWeight = working.isEmpty
        ? heaviest
        : ExerciseHistoryUtils.sessionHeaviestWeightKg(working);
    final topRepsAtWorking = working.isEmpty
        ? weighted
            .where((set) => set.weight == heaviest)
            .fold<int>(0, (best, set) => set.reps > best ? set.reps : best)
        : working.fold<int>(0, (best, set) => set.reps > best ? set.reps : best);
    final pattern = ExerciseHistoryUtils.weightPattern(session.sets);
    final orderedWeights = weighted.map((set) => set.weight).toList();

    return {
      'set_count': session.sets.length,
      if (heaviest > 0) 'heaviest_weight_kg': heaviest,
      if (workingWeight > 0) 'working_weight_kg': workingWeight,
      if (topRepsAtWorking > 0) 'top_reps_at_working': topRepsAtWorking,
      'weight_pattern': pattern,
      if (orderedWeights.isNotEmpty) 'set_weights_kg': orderedWeights,
      if (working.isNotEmpty) 'working_set_count': working.length,
    };
  }

  static Map<String, dynamic>? _recentTopSet(
    List<ExerciseSessionHistory> history,
    bool isCardio,
  ) {
    if (history.isEmpty) return null;

    if (isCardio || history.any((session) => session.sets.any((set) => set.isCardio))) {
      return null;
    }

    WorkoutSet? best;
    for (final session in history.take(historyLimit)) {
      for (final set in session.sets) {
        if ((set.weight ?? 0) <= 0 || set.reps <= 0) continue;
        if (best == null) {
          best = set;
          continue;
        }
        final bestWeight = best.weight ?? 0;
        final setWeight = set.weight ?? 0;
        if (setWeight > bestWeight || (setWeight == bestWeight && set.reps > best.reps)) {
          best = set;
        }
      }
    }

    if (best == null) return null;
    return {
      'weight_kg': best.weight,
      'reps': best.reps,
      if (best.rir != null) 'rir': best.rir,
    };
  }
}

/// Sugerencia parseada de la IA para un ejercicio.
class AiExerciseSetSuggestion {
  final int setNumber;
  final double? weightKg;
  final int reps;
  final int? durationSeconds;
  final double? distanceMeters;
  final double? inclinePercent;
  final int? steps;

  const AiExerciseSetSuggestion({
    required this.setNumber,
    this.weightKg,
    this.reps = 0,
    this.durationSeconds,
    this.distanceMeters,
    this.inclinePercent,
    this.steps,
  });
}

class AiWorkoutSuggestions {
  final Map<String, List<AiExerciseSetSuggestion>> byExerciseId;

  const AiWorkoutSuggestions({required this.byExerciseId});

  List<AiExerciseSetSuggestion>? forExercise(String exerciseId) => byExerciseId[exerciseId];
}

abstract final class AiWorkoutSuggestionsParser {
  static AiWorkoutSuggestions? parse(String response, {String unitSystem = 'kg'}) {
    try {
      final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start < 0 || end <= start) return null;

      final json = jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
      final exercises = json['exercises'] as List? ?? [];
      final byId = <String, List<AiExerciseSetSuggestion>>{};

      for (final item in exercises) {
        if (item is! Map<String, dynamic>) continue;
        final exerciseId = item['exercise_id'] as String?;
        if (exerciseId == null || exerciseId.isEmpty) continue;

        final setsRaw = item['sets'] as List? ?? [];
        final sets = <AiExerciseSetSuggestion>[];
        for (final setItem in setsRaw) {
          if (setItem is! Map<String, dynamic>) continue;
          final setNumber = setItem['set_number'] as int? ?? (sets.length + 1);
          sets.add(
            AiExerciseSetSuggestion(
              setNumber: setNumber,
              weightKg: GymWeight.snapKgOrNull(
                _positiveDouble(setItem['weight_kg']),
                unitSystem,
              ),
              reps: (setItem['reps'] as num?)?.toInt().clamp(0, 100) ?? 0,
              durationSeconds: _positiveInt(setItem['duration_seconds']),
              distanceMeters: _positiveDouble(setItem['distance_meters']),
              inclinePercent: _positiveDouble(setItem['incline_percent']),
              steps: _positiveInt(setItem['steps']),
            ),
          );
        }
        if (sets.isNotEmpty) {
          sets.sort((a, b) => a.setNumber.compareTo(b.setNumber));
          byId[exerciseId] = _renumberSets(sets);
        }
      }

      if (byId.isEmpty) return null;
      return AiWorkoutSuggestions(byExerciseId: byId);
    } catch (_) {
      return null;
    }
  }

  static double? _positiveDouble(dynamic value) {
    if (value is! num || value <= 0) return null;
    return value.toDouble();
  }

  static int? _positiveInt(dynamic value) {
    if (value is! num || value <= 0) return null;
    return value.toInt();
  }

  static List<AiExerciseSetSuggestion> _renumberSets(List<AiExerciseSetSuggestion> sets) {
    return sets
        .asMap()
        .entries
        .map(
          (e) => AiExerciseSetSuggestion(
            setNumber: e.key + 1,
            weightKg: e.value.weightKg,
            reps: e.value.reps,
            durationSeconds: e.value.durationSeconds,
            distanceMeters: e.value.distanceMeters,
            inclinePercent: e.value.inclinePercent,
            steps: e.value.steps,
          ),
        )
        .toList();
  }
}

abstract final class AiWorkoutSuggestionsMerger {
  static const minSets = 1;
  static const maxStrengthSets = 10;
  static const maxCardioSets = 3;

  static List<WorkoutExercise> apply({
    required List<WorkoutExercise> exercises,
    required AiWorkoutSuggestions suggestions,
    String unitSystem = 'kg',
  }) {
    return exercises.map((ex) {
      final suggested = suggestions.forExercise(ex.exerciseId);
      if (suggested == null || suggested.isEmpty) return ex;

      final isCardio = ex.sets.any((s) => s.isCardio);
      final clamped = _clampSetCount(suggested, isCardio: isCardio);
      if (clamped.isEmpty) return ex;

      final templateSet = ex.sets.isNotEmpty ? ex.sets.first : null;
      final loggingType = isCardio
          ? ExerciseLoggingType.cardio
          : (templateSet?.loggingType ?? ExerciseLoggingType.strength);

      final mergedSets = clamped.asMap().entries.map((entry) {
        final setNumber = entry.key + 1;
        final match = entry.value;
        final existing = _existingSet(ex.sets, setNumber);

        if (isCardio) {
          return WorkoutSet(
            id: existing?.id ?? '',
            setNumber: setNumber,
            loggingType: ExerciseLoggingType.cardio,
            durationSeconds:
                match.durationSeconds ?? existing?.durationSeconds ?? templateSet?.durationSeconds,
            distanceMeters:
                match.distanceMeters ?? existing?.distanceMeters ?? templateSet?.distanceMeters,
            inclinePercent:
                match.inclinePercent ?? existing?.inclinePercent ?? templateSet?.inclinePercent,
            steps: match.steps ?? existing?.steps ?? templateSet?.steps,
          );
        }

        return WorkoutSet(
          id: existing?.id ?? '',
          setNumber: setNumber,
          loggingType: loggingType,
          weight: GymWeight.snapKgOrNull(
                match.weightKg ?? existing?.weight ?? templateSet?.weight,
                unitSystem,
              ) ??
              existing?.weight ??
              templateSet?.weight,
          reps: match.reps > 0 ? match.reps : (existing?.reps ?? templateSet?.reps ?? 10),
        );
      }).toList();

      return WorkoutExercise(
        id: ex.id,
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        imageUrl: ex.imageUrl,
        orderIndex: ex.orderIndex,
        sets: mergedSets,
        notes: ex.notes,
      );
    }).toList();
  }

  static List<AiExerciseSetSuggestion> _clampSetCount(
    List<AiExerciseSetSuggestion> sets, {
    required bool isCardio,
  }) {
    final max = isCardio ? maxCardioSets : maxStrengthSets;
    if (sets.length > max) return sets.take(max).toList();
    if (sets.length < minSets) return const [];
    return sets;
  }

  static WorkoutSet? _existingSet(List<WorkoutSet> sets, int setNumber) {
    for (final set in sets) {
      if (set.setNumber == setNumber) return set;
    }
    if (setNumber <= sets.length) return sets[setNumber - 1];
    return null;
  }
}
