import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/exercise.dart';

class ExerciseService {
  final _http = http.Client();
  List<Exercise>? _cache;

  Future<List<Exercise>> fetchExercises({String? search, String? category}) async {
    if (_cache != null && search == null && category == null) {
      return _cache!;
    }

    final exercises = <Exercise>[];
    var offset = 0;
    const limit = 50;

    while (offset < 200) {
      final uri = Uri.parse('${AppConstants.wgerApiBase}/exerciseinfo/').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
          'language': '4',
        },
      );

      final response = await _http.get(uri);
      if (response.statusCode != 200) break;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List? ?? [];
      if (results.isEmpty) break;

      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;
        final exercise = await _parseExerciseInfo(item);
        if (exercise != null) {
          if (search != null &&
              !exercise.name.toLowerCase().contains(search.toLowerCase())) {
            continue;
          }
          if (category != null && exercise.category != category) continue;
          exercises.add(exercise);
        }
      }

      if (data['next'] == null) break;
      offset += limit;
    }

    if (search == null && category == null) {
      _cache = exercises;
    }
    return exercises;
  }

  Future<Exercise?> _parseExerciseInfo(Map<String, dynamic> json) async {
    final id = json['id'] as int?;
    if (id == null) return null;

    String name = '';
    String description = '';
    final translations = json['translations'] as List? ?? [];
    for (final t in translations) {
      if (t is Map && t['language'] == 4) {
        name = t['name'] as String? ?? '';
        description = (t['description'] as String? ?? '').replaceAll(RegExp(r'<[^>]*>'), '');
        break;
      }
    }
    if (name.isEmpty) return null;

    final muscles = (json['muscles'] as List? ?? [])
        .map((m) => m is Map ? Exercise.translateMuscle(m['name_en'] as String? ?? m['name'] as String? ?? '') : '')
        .where((s) => s.isNotEmpty)
        .toList();

    final category = json['category'] is Map
        ? Exercise.translateCategory((json['category'] as Map)['name'] as String? ?? 'Otros')
        : 'Otros';

    final imageUrl = await _fetchExerciseImage(id);
    final videoUrl = await _fetchExerciseVideo(id);

    return Exercise(
      wgerId: id,
      name: name,
      description: description,
      category: category,
      muscles: muscles,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
    );
  }

  Future<String?> _fetchExerciseImage(int exerciseId) async {
    try {
      final uri = Uri.parse('${AppConstants.wgerApiBase}/exerciseimage/').replace(
        queryParameters: {'exercise': exerciseId.toString(), 'is_main': 'true'},
      );
      final response = await _http.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List? ?? [];
      if (results.isEmpty) return null;
      final image = results.first as Map<String, dynamic>;
      return image['image'] as String?;
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
}
