import '../core/constants/cloud_exercise_catalog.dart';
import '../core/utils/catalog_muscle_labels.dart';
import '../core/utils/cloud_exercise_name_localizer.dart';
import '../models/exercise.dart';
import '../models/exercise_logging.dart';
import '../services/supabase_service.dart';

/// Catálogo extendido en Supabase (ejercicios del dataset externo, carga bajo demanda).
class CloudExerciseCatalog {
  final _cache = <String, Exercise>{};

  Future<List<Exercise>> search({
    required String query,
    required String locale,
    int limit = CloudExerciseCatalogIds.pageSize,
    int offset = 0,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    await CloudExerciseNameLocalizer.ensureLoaded();

    final cappedLimit = limit.clamp(1, CloudExerciseCatalogIds.maxPageSize);
    final cappedOffset = offset < 0 ? 0 : offset;

    final response = await SupabaseService.client.rpc(
      'search_catalog_exercises',
      params: {
        'p_query': trimmed,
        'p_limit': cappedLimit,
        'p_offset': cappedOffset,
      },
    );

    final rows = response as List? ?? const [];
    final exercises = <Exercise>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final exercise = _parseRow(row, locale);
      _cache[exercise.id] = exercise;
      exercises.add(exercise);
    }
    return exercises;
  }

  Future<List<Exercise>> browse({
    required String locale,
    int limit = CloudExerciseCatalogIds.pageSize,
    int offset = 0,
  }) async {
    await CloudExerciseNameLocalizer.ensureLoaded();

    final cappedLimit = limit.clamp(1, CloudExerciseCatalogIds.maxPageSize);
    final cappedOffset = offset < 0 ? 0 : offset;

    final response = await SupabaseService.client.rpc(
      'browse_catalog_exercises',
      params: {
        'p_limit': cappedLimit,
        'p_offset': cappedOffset,
      },
    );

    final rows = response as List? ?? const [];
    final exercises = <Exercise>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final exercise = _parseRow(row, locale);
      _cache[exercise.id] = exercise;
      exercises.add(exercise);
    }
    return exercises;
  }

  Future<Exercise?> getById({
    required String catalogId,
    required String locale,
  }) async {
    if (_cache.containsKey(catalogId)) return _cache[catalogId];

    final response = await SupabaseService.client
        .from('catalog_exercises')
        .select()
        .eq('id', catalogId)
        .maybeSingle();
    if (response == null) return null;
    await CloudExerciseNameLocalizer.ensureLoaded();
    final exercise = _parseRow(Map<String, dynamic>.from(response), locale);
    _cache[catalogId] = exercise;
    return exercise;
  }

  void clearCache() => _cache.clear();

  Exercise _parseRow(Map<String, dynamic> json, String locale) {
    final lang = locale == 'en' ? 'en' : 'es';
    final id = json['id'] as String? ?? '';
    final nameEn = (json['name_en'] as String? ?? '').trim();
    final nameEs = (json['name_es'] as String? ?? '').trim();
    final name = CloudExerciseNameLocalizer.localize(
      nameEn: nameEn,
      nameEs: nameEs,
      locale: lang,
    );

    final loggingType = ExerciseLoggingType.fromJson(json['logging_type'] as String?);
    final loadMode = ExerciseLoadMode.fromJson(json['load_mode'] as String?);

    final stepsKey = lang == 'en' ? 'instruction_steps_en' : 'instruction_steps_es';
    final descKey = lang == 'en' ? 'description_en' : 'description_es';
    var description = (json[descKey] as String? ?? '').trim();
    if (description.isEmpty) {
      final steps = json[stepsKey];
      if (steps is List) {
        description = steps.map((e) => e.toString()).where((s) => s.isNotEmpty).join('\n\n');
      }
    }

    final musclesRaw = json['muscles'];
    final muscles = musclesRaw is List
        ? CatalogMuscleLabels.canonicalizeMuscles(
            musclesRaw.map((e) => e.toString()).where((s) => s.isNotEmpty),
          )
        : const <String>[];

    final equipment = (json['equipment'] as String? ?? '').trim();
    final categoryRaw = (json['category'] as String? ?? 'Otros').trim();
    final category = CatalogMuscleLabels.canonicalCategoryKey(categoryRaw);

    return Exercise(
      catalogId: id,
      supabaseId: id,
      name: name.isNotEmpty ? name : nameEn,
      description: description,
      category: category,
      muscles: muscles,
      equipment: equipment.isEmpty ? const [] : [equipment],
      imageUrl: json['image_url'] as String?,
      videoUrl: json['gif_url'] as String?,
      loggingType: loggingType,
      loadMode: loadMode,
      perArmWeight: json['per_arm_weight'] as bool? ?? false,
      unilateral: json['unilateral'] as bool? ?? false,
      weightOptional: json['weight_optional'] as bool? ??
          (loadMode.weightOptional || loggingType == ExerciseLoggingType.cardio),
      isBundled: false,
    );
  }

  Exercise? getCached(String catalogId) => _cache[catalogId];

  static bool isCloudExerciseId(String id) => CloudExerciseCatalogIds.isCloudId(id);
}
