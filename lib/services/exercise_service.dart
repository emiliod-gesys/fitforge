import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/utils/exercise_matcher.dart';
import '../data/supplemental_exercises.dart';
import '../models/exercise.dart';

class ExerciseMedia {
  final String? imageUrl;
  final String? videoUrl;

  const ExerciseMedia({this.imageUrl, this.videoUrl});
}

/// Clave para resolver la imagen de un ejercicio en entrenos/rutinas.
class ExerciseImageLookup {
  final String exerciseId;
  final String exerciseName;
  final String? imageUrl;

  const ExerciseImageLookup({
    required this.exerciseId,
    required this.exerciseName,
    this.imageUrl,
  });

  @override
  bool operator ==(Object other) {
    return other is ExerciseImageLookup &&
        other.exerciseId == exerciseId &&
        other.exerciseName == exerciseName &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => Object.hash(exerciseId, exerciseName, imageUrl);
}

class ExerciseService {
  final _http = http.Client();
  List<Exercise>? _cache;
  final _mediaCache = <int, ExerciseMedia>{};

  static const _spanishLang = 4;
  static const _englishLang = 2;
  static const _pageSize = 100;
  static const _maxExercises = 1500;

  Future<List<Exercise>> fetchExercises({String? search, String? category}) async {
    if (_cache != null && search == null && category == null) {
      return _cache!;
    }

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
        final exercise = _parseExerciseInfo(item);
        if (exercise == null) continue;
        if (search != null && !exercise.name.toLowerCase().contains(search.toLowerCase())) {
          continue;
        }
        if (category != null && exercise.category != category) continue;
        exercises.add(exercise);
      }

      if (data['next'] == null) break;
      offset += _pageSize;
    }

    final merged = SupplementalExercises.mergeWith(exercises);

    if (search == null && category == null) {
      _cache = merged;
    }
    return merged;
  }

  Exercise? _parseExerciseInfo(Map<String, dynamic> json) {
    final id = json['id'] as int?;
    if (id == null) return null;

    final translation = _pickTranslation(json['translations'] as List? ?? []);
    if (translation == null) return null;

    final name = translation['name'] as String? ?? '';
    if (name.isEmpty) return null;

    final description = (translation['description'] as String? ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    final muscles = (json['muscles'] as List? ?? [])
        .map((m) => m is Map ? Exercise.translateMuscle(m['name_en'] as String? ?? m['name'] as String? ?? '') : '')
        .where((s) => s.isNotEmpty)
        .toList();

    final category = json['category'] is Map
        ? Exercise.translateCategory((json['category'] as Map)['name'] as String? ?? 'Otros')
        : 'Otros';

    final aliases = <String>[];
    for (final t in json['translations'] as List? ?? []) {
      if (t is! Map<String, dynamic>) continue;
      final alias = t['name'] as String?;
      if (alias != null && alias.trim().isNotEmpty) {
        aliases.add(alias.trim());
      }
    }

    return Exercise(
      wgerId: id,
      name: name,
      description: description,
      category: category,
      muscles: muscles,
      imageUrl: _pickImageUrl(json),
      aliases: aliases,
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

  Map<String, dynamic>? _pickTranslation(List translations) {
    Map<String, dynamic>? english;
    Map<String, dynamic>? fallback;

    for (final t in translations) {
      if (t is! Map<String, dynamic>) continue;
      final lang = t['language'];
      if (lang == _spanishLang) return t;
      if (lang == _englishLang) english = t;
      fallback ??= t;
    }

    return english ?? fallback;
  }

  Future<ExerciseMedia> fetchExerciseMedia(int wgerId) async {
    if (wgerId < 0) return const ExerciseMedia();
    if (_mediaCache.containsKey(wgerId)) return _mediaCache[wgerId]!;

    final media = ExerciseMedia(
      imageUrl: await _fetchExerciseImage(wgerId),
      videoUrl: await _fetchExerciseVideo(wgerId),
    );
    _mediaCache[wgerId] = media;
    return media;
  }

  Exercise? findInCatalog({
    required String exerciseId,
    required String exerciseName,
    required List<Exercise> catalog,
  }) {
    final parsed = int.tryParse(exerciseId);
    if (parsed != null) {
      for (final e in catalog) {
        if (e.wgerId == parsed) return e;
      }
    }

    for (final e in catalog) {
      if (e.id == exerciseId) return e;
    }

    for (final e in catalog) {
      if (e.matchesName(exerciseName) || e.matchesName(exerciseId)) return e;
    }

    return ExerciseMatcher.findBest(exerciseName, catalog) ??
        ExerciseMatcher.findBest(exerciseId, catalog);
  }

  Future<String?> resolveImageUrl(ExerciseImageLookup lookup) async {
    if (lookup.imageUrl != null && lookup.imageUrl!.isNotEmpty) {
      return lookup.imageUrl;
    }

    final catalog = await fetchExercises();
    final match = findInCatalog(
      exerciseId: lookup.exerciseId,
      exerciseName: lookup.exerciseName,
      catalog: catalog,
    );
    if (match == null) return null;

    if (match.imageUrl != null && match.imageUrl!.isNotEmpty) {
      return match.imageUrl;
    }

    final wgerId = match.wgerId;
    if (wgerId == null || wgerId < 0) return null;

    return (await fetchExerciseMedia(wgerId)).imageUrl;
  }

  Future<String?> _fetchExerciseImage(int exerciseId) async {
    try {
      // wger renombró el filtro `exercise` → `exercise_base`.
      for (final param in ['exercise_base', 'exercise']) {
        final uri = Uri.parse('${AppConstants.wgerApiBase}/exerciseimage/').replace(
          queryParameters: {param: exerciseId.toString(), 'is_main': 'true'},
        );
        final response = await _http.get(uri);
        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        if (results.isEmpty) continue;

        for (final item in results) {
          if (item is Map<String, dynamic> && item['is_main'] == true) {
            return item['image'] as String?;
          }
        }
        final first = results.first;
        if (first is Map<String, dynamic>) return first['image'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fetchExerciseVideo(int exerciseId) async {
    try {
      final uri = Uri.parse('${AppConstants.wgerApiBase}/video/').replace(
        queryParameters: {'exercise': exerciseId.toString()},
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

  Future<Exercise?> getExerciseById(int wgerId) async {
    final exercises = await fetchExercises();
    try {
      return exercises.firstWhere((e) => e.wgerId == wgerId);
    } catch (_) {
      return null;
    }
  }

  List<String> getCategories(List<Exercise> exercises) {
    return exercises.map((e) => e.category).toSet().toList()..sort();
  }

  void clearCache() => _cache = null;
}
