import 'dart:io';

import '../core/constants/app_constants.dart';
import '../core/constants/exercise_catalog_source.dart';
import '../core/utils/exercise_catalog_visibility.dart';
import '../core/utils/exercise_matcher.dart';
import '../core/constants/cloud_exercise_catalog.dart';
import '../data/bundled_exercise_catalog.dart';
import '../data/cloud_exercise_catalog.dart';
import '../data/exercise_translation_store.dart';
import '../data/wger_exercise_catalog.dart';
import '../models/exercise.dart';
import 'custom_exercise_repository.dart';

class ExerciseMedia {
  final String? videoUrl;

  const ExerciseMedia({this.videoUrl});
}

/// Clave para resolver la imagen de un ejercicio en entrenos/rutinas.
class ExerciseImageLookup {
  final String exerciseId;
  final String exerciseName;

  const ExerciseImageLookup({
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  bool operator ==(Object other) {
    return other is ExerciseImageLookup &&
        other.exerciseId == exerciseId &&
        other.exerciseName == exerciseName;
  }

  @override
  int get hashCode => Object.hash(exerciseId, exerciseName);
}

class ExerciseService {
  final WgerExerciseCatalog _wgerCatalog = WgerExerciseCatalog();
  final CloudExerciseCatalog _cloudCatalog = CloudExerciseCatalog();
  List<Exercise>? _fullCache;
  final _mediaCache = <int, ExerciseMedia>{};
  String _preferredLanguage = 'es';
  ExerciseTranslationStore? _translationStore;
  CustomExerciseRepository? _customExerciseRepository;

  void setTranslationStore(ExerciseTranslationStore store) {
    _translationStore = store;
  }

  void setCustomExerciseRepository(CustomExerciseRepository repository) {
    _customExerciseRepository = repository;
  }

  void configure({required String language}) {
    if (_preferredLanguage != language) {
      _preferredLanguage = language;
      clearCache();
      _mediaCache.clear();
    }
  }

  Future<List<Exercise>> fetchExercises({String? search, String? category}) async {
    final full = await _fetchFullExercises();
    var list = _filterFullList(full, search: search, category: category);
    return ExerciseCatalogVisibility.filterBrowsable(list);
  }

  /// Catálogo extendido en Supabase (búsqueda bajo demanda, no embebido).
  Future<List<Exercise>> searchCloudExercises(String query) {
    return _cloudCatalog.search(query: query, locale: _preferredLanguage);
  }

  Future<Exercise?> getCloudExerciseById(String catalogId) {
    return _cloudCatalog.getById(catalogId: catalogId, locale: _preferredLanguage);
  }

  /// Catálogo completo en memoria + ejercicios wger resueltos bajo demanda (entrenos antiguos).
  Future<List<Exercise>> fetchFullExercises() async {
    await _fetchFullExercises();
    return [...?_fullCache, ..._wgerCatalog.onDemandExercises];
  }

  Future<List<Exercise>> _fetchFullExercises() async {
    if (_fullCache != null) {
      return _withFreshUserCustom(_fullCache!);
    }

    final List<Exercise> catalog;
    switch (AppConstants.exerciseCatalogSource) {
      case ExerciseCatalogSource.bundled:
        catalog = await BundledExerciseCatalog.load(locale: _preferredLanguage);
      case ExerciseCatalogSource.wger:
        catalog = await _wgerCatalog.fetchCatalog(
          locale: _preferredLanguage,
          translationStore: _translationStore,
          illustratedOnly: AppConstants.catalogRequireVisualMedia,
        );
    }

    final merged = List<Exercise>.from(catalog);
    merged.addAll(await _loadUserCustomExercises());
    merged.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    _fullCache = merged;
    return merged;
  }

  Future<Exercise?> _resolveLegacyWgerExercise(int wgerId) {
    return _wgerCatalog.resolveById(
      wgerId,
      locale: _preferredLanguage,
      translationStore: _translationStore,
    );
  }

  List<Exercise> _filterFullList(
    List<Exercise> full, {
    String? search,
    String? category,
  }) {
    return full.where((exercise) {
      if (search != null && !exercise.name.toLowerCase().contains(search.toLowerCase())) {
        return false;
      }
      if (category != null && exercise.category != category) return false;
      return true;
    }).toList();
  }

  Future<List<Exercise>> _loadUserCustomExercises() async {
    final repo = _customExerciseRepository;
    if (repo == null) return [];
    final custom = await repo.loadAll();
    return custom.map((c) => c.toExercise()).toList();
  }

  Future<List<Exercise>> _withFreshUserCustom(List<Exercise> base) async {
    final userCustom = await _loadUserCustomExercises();
    final catalog = base.where((e) => !e.isUserCustom).toList();
    catalog.addAll(userCustom);
    catalog.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _fullCache = catalog;
    return catalog;
  }

  String? _localImageIfExists(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return null;
    final file = File(path);
    return file.existsSync() ? path : null;
  }

  Future<ExerciseMedia> fetchExerciseMedia(int wgerId) async {
    if (wgerId < 0) return const ExerciseMedia();
    if (_mediaCache.containsKey(wgerId)) return _mediaCache[wgerId]!;

    final videoUrl = await _wgerCatalog.fetchVideoUrl(wgerId);
    final media = ExerciseMedia(videoUrl: videoUrl);
    _mediaCache[wgerId] = media;
    return media;
  }

  Exercise? findInCatalog({
    required String exerciseId,
    required String exerciseName,
    required List<Exercise> catalog,
  }) {
    if (CloudExerciseCatalogIds.isCloudId(exerciseId)) {
      return _cloudCatalog.getCached(exerciseId);
    }

    for (final e in catalog) {
      if (e.id == exerciseId) return e;
    }

    final parsed = int.tryParse(exerciseId);
    if (parsed != null) {
      for (final e in catalog) {
        if (e.wgerId == parsed) return e;
      }
    }

    for (final e in catalog) {
      if (e.matchesName(exerciseName) || e.matchesName(exerciseId)) return e;
    }

    return ExerciseMatcher.findBest(exerciseName, catalog) ??
        ExerciseMatcher.findBest(exerciseId, catalog);
  }

  /// Prioridad de imagen en UI:
  /// 1. URL del catálogo · 2. maniquí por categoría · 3. isotipo FitForge.
  Future<String?> resolveImageUrl(ExerciseImageLookup lookup) async {
    if (CloudExerciseCatalogIds.isCloudId(lookup.exerciseId)) {
      final cloud = await getCloudExerciseById(lookup.exerciseId);
      final url = cloud?.imageUrl;
      if (url != null && url.isNotEmpty) return url;
    }

    final catalog = await fetchFullExercises();
    var match = findInCatalog(
      exerciseId: lookup.exerciseId,
      exerciseName: lookup.exerciseName,
      catalog: catalog,
    );

    if (match == null) {
      final wgerId = int.tryParse(lookup.exerciseId);
      if (wgerId != null) {
        match = await _resolveLegacyWgerExercise(wgerId);
      }
    }
    if (match == null) return null;

    if (CustomExerciseRepository.isCustomExerciseId(lookup.exerciseId)) {
      return _localImageIfExists(match.imageUrl);
    }

    final catalogUrl = match.imageUrl;
    if (catalogUrl != null && catalogUrl.isNotEmpty) return catalogUrl;

    return null;
  }

  Future<Exercise?> getExerciseById(int wgerId) async {
    final exercises = await fetchFullExercises();
    try {
      return exercises.firstWhere((e) => e.wgerId == wgerId);
    } catch (_) {
      return _resolveLegacyWgerExercise(wgerId);
    }
  }

  Future<Exercise?> getExerciseByCatalogId(String catalogId) async {
    if (CloudExerciseCatalogIds.isCloudId(catalogId)) {
      return getCloudExerciseById(catalogId);
    }

    final exercises = await fetchFullExercises();
    try {
      return exercises.firstWhere((e) => e.catalogId == catalogId);
    } catch (_) {
      return null;
    }
  }

  String localizedName({
    required String exerciseId,
    required String fallback,
  }) {
    if (CloudExerciseCatalogIds.isCloudId(exerciseId)) {
      final cached = _cloudCatalog.getCached(exerciseId);
      if (cached != null) return cached.name;
      return fallback;
    }

    final store = _translationStore;
    if (store != null && store.isLoaded) {
      final fromStore = store.resolveName(
        exerciseId: exerciseId,
        fallback: fallback,
        locale: _preferredLanguage,
      );
      if (fromStore != fallback) return fromStore;
    }

    final catalog = _fullCache;
    if (catalog != null) {
      final match = findInCatalog(
        exerciseId: exerciseId,
        exerciseName: fallback,
        catalog: [...catalog, ..._wgerCatalog.onDemandExercises],
      );
      if (match != null) return match.name;
    }

    final wgerId = int.tryParse(exerciseId);
    if (wgerId != null) {
      for (final e in _wgerCatalog.onDemandExercises) {
        if (e.wgerId == wgerId) return e.name;
      }
    }

    return fallback;
  }

  List<String> getCategories(List<Exercise> exercises) {
    return exercises.map((e) => e.category).toSet().toList()..sort();
  }

  void clearCache() {
    _fullCache = null;
    BundledExerciseCatalog.clearCache();
    _wgerCatalog.clearCache();
    _cloudCatalog.clearCache();
  }
}
