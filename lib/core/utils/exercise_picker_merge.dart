import '../../models/exercise.dart';
import '../utils/exercise_text_search.dart';
import '../utils/muscle_inference.dart';

class ExerciseUsage {
  final String exerciseId;
  final DateTime usedAt;

  const ExerciseUsage({required this.exerciseId, required this.usedAt});
}

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
  return ExerciseTextSearch.matchesExercise(exercise, search);
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

/// Filtra resultados cloud (músculo / chips) y revalida el texto con tokens ES/EN.
List<Exercise> filterCloudPickerExercises({
  required List<Exercise> exercises,
  String search = '',
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

/// IDs más recientes primero: picks del selector, luego usos por fecha.
List<String> mergeRecentExerciseIds({
  List<String> localPicks = const [],
  List<ExerciseUsage> usages = const [],
}) {
  final seen = <String>{};
  final out = <String>[];

  void add(String id) {
    if (id.isEmpty) return;
    if (seen.add(id)) out.add(id);
  }

  for (final id in localPicks) {
    add(id);
  }

  final dated = [...usages]..sort((a, b) => b.usedAt.compareTo(a.usedAt));
  for (final usage in dated) {
    add(usage.exerciseId);
  }
  return out;
}

/// Recientes arriba; si hay búsqueda, manda la relevancia y la recencia desempata.
List<Exercise> sortPickerExercises({
  required List<Exercise> exercises,
  required List<String> recentIds,
  String search = '',
}) {
  if (exercises.length < 2) return exercises;

  final rank = <String, int>{};
  for (var i = 0; i < recentIds.length; i++) {
    rank[recentIds[i]] = recentIds.length - i;
  }

  final ranked = List<Exercise>.from(exercises);
  final hasSearch = search.trim().isNotEmpty;
  ranked.sort((a, b) {
    if (hasSearch) {
      final byScore =
          ExerciseTextSearch.score(b, search).compareTo(ExerciseTextSearch.score(a, search));
      if (byScore != 0) return byScore;
    }
    final recency = (rank[b.id] ?? 0).compareTo(rank[a.id] ?? 0);
    if (recency != 0) return recency;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return ranked;
}
