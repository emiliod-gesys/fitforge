import 'custom_exercise.dart';
import 'exercise_logging.dart';

class Exercise {
  final int? wgerId;
  final String? supabaseId;
  final String name;
  final String description;
  final String category;
  final List<String> muscles;
  final List<String> equipment;
  final String? imageUrl;
  final String? videoUrl;
  final bool isCustom;
  final bool isUserCustom;
  /// Solo ejercicios personalizados: peso registrado por brazo/mancuerna.
  final bool perArmWeight;
  final List<String> aliases;
  final ExerciseLoggingType loggingType;
  final CardioLoggingConfig? cardioConfig;

  const Exercise({
    this.wgerId,
    this.supabaseId,
    required this.name,
    this.description = '',
    this.category = 'Otros',
    this.muscles = const [],
    this.equipment = const [],
    this.imageUrl,
    this.videoUrl,
    this.isCustom = false,
    this.isUserCustom = false,
    this.perArmWeight = false,
    this.aliases = const [],
    this.loggingType = ExerciseLoggingType.strength,
    this.cardioConfig,
  });

  bool get isCardio => loggingType == ExerciseLoggingType.cardio;

  bool matchesName(String label) {
    final query = _normalize(label);
    if (query.isEmpty) return false;
    if (_normalize(name) == query) return true;
    for (final alias in aliases) {
      if (_normalize(alias) == query) return true;
    }
    return false;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

  factory Exercise.fromWgerJson(Map<String, dynamic> json) {
    final translations = json['translations'] as List? ?? [];
    String name = 'Ejercicio';
    String description = '';
    for (final t in translations) {
      if (t is Map && (t['language'] == 4 || t['language'] == 2)) {
        name = t['name'] as String? ?? name;
        description = t['description'] as String? ?? description;
        if (t['language'] == 4) break;
      }
    }

    final muscles = (json['muscles'] as List? ?? [])
        .map((m) => m is Map ? (m['name'] as String? ?? '') : '')
        .where((s) => s.isNotEmpty)
        .toList();

    final equipment = (json['equipment'] as List? ?? [])
        .map((e) => e is Map ? (e['name'] as String? ?? '') : '')
        .where((s) => s.isNotEmpty)
        .toList();

    final category = json['category'] is Map
        ? (json['category']['name'] as String? ?? 'Otros')
        : 'Otros';
    final localizedCategory = translateCategory(category);

    return Exercise(
      wgerId: json['id'] as int?,
      name: name,
      description: description.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
      category: localizedCategory,
      muscles: muscles.map(translateMuscle).toList(),
      equipment: equipment,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      loggingType: _inferLoggingType(localizedCategory, name: name),
      cardioConfig: _inferLoggingType(localizedCategory, name: name) == ExerciseLoggingType.cardio
          ? CardioLoggingConfig.fromPreset(CardioPreset.inferFromExerciseName(name))
          : null,
    );
  }

  factory Exercise.fromSupabase(Map<String, dynamic> json) {
    final category = json['category'] as String? ?? 'Otros';
    final name = json['name'] as String? ?? '';
    final loggingType = _inferLoggingType(category, name: name);
    return Exercise(
      supabaseId: json['id'] as String?,
      wgerId: json['wger_id'] as int?,
      name: name,
      description: json['description'] as String? ?? '',
      category: category,
      muscles: List<String>.from(json['muscles'] ?? []),
      equipment: List<String>.from(json['equipment'] ?? []),
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
      loggingType: loggingType,
      cardioConfig: loggingType == ExerciseLoggingType.cardio
          ? CardioLoggingConfig.fromPreset(
              CardioPreset.inferFromExerciseName(name),
            )
          : null,
    );
  }

  Map<String, dynamic> toSupabase() => {
        if (wgerId != null) 'wger_id': wgerId,
        'name': name,
        'description': description,
        'category': category,
        'muscles': muscles,
        'equipment': equipment,
        'image_url': imageUrl,
        'video_url': videoUrl,
        'is_custom': isCustom,
      };

  String get id {
    if (isUserCustom && supabaseId != null) {
      return '${CustomExercise.idPrefix}$supabaseId';
    }
    return supabaseId ?? wgerId?.toString() ?? name;
  }

  static String localizeCategoryFromWger(String cat, {String locale = 'es'}) {
    if (locale == 'en') return cat;
    return translateCategory(cat);
  }

  static String translateCategory(String cat) {
    const map = {
      'Arms': 'Brazos',
      'Legs': 'Piernas',
      'Abs': 'Abdominales',
      'Chest': 'Pecho',
      'Back': 'Espalda',
      'Shoulders': 'Hombros',
      'Calves': 'Pantorrillas',
      'Cardio': 'Cardio',
    };
    return map[cat] ?? cat;
  }

  static String localizeMuscle(String m, {String locale = 'es'}) {
    if (locale == 'es') return translateMuscle(m);
    const enMap = {
      'Biceps brachii': 'Biceps',
      'Triceps brachii': 'Triceps',
      'Pectoralis major': 'Chest',
      'Latissimus dorsi': 'Back',
      'Deltoid': 'Shoulders',
      'Quadriceps femoris': 'Quadriceps',
      'Gluteus maximus': 'Glutes',
      'Rectus abdominis': 'Abs',
    };
    return enMap[m] ?? m;
  }

  static String translateMuscle(String m) {
    const map = {
      'Biceps brachii': 'Bíceps',
      'Triceps brachii': 'Tríceps',
      'Pectoralis major': 'Pecho',
      'Latissimus dorsi': 'Espalda',
      'Deltoid': 'Hombros',
      'Quadriceps femoris': 'Cuádriceps',
      'Gluteus maximus': 'Glúteos',
      'Rectus abdominis': 'Abdominales',
    };
    return map[m] ?? m;
  }

  static ExerciseLoggingType _inferLoggingType(String category, {String name = ''}) {
    if (category.toLowerCase().contains('cardio')) {
      return ExerciseLoggingType.cardio;
    }
    if (CardioNameMatcher.matches(name)) {
      return ExerciseLoggingType.cardio;
    }
    return ExerciseLoggingType.strength;
  }
}
