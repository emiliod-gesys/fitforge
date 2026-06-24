import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/l10n/app_locale.dart';
import '../data/exercise_translation_store.dart';
import '../data/supplemental_exercises.dart';
import '../models/exercise.dart';

/// Catálogo remoto wger.de — **legacy / inerte** mientras `ExerciseCatalogSource.bundled` esté activo.
///
/// Se conserva para reactivar con `AppConstants.exerciseCatalogSource = ExerciseCatalogSource.wger`
/// y para resolver entrenos antiguos guardados con IDs numéricos wger.
class WgerExerciseCatalog {
  final http.Client _http;
  Map<int, String>? _imageIndex;
  final Map<int, Exercise> _onDemandCache = {};

  WgerExerciseCatalog([http.Client? client]) : _http = client ?? http.Client();

  static const _pageSize = 100;
  static const _maxExercises = 1500;
  static const _illustratedFetchBatchSize = 10;

  Future<List<Exercise>> fetchCatalog({
    required String locale,
    required ExerciseTranslationStore? translationStore,
    required bool illustratedOnly,
  }) async {
    final exercises = illustratedOnly
        ? await _fetchIllustrated(locale: locale, translationStore: translationStore)
        : await _fetchAllExerciseInfo(locale: locale, translationStore: translationStore);

    if (illustratedOnly) {
      return exercises;
    }

    return SupplementalExercises.mergeWith(exercises, locale: locale);
  }

  Future<Exercise?> resolveById(
    int wgerId, {
    required String locale,
    required ExerciseTranslationStore? translationStore,
  }) async {
    if (wgerId < 0) return null;
    final cached = _onDemandCache[wgerId];
    if (cached != null) return cached;

    final imageIndex = _imageIndex ?? await _loadImageIndex();
    final exercise = await _fetchExerciseInfoById(
      wgerId,
      locale: locale,
      translationStore: translationStore,
      imageUrl: imageIndex[wgerId],
    );
    if (exercise == null) return null;
    _onDemandCache[wgerId] = exercise;
    return exercise;
  }

  Future<String?> fetchVideoUrl(int wgerId) async {
    if (wgerId < 0) return null;
    try {
      final uri = Uri.parse('${AppConstants.wgerApiBase}/video/').replace(
        queryParameters: {'exercise': wgerId.toString()},
      );
      final response = await _http.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List? ?? [];
      if (results.isEmpty) return null;
      final video = results.first as Map<String, dynamic>;
      return video['video'] as String?;
    } catch (_) {
      return null;
    }
  }

  Iterable<Exercise> get onDemandExercises => _onDemandCache.values;

  void clearCache() {
    _imageIndex = null;
    _onDemandCache.clear();
  }

  Future<List<Exercise>> _fetchIllustrated({
    required String locale,
    required ExerciseTranslationStore? translationStore,
  }) async {
    final imageIndex = await _loadImageIndex();
    final exercises = <Exercise>[];
    final ids = imageIndex.keys.toList();

    for (var i = 0; i < ids.length; i += _illustratedFetchBatchSize) {
      final batch = ids.skip(i).take(_illustratedFetchBatchSize);
      final batchResults = await Future.wait(
        batch.map(
          (id) => _fetchExerciseInfoById(
            id,
            locale: locale,
            translationStore: translationStore,
            imageUrl: imageIndex[id]!,
          ),
        ),
      );
      for (final exercise in batchResults) {
        if (exercise != null) exercises.add(exercise);
      }
    }

    return exercises;
  }

  Future<Map<int, String>> _loadImageIndex() async {
    if (_imageIndex != null) return _imageIndex!;

    final imageByExerciseId = <int, String>{};
    final isMainByExerciseId = <int, bool>{};
    var offset = 0;

    while (true) {
      final uri = Uri.parse('${AppConstants.wgerApiBase}/exerciseimage/').replace(
        queryParameters: {
          'limit': _pageSize.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await _http.get(uri);
      if (response.statusCode != 200) break;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List? ?? [];
      if (results.isEmpty) break;

      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;
        final exerciseId = item['exercise'] as int?;
        final imageUrl = item['image'] as String?;
        if (exerciseId == null || imageUrl == null || imageUrl.isEmpty) continue;

        final isMain = item['is_main'] == true;
        final existingIsMain = isMainByExerciseId[exerciseId] ?? false;
        if (!imageByExerciseId.containsKey(exerciseId) || (isMain && !existingIsMain)) {
          imageByExerciseId[exerciseId] = imageUrl;
          isMainByExerciseId[exerciseId] = isMain;
        }
      }

      if (data['next'] == null) break;
      offset += _pageSize;
    }

    _imageIndex = imageByExerciseId;
    return imageByExerciseId;
  }

  Future<List<Exercise>> _fetchAllExerciseInfo({
    required String locale,
    required ExerciseTranslationStore? translationStore,
  }) async {
    final exercises = <Exercise>[];
    var offset = 0;

    while (offset < _maxExercises) {
      final uri = Uri.parse('${AppConstants.wgerApiBase}/exerciseinfo/').replace(
        queryParameters: {
          'limit': _pageSize.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await _http.get(uri);
      if (response.statusCode != 200) break;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List? ?? [];
      if (results.isEmpty) break;

      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;
        final exercise = _parseExerciseInfo(
          item,
          locale: locale,
          translationStore: translationStore,
        );
        if (exercise != null) exercises.add(exercise);
      }

      if (data['next'] == null) break;
      offset += _pageSize;
    }

    return exercises;
  }

  Future<Exercise?> _fetchExerciseInfoById(
    int id, {
    required String locale,
    required ExerciseTranslationStore? translationStore,
    String? imageUrl,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.wgerApiBase}/exerciseinfo/$id/');
      final response = await _http.get(uri);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseExerciseInfo(
        json,
        locale: locale,
        translationStore: translationStore,
        imageUrlOverride: imageUrl,
      );
    } catch (_) {
      return null;
    }
  }

  Exercise? _parseExerciseInfo(
    Map<String, dynamic> json, {
    required String locale,
    required ExerciseTranslationStore? translationStore,
    String? imageUrlOverride,
  }) {
    final id = json['id'] as int?;
    if (id == null) return null;

    final translation = _pickTranslation(json['translations'] as List? ?? [], locale);
    if (translation == null) return null;

    final name = translation['name'] as String? ?? '';
    if (name.isEmpty) return null;

    final description = (translation['description'] as String? ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    final muscles = (json['muscles'] as List? ?? [])
        .map((m) => m is Map
            ? Exercise.localizeMuscle(
                m['name_en'] as String? ?? m['name'] as String? ?? '',
                locale: locale,
              )
            : '')
        .where((s) => s.isNotEmpty)
        .toList();

    final categoryRaw = json['category'] is Map
        ? (json['category'] as Map)['name'] as String? ?? 'Other'
        : 'Other';
    final category = Exercise.localizeCategoryFromWger(categoryRaw, locale: locale);

    final aliases = <String>[];
    for (final t in json['translations'] as List? ?? []) {
      if (t is! Map<String, dynamic>) continue;
      final alias = t['name'] as String?;
      if (alias != null && alias.trim().isNotEmpty) {
        aliases.add(alias.trim());
      }
    }

    return _applyStoredTranslation(
      Exercise(
        wgerId: id,
        name: name,
        description: description,
        category: category,
        muscles: muscles,
        imageUrl: imageUrlOverride ?? _pickImageUrl(json),
        aliases: aliases,
      ),
      locale: locale,
      translationStore: translationStore,
    );
  }

  Exercise _applyStoredTranslation(
    Exercise exercise, {
    required String locale,
    required ExerciseTranslationStore? translationStore,
  }) {
    final store = translationStore;
    if (store == null || !store.isLoaded || exercise.wgerId == null) {
      return exercise;
    }

    final t = store.get(exercise.wgerId, locale);
    if (t == null || t.name.isEmpty) return exercise;

    return Exercise(
      wgerId: exercise.wgerId,
      catalogId: exercise.catalogId,
      supabaseId: exercise.supabaseId,
      name: t.name,
      description: t.description.isNotEmpty ? t.description : exercise.description,
      category: exercise.category,
      muscles: exercise.muscles,
      equipment: exercise.equipment,
      imageUrl: exercise.imageUrl,
      videoUrl: exercise.videoUrl,
      isCustom: exercise.isCustom,
      isUserCustom: exercise.isUserCustom,
      isBundled: exercise.isBundled,
      perArmWeight: exercise.perArmWeight,
      unilateral: exercise.unilateral,
      weightOptional: exercise.weightOptional,
      loadMode: exercise.loadMode,
      aliases: exercise.aliases,
      loggingType: exercise.loggingType,
      cardioConfig: exercise.cardioConfig,
    );
  }

  String? _pickImageUrl(Map<String, dynamic> json) {
    final images = json['images'] as List? ?? [];
    if (images.isEmpty) return null;

    Map<String, dynamic>? chosen;
    for (final item in images) {
      if (item is Map<String, dynamic> && item['is_main'] == true) {
        chosen = item;
        break;
      }
    }
    chosen ??= images.first is Map ? images.first as Map<String, dynamic> : null;
    final url = chosen?['image'] as String?;
    return url != null && url.isNotEmpty ? url : null;
  }

  Map<String, dynamic>? _pickTranslation(List translations, String locale) {
    final preferred = AppLocale.wgerLanguageId(locale);
    final fallback = AppLocale.wgerFallbackLanguageId(locale);
    Map<String, dynamic>? fallbackT;
    Map<String, dynamic>? any;

    for (final t in translations) {
      if (t is! Map<String, dynamic>) continue;
      final lang = t['language'];
      if (lang == preferred) return t;
      if (lang == fallback) fallbackT = t;
      any ??= t;
    }

    return fallbackT ?? any;
  }
}
