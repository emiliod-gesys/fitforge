import '../../models/exercise.dart';
import '../utils/muscle_inference.dart';

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

List<Exercise> dedupeExercisesById(List<Exercise> exercises) {
  final seen = <String>{};
  final out = <Exercise>[];
  for (final exercise in exercises) {
    if (seen.add(exercise.id)) out.add(exercise);
  }
  return out;
}

/// Query para RPC cloud: texto de búsqueda o, si está vacío, el chip de músculo.
String? cloudCatalogSearchQuery({
  required String search,
  String? muscleFilter,
}) {
  final trimmedSearch = search.trim();
  if (trimmedSearch.length >= 2) return trimmedSearch;
  final muscle = muscleFilter?.trim();
  if (muscle != null && muscle.length >= 2) return muscle;
  return null;
}

bool shouldQueryCloudExerciseCatalog(String? query) =>
    query != null && query.trim().length >= 2;

/// Clave para el notifier cloud: búsqueda, exploración paginada o desactivado.
String? cloudExerciseCatalogNotifierKey({
  required String search,
  String? muscleFilter,
  bool cloudDisabled = false,
}) {
  if (cloudDisabled) return null;
  final query = cloudCatalogSearchQuery(search: search, muscleFilter: muscleFilter);
  if (query != null) return query;
  return '__browse__';
}

bool cloudExerciseCatalogIsBrowseMode(String key) => key == '__browse__';

bool exerciseMatchesTextFilter(Exercise exercise, String search) {
  if (search.trim().isEmpty) return true;
  final q = search.toLowerCase();
  return exercise.name.toLowerCase().contains(q) ||
      exercise.category.toLowerCase().contains(q) ||
      exercise.muscles.any((m) => m.toLowerCase().contains(q));
}

bool exerciseMatchesMuscleFilter(Exercise exercise, String? muscleFilter) {
  if (muscleFilter == null) return true;
  return MuscleInference.matchesMuscleGroup(exercise: exercise, muscleGroup: muscleFilter);
}

/// Filtra solo el catálogo embebido (búsqueda local de texto).
List<Exercise> filterBundledPickerExercises({
  required List<Exercise> exercises,
  required String search,
  String? muscleFilter,
  bool customOnly = false,
  bool inRoutineOnly = false,
  Set<String> selectedExerciseIds = const {},
  Set<String> excludeExerciseIds = const {},
}) {
  return exercises.where((exercise) {
    if (excludeExerciseIds.contains(exercise.id)) return false;
    if (inRoutineOnly && !selectedExerciseIds.contains(exercise.id)) return false;
    if (customOnly && !exercise.isUserCustom) return false;
    if (!exerciseMatchesMuscleFilter(exercise, muscleFilter)) return false;
    if (!exerciseMatchesTextFilter(exercise, search)) return false;
    return true;
  }).toList();
}

/// Filtra resultados cloud ya resueltos por Supabase (no repetir búsqueda de texto).
List<Exercise> filterCloudPickerExercises({
  required List<Exercise> exercises,
  String? muscleFilter,
  bool customOnly = false,
  bool inRoutineOnly = false,
  Set<String> selectedExerciseIds = const {},
  Set<String> excludeExerciseIds = const {},
}) {
  return exercises.where((exercise) {
    if (excludeExerciseIds.contains(exercise.id)) return false;
    if (inRoutineOnly && !selectedExerciseIds.contains(exercise.id)) return false;
    if (customOnly && !exercise.isUserCustom) return false;
    if (!exerciseMatchesMuscleFilter(exercise, muscleFilter)) return false;
    return true;
  }).toList();
}
