import '../../models/exercise.dart';

/// Combina catálogo embebido con resultados cloud (sin duplicar IDs).
List<Exercise> mergeBundledAndCloudExercises({
  required List<Exercise> bundled,
  required List<Exercise> cloud,
}) {
  if (cloud.isEmpty) return bundled;
  final seen = bundled.map((e) => e.id).toSet();
  final merged = List<Exercise>.from(bundled);
  for (final exercise in cloud) {
    if (seen.add(exercise.id)) merged.add(exercise);
  }
  return merged;
}

bool shouldQueryCloudExerciseCatalog(String search) => search.trim().length >= 2;
