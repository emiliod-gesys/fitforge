import '../../models/exercise.dart';
import '../../models/routine.dart';
import 'exercise_catalog_visibility.dart';
import 'exercise_matcher.dart';
import 'muscle_inference.dart';

/// Limpia rutinas generadas por IA: catálogo filtrado, sin duplicados ni nombres basura.
abstract final class AiRoutineSanitizer {
  static const _excludedNamePatterns = [
    'ejercicio de prueba',
    'test exercise',
    'placeholder',
    'ejemplo',
    'demo',
    'xxx',
    'asdf',
  ];

  static bool isLowQualityExerciseName(String name) {
    final normalized = name.toLowerCase().trim();
    if (normalized.length < 3) return true;
    return _excludedNamePatterns.any(normalized.contains);
  }

  static const _vagueMuscleOnlyNames = {
    'biceps',
    'bíceps',
    'bicep',
    'triceps',
    'tríceps',
    'tricep',
    'pecho',
    'chest',
    'espalda',
    'back',
    'hombros',
    'hombro',
    'shoulders',
    'shoulder',
    'piernas',
    'pierna',
    'legs',
    'leg',
    'gluteos',
    'glúteos',
    'glutes',
    'abdominales',
    'abs',
    'core',
    'brazos',
    'arms',
    'cardio',
  };

  /// Ejercicio con foto wger o imagen personalizada del usuario (no maniquí genérico).
  static bool hasIllustration(Exercise exercise) =>
      ExerciseCatalogVisibility.hasIllustration(exercise);

  static bool isVagueExerciseName(String name) {
    final normalized = _normalizeName(name);
    if (_vagueMuscleOnlyNames.contains(normalized)) return true;

    final words = normalized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length == 1 && normalized.length <= 10) {
      return _vagueMuscleOnlyNames.any(normalized.contains);
    }
    return false;
  }

  static String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .trim();
  }

  static bool isEligibleForAi(Exercise exercise) {
    final qualityOk = !isLowQualityExerciseName(exercise.name) &&
        !isVagueExerciseName(exercise.name);
    if (exercise.isBundled) return qualityOk;
    return hasIllustration(exercise) && qualityOk;
  }

  static List<Exercise> catalogForAi(List<Exercise> catalog) {
    return catalog.where(isEligibleForAi).toList();
  }

  static List<String> namesForMuscles(List<Exercise> catalog, List<String> targetMuscles) {
    final filtered = catalogForAi(catalog);
    if (targetMuscles.isEmpty) {
      return filtered.map((e) => e.name).toList();
    }

    final matches =
        filtered.where((e) => _matchesTargetMuscles(e, targetMuscles)).map((e) => e.name).toList();
    return matches.isEmpty ? filtered.map((e) => e.name).toList() : matches;
  }

  static Routine enrichAndSanitize(
    Routine routine,
    List<Exercise> catalog, {
    List<String> targetMuscles = const [],
  }) {
    final aiCatalog = catalogForAi(catalog);
    final muscles = targetMuscles.isNotEmpty ? targetMuscles : routine.targetMuscles;
    final usedIds = <String>{};
    final result = <RoutineExercise>[];

    for (final re in routine.exercises) {
      if (isLowQualityExerciseName(re.exerciseName) || isVagueExerciseName(re.exerciseName)) {
        continue;
      }

      var match = ExerciseMatcher.findBest(re.exerciseName, aiCatalog);
      if (match != null && usedIds.contains(match.id)) {
        match = _findAlternative(
          catalog: aiCatalog,
          usedIds: usedIds,
          targetMuscles: muscles,
          avoidName: re.exerciseName,
        );
      } else if (match == null) {
        match = _findAlternative(
          catalog: aiCatalog,
          usedIds: usedIds,
          targetMuscles: muscles,
          avoidName: re.exerciseName,
        );
      }

      if (match == null) continue;
      if (!isEligibleForAi(match)) continue;

      usedIds.add(match.id);
      final isCardio = match.isCardio;
      result.add(
        RoutineExercise(
          id: re.id,
          exerciseId: match.id,
          exerciseName: match.name,
          orderIndex: result.length,
          targetSets: re.targetSets,
          targetReps: isCardio ? 0 : re.targetReps,
          targetWeight: isCardio ? null : re.targetWeight,
          restSeconds: isCardio ? 0 : re.restSeconds,
          imageUrl: match.imageUrl,
          loggingType: match.loggingType,
          targetDurationSeconds: re.targetDurationSeconds ?? (isCardio ? 1200 : null),
          targetDistanceMeters: re.targetDistanceMeters ?? (isCardio ? 3000 : null),
          targetInclinePercent: re.targetInclinePercent,
          targetSteps: re.targetSteps,
        ),
      );
    }

    return Routine(
      id: routine.id,
      userId: routine.userId,
      name: routine.name,
      description: routine.description,
      targetMuscles: routine.targetMuscles,
      exercises: result,
      createdAt: routine.createdAt,
      updatedAt: routine.updatedAt,
      isAiGenerated: routine.isAiGenerated,
    );
  }

  static Exercise? _findAlternative({
    required List<Exercise> catalog,
    required Set<String> usedIds,
    required List<String> targetMuscles,
    required String avoidName,
  }) {
    final avoid = avoidName.toLowerCase();
    for (final exercise in catalog) {
      if (usedIds.contains(exercise.id)) continue;
      if (!isEligibleForAi(exercise)) continue;
      if (exercise.name.toLowerCase() == avoid) continue;
      if (targetMuscles.isEmpty || _matchesTargetMuscles(exercise, targetMuscles)) {
        return exercise;
      }
    }
    return null;
  }

  static bool _matchesTargetMuscles(Exercise exercise, List<String> targetMuscles) {
    return targetMuscles.any(
      (target) => MuscleInference.matchesMuscleGroup(
        exercise: exercise,
        muscleGroup: target,
      ),
    );
  }
}
