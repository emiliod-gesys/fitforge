import '../../models/exercise.dart';
import '../../models/exercise_logging.dart';
import '../../models/workout.dart';

abstract final class ExerciseLoggingResolver {
  static Exercise? findInCatalog(String exerciseId, Iterable<Exercise> catalog) {
    for (final exercise in catalog) {
      if (exercise.id == exerciseId) return exercise;
    }
    return null;
  }

  static Exercise? findByName(String exerciseName, Iterable<Exercise> catalog) {
    for (final exercise in catalog) {
      if (exercise.matchesName(exerciseName)) return exercise;
    }
    return null;
  }

  static ExerciseLoggingType loggingTypeFor(
    String exerciseId,
    Iterable<Exercise> catalog, {
    String exerciseName = '',
  }) {
    return resolveLoggingType(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      catalog: catalog,
    );
  }

  static ExerciseLoggingType resolveLoggingType({
    required String exerciseId,
    required String exerciseName,
    Iterable<Exercise> catalog = const [],
    ExerciseLoggingType explicit = ExerciseLoggingType.strength,
    String? category,
  }) {
    if (explicit == ExerciseLoggingType.cardio) return ExerciseLoggingType.cardio;

    final byId = findInCatalog(exerciseId, catalog);
    if (byId != null && byId.isCardio) return ExerciseLoggingType.cardio;

    if (exerciseName.isNotEmpty) {
      final byName = findByName(exerciseName, catalog);
      if (byName != null && byName.isCardio) return ExerciseLoggingType.cardio;
    }

    if (category != null && inferFromCategory(category) == ExerciseLoggingType.cardio) {
      return ExerciseLoggingType.cardio;
    }

    if (exerciseName.isNotEmpty && inferFromName(exerciseName)) {
      return ExerciseLoggingType.cardio;
    }

    return ExerciseLoggingType.strength;
  }

  static bool isCardio(String exerciseId, Iterable<Exercise> catalog) {
    return isCardioExercise(exerciseId: exerciseId, exerciseName: '', catalog: catalog);
  }

  static bool isCardioExercise({
    required String exerciseId,
    required String exerciseName,
    Iterable<Exercise> catalog = const [],
    Iterable<WorkoutSet>? sets,
  }) {
    if (sets != null && sets.any((s) => s.loggingType == ExerciseLoggingType.cardio)) {
      return true;
    }

    final byId = findInCatalog(exerciseId, catalog);
    if (byId != null && byId.isCardio) return true;

    if (exerciseName.isNotEmpty) {
      final byName = findByName(exerciseName, catalog);
      if (byName != null && byName.isCardio) return true;
      if (inferFromName(exerciseName)) return true;
    }

    return false;
  }

  static CardioPreset inferPresetFromName(String exerciseName) {
    return CardioPreset.inferFromExerciseName(exerciseName);
  }

  static CardioLoggingConfig cardioConfigFor({
    required String exerciseId,
    required String exerciseName,
    Iterable<Exercise> catalog = const [],
  }) {
    final exercise = findInCatalog(exerciseId, catalog) ?? findByName(exerciseName, catalog);
    if (exercise?.cardioConfig != null) return exercise!.cardioConfig!;

    if (exerciseName.isNotEmpty) {
      return CardioLoggingConfig.fromPreset(inferPresetFromName(exerciseName));
    }

    return CardioLoggingConfig.fromPreset(CardioPreset.treadmill);
  }

  static ExerciseLoggingType inferFromCategory(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('cardio')) return ExerciseLoggingType.cardio;
    return ExerciseLoggingType.strength;
  }

  static bool inferFromName(String exerciseName) {
    return CardioNameMatcher.matches(exerciseName);
  }
}
