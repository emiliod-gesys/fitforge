import '../../models/exercise.dart';
import 'muscle_inference.dart';

abstract final class SimilarExercises {
  /// Query cloud RPC para traer candidatos del mismo grupo muscular principal.
  static String cloudSearchQueryForPrimaryGroup(String primaryGroup) {
    switch (primaryGroup) {
      case 'Abdominales':
        return 'abdominal';
      case 'Antebrazos':
        return 'antebrazo';
      default:
        return primaryGroup;
    }
  }

  static Exercise? findInCatalog(List<Exercise> catalog, String exerciseId) {
    for (final exercise in catalog) {
      if (exercise.id == exerciseId) return exercise;
    }
    return null;
  }

  static String? resolvePrimaryGroup({
    required String exerciseName,
    required String exerciseId,
    Exercise? catalogMatch,
  }) {
    if (catalogMatch != null) {
      final fromCatalog = MuscleInference.primaryRecoveryGroup(
        category: catalogMatch.category,
        muscles: catalogMatch.muscles,
      );
      if (fromCatalog != null) return fromCatalog;
    }

    final fromName = MuscleInference.fromExerciseName(exerciseName);
    if (fromName.length == 1) return fromName.first;
    if (fromName.isNotEmpty) return fromName.first;

    return null;
  }

  static bool matchesPrimaryGroup({
    required Exercise exercise,
    required String primaryGroup,
  }) {
    return MuscleInference.matchesMuscleGroup(
      exercise: exercise,
      muscleGroup: primaryGroup,
    );
  }

  static List<Exercise> find({
    required String exerciseName,
    required String exerciseId,
    required List<Exercise> catalog,
    required Set<String> excludeIds,
    String? primaryGroup,
    Exercise? sourceExercise,
  }) {
    final source = sourceExercise ?? findInCatalog(catalog, exerciseId);
    final targetPrimary = primaryGroup ??
        resolvePrimaryGroup(
          exerciseName: exerciseName,
          exerciseId: exerciseId,
          catalogMatch: source,
        );
    if (targetPrimary == null) return const [];

    final sourceCategory = source?.category ?? '';
    final matches = <Exercise>[];

    for (final candidate in catalog) {
      if (candidate.id == exerciseId || excludeIds.contains(candidate.id)) continue;
      if (!matchesPrimaryGroup(exercise: candidate, primaryGroup: targetPrimary)) continue;
      matches.add(candidate);
    }

    matches.sort((a, b) => _compareCandidates(a, b, sourceCategory));
    return matches;
  }

  static List<Exercise> filterCloudCandidates({
    required List<Exercise> cloud,
    required String primaryGroup,
    required String exerciseId,
    required Set<String> excludeIds,
    String sourceCategory = '',
  }) {
    final matches = <Exercise>[];
    for (final candidate in cloud) {
      if (candidate.id == exerciseId || excludeIds.contains(candidate.id)) continue;
      if (!matchesPrimaryGroup(exercise: candidate, primaryGroup: primaryGroup)) continue;
      matches.add(candidate);
    }
    matches.sort((a, b) => _compareCandidates(a, b, sourceCategory));
    return matches;
  }

  static void sortByRelevance(List<Exercise> exercises, {String sourceCategory = ''}) {
    exercises.sort((a, b) => _compareCandidates(a, b, sourceCategory));
  }

  static int _compareCandidates(Exercise a, Exercise b, String sourceCategory) {
    if (sourceCategory.isNotEmpty) {
      final aSameCategory = a.category == sourceCategory;
      final bSameCategory = b.category == sourceCategory;
      if (aSameCategory != bSameCategory) return aSameCategory ? -1 : 1;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
