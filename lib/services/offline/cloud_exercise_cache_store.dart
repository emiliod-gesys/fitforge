import '../../core/utils/exercise_text_search.dart';
import '../../models/exercise.dart';
import '../../models/exercise_logging.dart';
import 'offline_json_file.dart';

/// Caché local del catálogo extendido (cloud) para uso offline.
class CloudExerciseCacheStore {
  static const _fileName = 'cloud_exercises_cache.json';

  List<Exercise> _exercises = [];
  String? _locale;
  DateTime? _downloadedAt;
  bool _loaded = false;

  bool get hasData => _exercises.isNotEmpty;
  int get count => _exercises.length;
  String? get locale => _locale;
  DateTime? get downloadedAt => _downloadedAt;
  List<Exercise> get all => List.unmodifiable(_exercises);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final state = await OfflineJsonFile.readMap(_fileName);
    _locale = state['locale'] as String?;
    final rawAt = state['downloaded_at'] as String?;
    _downloadedAt = rawAt != null ? DateTime.tryParse(rawAt) : null;
    final rawList = state['exercises'] as List? ?? [];
    _exercises = rawList
        .whereType<Map>()
        .map((e) => _deserialize(Map<String, dynamic>.from(e)))
        .toList();
    _loaded = true;
  }

  Future<void> saveAll(List<Exercise> exercises, String locale) async {
    _exercises = List<Exercise>.from(exercises);
    _locale = locale;
    _downloadedAt = DateTime.now().toUtc();
    _loaded = true;
    await OfflineJsonFile.writeMap(_fileName, {
      'locale': locale,
      'downloaded_at': _downloadedAt!.toIso8601String(),
      'count': exercises.length,
      'exercises': exercises.map(_serialize).toList(),
    });
  }

  Exercise? getById(String catalogId) {
    for (final exercise in _exercises) {
      if (exercise.id == catalogId) return exercise;
    }
    return null;
  }

  List<Exercise> browse({int limit = 40, int offset = 0}) {
    final sorted = List<Exercise>.from(_exercises)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (offset >= sorted.length) return const [];
    final end = (offset + limit).clamp(0, sorted.length);
    return sorted.sublist(offset, end);
  }

  List<Exercise> search(String query, {int limit = 40, int offset = 0}) {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final q = ExerciseTextSearch.normalize(trimmed);
    final filtered = _exercises.where((exercise) {
      return ExerciseTextSearch.matchesExercise(exercise, q);
    }).toList()
      ..sort((a, b) {
        final byScore = ExerciseTextSearch.score(b, q)
            .compareTo(ExerciseTextSearch.score(a, q));
        if (byScore != 0) return byScore;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    if (offset >= filtered.length) return const [];
    final end = (offset + limit).clamp(0, filtered.length);
    return filtered.sublist(offset, end);
  }

  Map<String, dynamic> _serialize(Exercise exercise) => {
        'catalog_id': exercise.catalogId,
        'supabase_id': exercise.supabaseId,
        'name': exercise.name,
        'description': exercise.description,
        'category': exercise.category,
        'muscles': exercise.muscles,
        'equipment': exercise.equipment,
        'image_url': exercise.imageUrl,
        'video_url': exercise.videoUrl,
        'per_arm_weight': exercise.perArmWeight,
        'unilateral': exercise.unilateral,
        'weight_optional': exercise.weightOptional,
        'logging_type': exercise.loggingType.name,
        'load_mode': exercise.loadMode.name,
        'is_bundled': exercise.isBundled,
      };

  Exercise _deserialize(Map<String, dynamic> json) {
    return Exercise(
      catalogId: json['catalog_id'] as String?,
      supabaseId: json['supabase_id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Otros',
      muscles: List<String>.from(json['muscles'] ?? const []),
      equipment: List<String>.from(json['equipment'] ?? const []),
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      perArmWeight: json['per_arm_weight'] as bool? ?? false,
      unilateral: json['unilateral'] as bool? ?? false,
      weightOptional: json['weight_optional'] as bool? ?? false,
      loggingType: ExerciseLoggingType.fromJson(json['logging_type'] as String?),
      loadMode: ExerciseLoadMode.fromJson(json['load_mode'] as String?),
      isBundled: json['is_bundled'] as bool? ?? false,
    );
  }
}
