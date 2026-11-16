import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../services/routine_limit_service.dart';
import 'ai_routine_sanitizer.dart';
import 'exercise_text_search.dart';
import 'muscle_inference.dart';

/// Utilidades de prompt y filtrado para rutinas generadas por el AI Coach.
abstract final class AiCoachRoutinePrompt {
  static const fullGymPhrases = [
    'gym completo',
    'gimnasio completo',
    'acceso a todo',
    'todo el gym',
    'todo el gimnasio',
    'full gym',
    'commercial gym',
    'gym comercial',
  ];

  static const _equipmentKeywords = <String, List<String>>{
    'dumbbell': ['mancuerna', 'mancuernas', 'dumbbell', 'dumbbells'],
    'barbell': ['barra', 'barbell', 'barra olimpica', 'barra olímpica', 'barra z', 'ez bar'],
    'machine': ['maquina', 'máquina', 'machine', 'maquinas', 'máquinas'],
    'cable': ['cable', 'polea', 'poleas', 'pulley'],
    'band': ['banda elastica', 'banda elástica', 'bandas elasticas', 'bandas elásticas', 'resistance band'],
    'bodyweight': [
      'peso corporal',
      'bodyweight',
      'sin equipo',
      'sin material',
      'casa sin equipo',
      'solo peso corporal',
    ],
    'kettlebell': ['kettlebell', 'pesa rusa', 'pesas rusas'],
    'smith': ['smith'],
    'bench': ['banco', 'bench'],
  };

  static bool mentionsFullGymAccess(String message) {
    final normalized = _normalize(message);
    return fullGymPhrases.any(normalized.contains);
  }

  /// «Solo con mancuernas» limita la rutina a ese equipo, no pide más detalles.
  static bool requestsExclusiveEquipment(String message) {
    final normalized = _normalize(message);
    const phrases = [
      'solo con',
      'solamente con',
      'unicamente con',
      'nada mas que',
      'only with',
      'just with',
      'only using',
    ];
    return phrases.any(normalized.contains);
  }

  /// Ejercicios que cumplen el músculo y el equipo dichos.
  static List<Exercise> matchingExercises({
    required List<Exercise> catalog,
    required List<String> equipment,
    required List<String> muscles,
  }) {
    final geared = filterCatalogByEquipment(catalog, equipment);
    final byMuscle = muscles.isEmpty
        ? geared
        : geared
            .where(
              (exercise) => muscles.any(
                (muscle) => MuscleInference.matchesMuscleGroup(
                  exercise: exercise,
                  muscleGroup: muscle,
                ),
              ),
            )
            .toList();
    final eligible = byMuscle.where(AiRoutineSanitizer.isEligibleForAi).toList();
    final pool = eligible.length >= 2 ? eligible : byMuscle;
    final strength = pool.where((exercise) => !exercise.isCardio).toList();
    final chosen = strength.length >= 2 ? strength : pool;
    chosen.sort((a, b) {
      final byPrimary = _primaryRank(a, muscles).compareTo(_primaryRank(b, muscles));
      if (byPrimary != 0) return byPrimary;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return chosen;
  }

  /// Rutina concreta cuando el pedido ya trae músculo y equipo.
  static Routine routineFromExercises({
    required List<Exercise> exercises,
    required List<String> muscles,
    required List<String> equipment,
    required String languageCode,
    required String userId,
    Map<String, int> frequent = const {},
  }) {
    final english = languageCode == 'en';
    final onlyLegs = muscles.isNotEmpty &&
        muscles.every((muscle) => muscle == 'Piernas' || muscle == 'Glúteos');
    final fullLegs = muscles.contains('Piernas') && muscles.contains('Glúteos');
    final picked = onlyLegs
        ? pickSpread(exercises, legs: true, frequent: frequent)
        : muscles.length >= 2
            ? pickAcross(exercises, muscles, frequent: frequent)
            : muscles.isEmpty
                ? pickBalanced(preferFrequent(exercises, frequent))
                : preferFrequent(exercises, frequent).take(6).toList();
    final now = DateTime.now();
    final gear = equipment.map((key) => equipmentLabel(key, languageCode: languageCode)).join(', ');
    final muscleNames = muscles
        .map((muscle) => english ? _muscleEnglish[muscle] ?? muscle : muscle)
        .join(english ? ' and ' : ' y ');
    final name = fullLegs
        ? (english ? 'Full legs' : 'Piernas completas')
        : gear.isEmpty
            ? (muscleNames.isEmpty ? (english ? 'Workout' : 'Rutina') : muscleNames)
            : muscleNames.isEmpty
                ? (english ? 'Workout with $gear' : 'Rutina con $gear')
                : (english ? '$muscleNames with $gear' : '$muscleNames con $gear');
    final description = fullLegs
        ? (english
            ? 'Quads, hamstrings, glutes and calves.'
            : 'Cuádriceps, isquios, glúteos y pantorrillas.')
        : gear.isEmpty
            ? (muscleNames.isEmpty
                ? (english ? 'Ready to review and save.' : 'Lista para revisar y guardar.')
                : (english ? '$muscleNames workout.' : 'Rutina de $muscleNames.'))
            : (muscleNames.isEmpty
                ? (english ? 'Exercises using only $gear.' : 'Ejercicios usando solo $gear.')
                : (english
                    ? '$muscleNames exercises using only $gear.'
                    : 'Ejercicios de $muscleNames usando solo $gear.'));

    return Routine(
      id: '',
      userId: userId,
      name: name,
      description: description,
      targetMuscles: muscles,
      exercises: [
        for (var i = 0; i < picked.length; i++)
          RoutineExercise(
            id: 'draft-$i-${picked[i].id}',
            exerciseId: picked[i].id,
            exerciseName: picked[i].name,
            orderIndex: i,
            imageUrl: picked[i].imageUrl,
            loggingType: picked[i].loggingType,
          ),
      ],
      createdAt: now,
      updatedAt: now,
      isAiGenerated: true,
    );
  }

  /// Cuántas veces el usuario ya hizo cada ejercicio.
  static Map<String, int> exerciseFrequency(Iterable<Workout> workouts) {
    final counts = <String, int>{};
    for (final workout in workouts) {
      for (final item in workout.exercises) {
        void bump(String key) {
          if (key.isEmpty) return;
          counts[key] = (counts[key] ?? 0) + 1;
        }

        bump(item.exerciseId);
        bump(ExerciseTextSearch.normalize(item.exerciseName));
      }
    }
    return counts;
  }

  static int _uses(Exercise exercise, Map<String, int> frequent) {
    final byId = frequent[exercise.id] ?? 0;
    final byName = frequent[ExerciseTextSearch.normalize(exercise.name)] ?? 0;
    return byId > byName ? byId : byName;
  }

  /// Los que ya hace van primero. El resto conserva el orden.
  static List<Exercise> preferFrequent(
    List<Exercise> exercises,
    Map<String, int> frequent,
  ) {
    if (frequent.isEmpty) return List<Exercise>.of(exercises);
    final indexed = exercises.asMap().entries.toList();
    indexed.sort((a, b) {
      final byUse = _uses(b.value, frequent).compareTo(_uses(a.value, frequent));
      if (byUse != 0) return byUse;
      return a.key.compareTo(b.key);
    });
    return indexed.map((entry) => entry.value).toList();
  }

  /// Reparte la sesión entre cada músculo pedido.
  static List<Exercise> pickAcross(
    List<Exercise> exercises,
    List<String> muscles, {
    int limit = 6,
    Map<String, int> frequent = const {},
  }) {
    final buckets = <String, List<Exercise>>{
      for (final muscle in muscles) muscle: <Exercise>[],
    };
    for (final exercise in exercises) {
      for (final muscle in muscles) {
        if (!MuscleInference.matchesMuscleGroup(
          exercise: exercise,
          muscleGroup: muscle,
        )) {
          continue;
        }
        buckets[muscle]!.add(exercise);
        break;
      }
    }
    for (final bucket in buckets.values) {
      final ordered = preferFrequent(bucket, frequent);
      bucket
        ..clear()
        ..addAll(ordered);
    }
    final picked = <Exercise>[];
    var guard = 0;
    while (picked.length < limit && guard < limit * 3) {
      var added = false;
      for (final muscle in muscles) {
        final bucket = buckets[muscle]!;
        if (bucket.isEmpty) continue;
        picked.add(bucket.removeAt(0));
        added = true;
        if (picked.length == limit) break;
      }
      if (!added) break;
      guard++;
    }
    return picked;
  }

  /// Una sesión variada cuando no nombraron un músculo.
  static List<Exercise> pickBalanced(List<Exercise> exercises, {int limit = 6}) {
    final buckets = <String, List<Exercise>>{};
    for (final exercise in exercises) {
      if (exercise.isCardio) continue;
      final key = MuscleInference.primaryRecoveryGroup(
            category: exercise.category,
            muscles: exercise.muscles,
          ) ??
          'Otros';
      (buckets[key] ??= []).add(exercise);
    }
    if (buckets.isEmpty) return exercises.take(limit).toList();
    const preferred = [
      'Pecho',
      'Espalda',
      'Piernas',
      'Hombros',
      'Glúteos',
      'Bíceps',
      'Tríceps',
      'Abdominales',
    ];
    final keys = [
      ...preferred.where(buckets.containsKey),
      ...buckets.keys.where((key) => !preferred.contains(key)),
    ];
    final picked = <Exercise>[];
    var guard = 0;
    while (picked.length < limit && guard < limit * 3) {
      var added = false;
      for (final key in keys) {
        final bucket = buckets[key]!;
        if (bucket.isEmpty) continue;
        picked.add(bucket.removeAt(0));
        added = true;
        if (picked.length == limit) break;
      }
      if (!added) break;
      guard++;
    }
    return picked;
  }

  /// Reparte una rutina de piernas entre cuádriceps, isquios, glúteo y pantorrilla.
  static List<Exercise> pickSpread(
    List<Exercise> exercises, {
    required bool legs,
    Map<String, int> frequent = const {},
  }) {
    if (!legs) return preferFrequent(exercises, frequent).take(6).toList();
    final buckets = <String, List<Exercise>>{
      'quad': [],
      'ham': [],
      'glute': [],
      'calf': [],
      'other': [],
    };
    for (final exercise in exercises) {
      buckets[_legBucket(exercise)]!.add(exercise);
    }
    for (final bucket in buckets.values) {
      final ordered = preferFrequent(bucket, frequent);
      bucket
        ..clear()
        ..addAll(ordered);
    }
    const order = ['quad', 'ham', 'glute', 'calf', 'other'];
    final picked = <Exercise>[];
    var guard = 0;
    while (picked.length < 6 && guard < 12) {
      var added = false;
      for (final key in order) {
        final bucket = buckets[key]!;
        if (bucket.isEmpty) continue;
        picked.add(bucket.removeAt(0));
        added = true;
        if (picked.length == 6) break;
      }
      if (!added) break;
      guard++;
    }
    return picked;
  }

  static String _legBucket(Exercise exercise) {
    final blob = _normalize('${exercise.name} ${exercise.muscles.join(' ')} ${exercise.category}');
    if (blob.contains('pantorrilla') ||
        blob.contains('gemelo') ||
        blob.contains('calf') ||
        blob.contains('soleo')) {
      return 'calf';
    }
    if (blob.contains('glute') || blob.contains('cadera') || blob.contains('hip thrust')) return 'glute';
    if (blob.contains('isquio') ||
        blob.contains('femoral') ||
        blob.contains('hamstring') ||
        blob.contains('peso muerto') ||
        blob.contains('rumano') ||
        blob.contains('deadlift')) {
      return 'ham';
    }
    if (blob.contains('cuadriceps') ||
        blob.contains('quad') ||
        blob.contains('sentadilla') ||
        blob.contains('squat') ||
        blob.contains('prensa') ||
        blob.contains('extension')) {
      return 'quad';
    }
    return 'other';
  }

  static int _primaryRank(Exercise exercise, List<String> muscles) {
    if (muscles.isEmpty) return 0;
    final primary = MuscleInference.primaryRecoveryGroup(
      category: exercise.category,
      muscles: exercise.muscles,
    );
    return muscles.contains(primary) ? 0 : 1;
  }

  static const _muscleEnglish = {
    'Pecho': 'Chest',
    'Espalda': 'Back',
    'Hombros': 'Shoulders',
    'Bíceps': 'Biceps',
    'Tríceps': 'Triceps',
    'Piernas': 'Legs',
    'Glúteos': 'Glutes',
    'Abdominales': 'Abs',
    'Antebrazos': 'Forearms',
    'Cardio': 'Cardio',
  };

  /// Equipamiento que el usuario dice tener disponible (claves normalizadas).
  static List<String> parseAvailableEquipment(String message) {
    if (mentionsFullGymAccess(message)) return const [];

    final normalized = _normalize(message);
    final found = <String>{};

    for (final entry in _equipmentKeywords.entries) {
      if (entry.value.any(normalized.contains)) {
        found.add(entry.key);
      }
    }

    return found.toList();
  }

  static List<Exercise> filterCatalogByEquipment(
    List<Exercise> catalog,
    List<String> availableEquipment,
  ) {
    if (availableEquipment.isEmpty) return catalog;
    return catalog
        .where((exercise) => exerciseMatchesAvailableEquipment(exercise, availableEquipment))
        .toList();
  }

  static bool exerciseMatchesAvailableEquipment(
    Exercise exercise,
    List<String> availableEquipment,
  ) {
    if (availableEquipment.isEmpty) return true;

    for (final equipment in availableEquipment) {
      if (_exerciseMatchesEquipmentKey(exercise, equipment)) return true;
    }
    return false;
  }

  static String buildRoutineLimitSection({
    required RoutineLimitStatus status,
    required String languageCode,
  }) {
    final lang = languageCode == 'en' ? 'en' : 'es';
    if (lang == 'en') {
      final buffer = StringBuffer()
        ..writeln('\n=== SAVED ROUTINE LIMIT ===')
        ..writeln('Saved routines: ${status.used} of ${status.limit}')
        ..writeln('Remaining slots: ${status.remaining}');
      if (!status.canCreate) {
        buffer.writeln(
          'IMPORTANT: the user cannot save more routines until they upgrade or delete one. '
          'If you generate a routine, warn them clearly that saving is blocked.',
        );
      } else if (status.remaining <= 2) {
        buffer.writeln(
          'WARNING: only ${status.remaining} routine slot(s) left. Mention this briefly when generating a routine.',
        );
      }
      return buffer.toString().trim();
    }

    final buffer = StringBuffer()
      ..writeln('\n=== LÍMITE DE RUTINAS GUARDADAS ===')
      ..writeln('Rutinas guardadas: ${status.used} de ${status.limit}')
      ..writeln('Espacios disponibles: ${status.remaining}');
    if (!status.canCreate) {
      buffer.writeln(
        'IMPORTANTE: el usuario NO puede guardar más rutinas hasta mejorar su plan o eliminar alguna. '
        'Si generas una rutina, adviértele claramente que no podrá guardarla.',
      );
    } else if (status.remaining <= 2) {
      buffer.writeln(
        'ADVERTENCIA: solo quedan ${status.remaining} espacio(s) para rutinas. Menciónalo brevemente al generar una rutina.',
      );
    }
    return buffer.toString().trim();
  }

  static String buildEquipmentSection({
    required List<String> availableEquipment,
    required String languageCode,
  }) {
    if (availableEquipment.isEmpty) return '';

    final labels = availableEquipment.map(equipmentLabel).join(', ');
    if (languageCode == 'en') {
      return '''
Available equipment (every exercise MUST be doable with this equipment only):
$labels
Do not suggest exercises that require other equipment.''';
    }
    return '''
Equipamiento disponible (cada ejercicio DEBE poder hacerse solo con esto):
$labels
No sugieras ejercicios que requieran otro equipamiento.''';
  }

  static String equipmentLabel(String key, {String languageCode = 'es'}) {
    if (languageCode == 'en') {
      return switch (key) {
        'dumbbell' => 'dumbbells',
        'barbell' => 'barbell',
        'machine' => 'machines',
        'cable' => 'cables',
        'band' => 'bands',
        'bodyweight' => 'bodyweight',
        'kettlebell' => 'kettlebells',
        'smith' => 'Smith machine',
        'bench' => 'bench',
        _ => key,
      };
    }
    return switch (key) {
      'dumbbell' => 'mancuernas',
      'barbell' => 'barra',
      'machine' => 'máquinas',
      'cable' => 'poleas/cables',
      'band' => 'bandas elásticas',
      'bodyweight' => 'peso corporal',
      'kettlebell' => 'kettlebells',
      'smith' => 'máquina Smith',
      'bench' => 'banco',
      _ => key,
    };
  }

  static String routineGenerationInstruction(String languageCode) {
    if (languageCode == 'en') {
      return '''
When the user asks for a workout routine or training plan to save in FORGEN, you MUST respond with valid routine JSON only (no markdown prose as the main answer) so the app can add it to their library.
Do not reply with a generic tip list when they asked for a routine; produce the structured routine.''';
    }
    return '''
Cuando el usuario pida una rutina o plan de entrenamiento para guardar en FORGEN, DEBES responder SOLO con JSON válido de rutina (sin markdown como respuesta principal) para que la app pueda agregarla.
No respondas con una lista genérica de consejos si pidió una rutina; genera la rutina estructurada.''';
  }

  static bool _exerciseMatchesEquipmentKey(Exercise exercise, String key) {
    final blob = _normalize('${exercise.equipment.join(' ')} ${exercise.name} ${exercise.category}');

    return switch (key) {
      'dumbbell' => blob.contains('mancuern') || blob.contains('dumbbell'),
      'barbell' =>
        blob.contains('barbell') ||
            blob.contains('barra') ||
            blob.contains('olympic') ||
            blob.contains('ez bar'),
      'machine' => blob.contains('maquina') || blob.contains('máquina') || blob.contains('machine'),
      'cable' => blob.contains('cable') || blob.contains('polea') || blob.contains('pulley'),
      'band' => blob.contains('banda') || blob.contains('band') || blob.contains('elastic'),
      'bodyweight' =>
        blob.contains('bodyweight') ||
            blob.contains('peso corporal') ||
            blob.contains('ninguno') ||
            blob.contains('none') ||
            exercise.equipment.isEmpty,
      'kettlebell' => blob.contains('kettlebell') || blob.contains('pesa rusa'),
      'smith' => blob.contains('smith'),
      'bench' => blob.contains('banco') || blob.contains('bench'),
      _ => false,
    };
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .trim();
  }
}
