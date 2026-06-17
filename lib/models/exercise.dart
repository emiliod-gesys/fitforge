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
  final List<String> aliases;

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
    this.aliases = const [],
  });

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

    return Exercise(
      wgerId: json['id'] as int?,
      name: name,
      description: description.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
      category: translateCategory(category),
      muscles: muscles.map(translateMuscle).toList(),
      equipment: equipment,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
    );
  }

  factory Exercise.fromSupabase(Map<String, dynamic> json) {
    return Exercise(
      supabaseId: json['id'] as String?,
      wgerId: json['wger_id'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Otros',
      muscles: List<String>.from(json['muscles'] ?? []),
      equipment: List<String>.from(json['equipment'] ?? []),
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
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

  String get id => supabaseId ?? wgerId?.toString() ?? name;

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
}
