import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/utils/ai_coach_context.dart';
import '../core/utils/ai_routine_sanitizer.dart';
import '../core/utils/exercise_matcher.dart';
import '../core/utils/food_estimate_parser.dart';
import '../core/utils/food_query_hints.dart';
import '../core/utils/gym_weight.dart';
import '../core/utils/proactive_workout_ai_rules.dart';
import '../core/utils/unit_converter.dart';
import '../core/utils/workout_streak.dart';
import '../core/utils/workout_suggestion_context.dart';
import '../models/body_metric.dart';
import '../models/coach_nutrition_snapshot.dart';
import '../models/exercise.dart';
import '../models/exercise_logging.dart';
import '../models/food_entry.dart';
import '../models/profile.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import 'profile_service.dart';

class AiCoachService {
  AiCoachService(this._profileService);

  final ProfileService _profileService;

  Future<({AiProvider provider, String apiKey})> _resolveCredentials(
    UserProfile? profile,
  ) async {
    final provider = _profileService.resolveAiProvider(profile);
    if (provider == AiProvider.none) {
      throw Exception('Configura un proveedor de IA en tu perfil');
    }
    final apiKey = await _profileService.getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Configura tu API key en el perfil');
    }
    return (provider: provider, apiKey: apiKey);
  }

  static bool isRoutineSaveIntent(String message) {
    final m = message.toLowerCase().trim();
    final hasCreateVerb = _hasRoutineCreateVerb(m);
    if (hasCreateVerb) return false;

    const savePhrases = [
      'guarda la rutina',
      'guardar rutina',
      'guárdala como rutina',
      'guardala como rutina',
      'guárdala',
      'guardala',
      'save the routine',
      'save routine',
    ];
    if (savePhrases.any(m.contains)) return true;

    return m == 'guarda' || m == 'guardar' || m == 'save';
  }

  static bool requestsRoutineAutoSave(String message) {
    final m = message.toLowerCase();
    return _hasRoutineCreateVerb(m) && (m.contains('guarda') || m.contains('save'));
  }

  static bool _hasRoutineCreateVerb(String m) {
    return m.contains('crea') ||
        m.contains('haz') ||
        m.contains('genera') ||
        m.contains('arma') ||
        m.contains('diseña') ||
        m.contains('disena') ||
        m.contains('muéstrame') ||
        m.contains('muestrame') ||
        m.contains('necesito') ||
        m.contains('quiero') ||
        m.contains('dame') ||
        m.contains('prepara') ||
        m.contains('monta') ||
        m.contains('elabora') ||
        m.contains('create') ||
        m.contains('make') ||
        m.contains('build') ||
        m.contains('design') ||
        m.contains('give me');
  }

  static bool isMultiRoutineProgramRequest(String message) {
    final m = _normalizeRoutineTypos(message);
    const keywords = [
      'toda la semana',
      'toda semana',
      'semana completa',
      'semanal',
      'weekly',
      'whole week',
      'for the week',
      'per week',
      'each day',
      'cada día',
      'cada dia',
      'ulppl',
      'ppl',
      'push pull leg',
      'push/pull',
      'upper lower',
      'upper/lower',
      'varias rutinas',
      'multiple routines',
      'split semanal',
      'plan semanal',
      'programa semanal',
      'rutina semanal',
      'weekly split',
      'weekly program',
      'training split',
      'workout split',
      'week plan',
      'plan de la semana',
    ];
    if (keywords.any(m.contains)) return true;

    if (RegExp(r'\b[3-7]\s*d[ií]as').hasMatch(m) && _mentionsRoutineOrPlan(m)) {
      return true;
    }
    if (RegExp(r'\b[3-7]\s*day').hasMatch(m) && _mentionsRoutineOrPlan(m)) {
      return true;
    }

    return false;
  }

  static int expectedProgramRoutineCount(String message) {
    final m = _normalizeRoutineTypos(message);
    if (m.contains('ulppl')) return 5;
    if (RegExp(r'\bppl\b').hasMatch(m) && !m.contains('ulppl')) return 6;
    if (m.contains('upper lower') || m.contains('upper/lower')) return 4;

    final esDays = RegExp(r'(\d+)\s*d[ií]as').firstMatch(m);
    if (esDays != null) {
      final n = int.tryParse(esDays.group(1)!);
      if (n != null && n >= 2 && n <= 7) return n;
    }
    final enDays = RegExp(r'(\d+)\s*day').firstMatch(m);
    if (enDays != null) {
      final n = int.tryParse(enDays.group(1)!);
      if (n != null && n >= 2 && n <= 7) return n;
    }

    if (isMultiRoutineProgramRequest(message)) return 5;
    return 3;
  }

  static bool _mentionsRoutineOrPlan(String m) {
    return RegExp(r'rutin\w*').hasMatch(m) ||
        m.contains('entrenamiento') ||
        m.contains('workout') ||
        m.contains('plan de') ||
        m.contains('programa de');
  }

  static bool _mentionsBodyRegionOrSplit(String m) {
    const regions = [
      'tren superior',
      'tren inferior',
      'parte superior',
      'parte inferior',
      'upper body',
      'lower body',
      'push pull',
      'push day',
      'pull day',
      'leg day',
      'día de piernas',
      'dia de piernas',
    ];
    return regions.any(m.contains);
  }

  static bool userSpecifiedDuration(String message) {
    final m = message.toLowerCase();
    return RegExp(r'(\d+)\s*(min|minutos|mins?)\b').hasMatch(m) ||
        RegExp(r'\b1\s*h(ora|oras)?\b').hasMatch(m) ||
        RegExp(r'\b90\b').hasMatch(m);
  }

  static String _normalizeRoutineTypos(String message) {
    return message
        .toLowerCase()
        .replaceAll(RegExp(r'\bretina\b'), 'rutina')
        .replaceAll(RegExp(r'\brutna\b'), 'rutina');
  }

  static bool isRoutineCreationRequest(String message) {
    if (isRoutineSaveIntent(message)) return false;

    final m = _normalizeRoutineTypos(message);
    const triggers = [
      'crea una rutina',
      'crear rutina',
      'créame una rutina',
      'hazme una rutina',
      'haz una rutina',
      'genera una rutina',
      'generar rutina',
      'arma una rutina',
      'arma me una rutina',
      'diseña una rutina',
      'disena una rutina',
      'muéstrame una rutina',
      'muestrame una rutina',
      'necesito una rutina',
      'quiero una rutina',
      'crea un entrenamiento',
      'crear entrenamiento',
      'hazme un entrenamiento',
      'haz un entrenamiento',
      'genera un entrenamiento',
      'plan de entrenamiento',
      'programa de entrenamiento',
      'create a workout',
      'create a routine',
      'make me a workout',
      'make a routine',
    ];

    if (triggers.any(m.contains)) return true;

    if (RegExp(r'rutin\w*\s+(de|para)\b').hasMatch(m)) return true;

    if (RegExp(r'entrenamiento\s+(de|para)\b').hasMatch(m)) return true;

    if ((m.contains('editable') || m.contains('editar') || m.contains('revisar')) &&
        (m.contains('rutin') || m.contains('plan') || m.contains('entrenamiento'))) {
      return true;
    }

    final muscles = parseTargetMuscles(message);
    if (muscles.isNotEmpty && _hasTrainingPlanIntent(m)) return true;

    if (_hasRoutineCreateVerb(m) && _mentionsRoutineOrPlan(m)) return true;

    if (_hasRoutineCreateVerb(m) && _mentionsBodyRegionOrSplit(m)) return true;

    if (_hasRoutineCreateVerb(m) &&
        (m.contains('enfocad') || m.contains('orientad')) &&
        (m.contains('fuerza') ||
            m.contains('hipertrof') ||
            m.contains('resistencia') ||
            muscles.isNotEmpty ||
            _mentionsBodyRegionOrSplit(m))) {
      return true;
    }

    if (isMultiRoutineProgramRequest(message) && _hasRoutineCreateVerb(m)) return true;

    if (isMultiRoutineProgramRequest(message) &&
        RegExp(r'\b(create|make|build|design|give me|crea|haz|genera|dame)\b').hasMatch(m)) {
      return true;
    }

    if (RegExp(r'creat\w*').hasMatch(m) && RegExp(r'routin\w*').hasMatch(m)) return true;

    return RegExp(r'rutin\w*').hasMatch(m) && _hasRoutineCreateVerb(m);
  }

  static bool _hasTrainingPlanIntent(String m) {
    return _hasRoutineCreateVerb(m) ||
        m.contains('entren') ||
        m.contains('ejercicios para') ||
        m.contains('qué hago') ||
        m.contains('que hago') ||
        m.contains('rutina') ||
        m.contains('plan');
  }

  static const _routineRules = '''
REGLAS OBLIGATORIAS:
- Entre 4 y 8 ejercicios DIFERENTES; nunca repitas el mismo ejercicio.
- Usa SOLO nombres EXACTOS copiados de la lista proporcionada (todos tienen imagen ilustrativa).
- No uses nombres genéricos de músculo (ej. "bíceps", "tríceps", "pecho") ni inventados.
- No inventes nombres como "ejercicio de prueba" o "ejercicio 1".
- Si el objetivo incluye varios músculos, incluye ejercicios variados para cada uno.
- Para bíceps y tríceps: mínimo 2 ejercicios de bíceps y 2 de tríceps, todos distintos.
''';

  /// Intenta extraer una rutina JSON embebida en una respuesta de chat libre.
  Routine? tryParseRoutineFromResponse(
    String response, {
    required List<String> targetMuscles,
    UserProfile? profile,
    List<Exercise>? catalog,
  }) {
    final routine = _parseRoutineJson(
      response,
      targetMuscles: targetMuscles,
      profile: profile,
    );
    if (routine == null || catalog == null) return routine;
    return ExerciseMatcher.enrich(routine, catalog);
  }

  static int parseDurationMinutes(String message) {
    final minMatch = RegExp(r'(\d+)\s*(min|minutos|mins?)', caseSensitive: false).firstMatch(message);
    if (minMatch != null) {
      return int.tryParse(minMatch.group(1)!) ?? 45;
    }
    if (RegExp(r'1\s*h(ora|oras)?', caseSensitive: false).hasMatch(message)) return 60;
    if (RegExp(r'\b90\b', caseSensitive: false).hasMatch(message)) return 90;
    return 45;
  }

  static List<String> parseTargetMuscles(String message) {
    final m = _normalizeRoutineTypos(message);
    final found = <String>{};

    if (m.contains('tren superior') ||
        m.contains('parte superior') ||
        m.contains('upper body')) {
      found.addAll(['Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps']);
    }
    if (m.contains('tren inferior') ||
        m.contains('parte inferior') ||
        m.contains('lower body') ||
        m.contains('leg day') ||
        m.contains('día de piernas') ||
        m.contains('dia de piernas')) {
      found.addAll(['Piernas', 'Glúteos']);
    }
    if (m.contains('push day') || (m.contains('push') && !m.contains('pull'))) {
      found.addAll(['Pecho', 'Hombros', 'Tríceps']);
    }
    if (m.contains('pull day') || (m.contains('pull') && !m.contains('push'))) {
      found.addAll(['Espalda', 'Bíceps']);
    }

    const keywords = <String, String>{
      'pierna': 'Piernas',
      'piernas': 'Piernas',
      'leg': 'Piernas',
      'cuadriceps': 'Piernas',
      'cuádriceps': 'Piernas',
      'pecho': 'Pecho',
      'chest': 'Pecho',
      'espalda': 'Espalda',
      'back': 'Espalda',
      'hombro': 'Hombros',
      'hombros': 'Hombros',
      'shoulder': 'Hombros',
      'biceps': 'Bíceps',
      'bíceps': 'Bíceps',
      'triceps': 'Tríceps',
      'tríceps': 'Tríceps',
      'gluteo': 'Glúteos',
      'glúteo': 'Glúteos',
      'gluteos': 'Glúteos',
      'abdominal': 'Abdominales',
      'abdominales': 'Abdominales',
      'core': 'Abdominales',
      'antebrazo': 'Antebrazos',
      'cardio': 'Cardio',
      'full body': 'Pecho',
      'cuerpo completo': 'Pecho',
    };

    for (final entry in keywords.entries) {
      if (m.contains(entry.key)) found.add(entry.value);
    }

    return found.toList();
  }

  static String languageInstruction(String languageCode) {
    final normalized = languageCode == 'en' ? 'en' : 'es';
    if (normalized == 'en') {
      return 'Respond in the same language the user writes in. '
          'Default to English when the language is unclear. '
          'If the user asks about languages, confirm you can communicate in English and Spanish.';
    }
    return 'Responde en el mismo idioma en que escribe el usuario. '
        'Por defecto usa español si no está claro. '
        'Si preguntan por idiomas, confirma que puedes comunicarte en español e inglés.';
  }

  static String fitnessScopeInstruction(String languageCode) {
    final normalized = languageCode == 'en' ? 'en' : 'es';
    if (normalized == 'en') {
      return 'ONLY answer questions related to fitness: training, exercise technique, '
          'workout programming, sports nutrition, recovery, physical health tied to exercise, '
          'and using FitForge. Politely decline off-topic requests (general knowledge, coding, '
          'politics, homework, etc.) and offer to help with fitness instead.';
    }
    return 'Responde ÚNICAMENTE preguntas relacionadas con fitness: entrenamiento, técnica de '
        'ejercicios, programación de rutinas, nutrición deportiva, recuperación, salud física '
        'vinculada al ejercicio y uso de FitForge. Rechaza amablemente temas ajenos (cultura '
        'general, programación, política, deberes, etc.) y ofrece ayuda con fitness.';
  }

  static String _resolveLanguageCode({
    String? languageCode,
    UserProfile? profile,
  }) {
    final fromProfile = profile?.preferredLanguage;
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    if (languageCode != null && languageCode.isNotEmpty) return languageCode;
    return 'es';
  }

  Future<String> getRecommendation({
    required String userMessage,
    List<Workout>? recentWorkouts,
    List<Routine>? routines,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    WorkoutWeeklyStats? weeklyStats,
    List<PersonalRecord>? personalRecords,
    String? languageCode,
    CoachNutritionSnapshot? nutrition,
  }) async {
    final credentials = await _resolveCredentials(profile);
    final aiProvider = credentials.provider;
    final apiKey = credentials.apiKey;
    final metrics = bodyMetrics ?? await _profileService.getBodyMetricSnapshots();
    final context = AiCoachContextBuilder.build(
      profile: profile,
      bodyMetrics: metrics,
      weeklyStats: weeklyStats,
      personalRecords: personalRecords,
      recentWorkouts: recentWorkouts,
      routines: routines,
      nutrition: nutrition,
    );
    final usesLb = profile != null && UnitConverter.isLb(profile.unitSystem);
    final weightUnit = usesLb ? 'libras (lb)' : 'kilogramos (kg)';
    final progressionHint = usesLb ? '+5 lb o +5%' : '+2.5 kg o +5%';
    final lang = _resolveLanguageCode(languageCode: languageCode, profile: profile);
    final systemPrompt = '''
Eres FitForge Coach, un entrenador personal experto en fuerza e hipertrofia.
${languageInstruction(lang)} Sé conciso pero útil.
${fitnessScopeInstruction(lang)}
Tienes acceso al perfil completo del usuario: datos personales, objetivo, métricas corporales, nivel, racha, records, historial de entrenos y nutrición.
La ingesta del día se actualiza en tiempo real; también tienes el historial nutricional de los últimos 7 días.
Usa esa información para personalizar ejercicios, volumen, series, reps, progresión y consejos de nutrición (macros, timing pre/post entreno, déficit/superávit) según su propósito y estado actual.
Basándote en el historial del usuario, recomienda ejercicios, rutinas, pesos, series y reps.
El usuario usa $weightUnit para pesos. Si sugieres pesos, exprésalos en $weightUnit con progresión gradual ($progressionHint).
Formato: usa listas y secciones claras.
Si el usuario pide crear una rutina editable, responde solo con un resumen breve (la app generará la rutina estructurada por separado).
No escribas rutinas completas en markdown cuando pidan crearlas en la app.

Contexto del usuario:
$context
''';

    switch (aiProvider) {
      case AiProvider.openai:
        return _callOpenAI(apiKey, systemPrompt, userMessage);
      case AiProvider.gemini:
        return _callGemini(apiKey, systemPrompt, userMessage);
      case AiProvider.anthropic:
        return _callAnthropic(apiKey, systemPrompt, userMessage);
      case AiProvider.none:
        throw Exception('Proveedor no configurado');
    }
  }

  Future<Routine?> generateRoutineFromMessage({
    required String userMessage,
    required List<Exercise> catalog,
    UserProfile? profile,
    List<Workout>? recentWorkouts,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    WorkoutWeeklyStats? weeklyStats,
    List<PersonalRecord>? personalRecords,
    List<Routine>? routines,
    String? languageCode,
    CoachNutritionSnapshot? nutrition,
  }) async {
    final targetMuscles = parseTargetMuscles(userMessage);
    final duration = parseDurationMinutes(userMessage);
    final durationLine = userSpecifiedDuration(userMessage)
        ? 'Duración solicitada: $duration minutos.'
        : 'El usuario no indicó duración; diseña una rutina de aproximadamente $duration minutos.';
    final lang = _resolveLanguageCode(languageCode: languageCode, profile: profile);
    final routineLanguageHint = lang == 'en'
        ? 'Write the routine name and description in English.'
        : 'Escribe el nombre y la descripción de la rutina en español.';
    final aiCatalog = AiRoutineSanitizer.catalogForAi(catalog);
    final names = AiRoutineSanitizer.namesForMuscles(aiCatalog, targetMuscles);
    final userContext = await _loadUserContext(
      profile: profile,
      bodyMetrics: bodyMetrics,
      weeklyStats: weeklyStats,
      personalRecords: personalRecords,
      recentWorkouts: recentWorkouts,
      routines: routines,
      nutrition: nutrition,
    );

    final prompt = '''
El usuario pidió lo siguiente:
"$userMessage"

Genera una rutina de gimnasio.
$durationLine
Músculos objetivo: ${targetMuscles.isEmpty ? 'equilibrada según el mensaje y el perfil' : targetMuscles.join(', ')}.

Perfil y contexto del usuario (úsalo para adaptar ejercicios, volumen y dificultad):
$userContext

$routineLanguageHint

$_routineRules

IMPORTANTE: usa SOLO nombres de ejercicio de esta lista (copia el nombre exacto):
${names.take(100).join('\n')}

Responde SOLO con JSON válido (sin markdown ni texto extra):
{
  "name": "nombre corto de la rutina",
  "description": "breve descripción",
  "target_muscles": ["Piernas"],
  "exercises": [
    {"name": "nombre exacto de la lista", "sets": 3, "reps": 10, "weight_kg": null, "rest_seconds": 90}
  ]
}
''';

    final response = await _complete(
      profile: profile,
      systemPrompt: '''
Eres un generador de rutinas de gimnasio para FitForge.
Responde ÚNICAMENTE con JSON válido. Sin markdown, sin texto adicional.
${fitnessScopeInstruction(lang)}
$_routineRules
''',
      userPrompt: prompt,
    );

    final routine = _parseRoutineJson(
      response,
      targetMuscles: targetMuscles,
      profile: profile,
    );
    if (routine == null) return null;

    return ExerciseMatcher.enrich(routine, catalog);
  }

  Future<List<Routine>> generateRoutineProgramFromMessage({
    required String userMessage,
    required List<Exercise> catalog,
    UserProfile? profile,
    List<Workout>? recentWorkouts,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    WorkoutWeeklyStats? weeklyStats,
    List<PersonalRecord>? personalRecords,
    List<Routine>? routines,
    String? languageCode,
    CoachNutritionSnapshot? nutrition,
  }) async {
    final targetMuscles = parseTargetMuscles(userMessage);
    final duration = parseDurationMinutes(userMessage);
    final durationLine = userSpecifiedDuration(userMessage)
        ? 'Duración por sesión: $duration minutos.'
        : 'El usuario no indicó duración; cada sesión debe durar aproximadamente $duration minutos.';
    final routineCount = expectedProgramRoutineCount(userMessage);
    final lang = _resolveLanguageCode(languageCode: languageCode, profile: profile);
    final routineLanguageHint = lang == 'en'
        ? 'Write routine names and descriptions in English.'
        : 'Escribe nombres y descripciones en español.';
    final aiCatalog = AiRoutineSanitizer.catalogForAi(catalog);
    final names = AiRoutineSanitizer.namesForMuscles(aiCatalog, targetMuscles);
    final userContext = await _loadUserContext(
      profile: profile,
      bodyMetrics: bodyMetrics,
      weeklyStats: weeklyStats,
      personalRecords: personalRecords,
      recentWorkouts: recentWorkouts,
      routines: routines,
      nutrition: nutrition,
    );

    final prompt = '''
El usuario pidió lo siguiente:
"$userMessage"

Genera un programa con EXACTAMENTE $routineCount rutinas distintas (una por día de entrenamiento).
$durationLine
Músculos objetivo globales: ${targetMuscles.isEmpty ? 'según el split y el perfil' : targetMuscles.join(', ')}.

Perfil y contexto del usuario:
$userContext

$routineLanguageHint

$_routineRules
- Cada rutina es un día de entrenamiento independiente con nombre claro (ej. "Upper (Fuerza)", "Push hipertrofia").
- Varía ejercicios entre días; no repitas la misma rutina.

IMPORTANTE: usa SOLO nombres de ejercicio de esta lista (copia el nombre exacto):
${names.take(120).join('\n')}

Responde SOLO con JSON válido (sin markdown ni texto extra):
{
  "routines": [
    {
      "name": "nombre del día",
      "description": "breve descripción",
      "target_muscles": ["Pecho"],
      "exercises": [
        {"name": "nombre exacto de la lista", "sets": 3, "reps": 10, "weight_kg": null, "rest_seconds": 90}
      ]
    }
  ]
}
''';

    final response = await _complete(
      profile: profile,
      systemPrompt: '''
Eres un generador de programas de entrenamiento para FitForge.
Responde ÚNICAMENTE con JSON válido. Sin markdown, sin texto adicional.
${fitnessScopeInstruction(lang)}
$_routineRules
''',
      userPrompt: prompt,
    );

    final parsed = _parseRoutineProgramJson(
      response,
      targetMuscles: targetMuscles,
      profile: profile,
    );
    if (parsed.isEmpty) return const [];

    return parsed
        .map((routine) => ExerciseMatcher.enrich(routine, catalog))
        .where((routine) => routine.exercises.length >= 2)
        .toList();
  }

  Future<Routine?> generateRoutine({
    required List<String> targetMuscles,
    required int durationMinutes,
    UserProfile? profile,
    List<Workout>? recentWorkouts,
    List<Exercise>? catalog,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    WorkoutWeeklyStats? weeklyStats,
    List<PersonalRecord>? personalRecords,
    List<Routine>? routines,
    CoachNutritionSnapshot? nutrition,
  }) async {
    final names = catalog != null
        ? AiRoutineSanitizer.namesForMuscles(AiRoutineSanitizer.catalogForAi(catalog), targetMuscles)
        : <String>[];
    final userContext = await _loadUserContext(
      profile: profile,
      bodyMetrics: bodyMetrics,
      weeklyStats: weeklyStats,
      personalRecords: personalRecords,
      recentWorkouts: recentWorkouts,
      routines: routines,
      nutrition: nutrition,
    );

    final catalogHint = names.isEmpty
        ? ''
        : '\nUsa SOLO nombres de esta lista:\n${names.take(80).join(', ')}';

    final prompt = '''
Genera una rutina de gimnasio de $durationMinutes minutos enfocada en: ${targetMuscles.join(', ')}.

Perfil y contexto del usuario (úsalo para adaptar ejercicios, volumen y dificultad):
$userContext
$catalogHint

$_routineRules

Responde SOLO con JSON válido (sin markdown):
{
  "name": "nombre de la rutina",
  "description": "breve descripción",
  "target_muscles": ${jsonEncode(targetMuscles)},
  "exercises": [
    {"name": "nombre ejercicio", "sets": 3, "reps": 10, "weight_kg": null, "rest_seconds": 90, "logging_type": "strength"},
    {"name": "cinta", "sets": 1, "logging_type": "cardio", "duration_seconds": 1200, "distance_meters": 3000, "incline_percent": 5, "rest_seconds": 0}
  ]
}
''';

    final lang = _resolveLanguageCode(profile: profile);
    final response = await _complete(
      profile: profile,
      systemPrompt: '''
Eres un generador de rutinas de gimnasio para FitForge.
Responde ÚNICAMENTE con JSON válido. Sin markdown, sin texto adicional.
${fitnessScopeInstruction(lang)}
$_routineRules
''',
      userPrompt: prompt,
    );

    final routine = _parseRoutineJson(
      response,
      targetMuscles: targetMuscles,
      profile: profile,
    );
    if (routine == null || catalog == null) return routine;

    return ExerciseMatcher.enrich(routine, catalog);
  }

  Future<String> _complete({
    required UserProfile? profile,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final credentials = await _resolveCredentials(profile);
    final aiProvider = credentials.provider;
    final apiKey = credentials.apiKey;

    switch (aiProvider) {
      case AiProvider.openai:
        return _callOpenAI(apiKey, systemPrompt, userPrompt);
      case AiProvider.gemini:
        return _callGemini(apiKey, systemPrompt, userPrompt);
      case AiProvider.anthropic:
        return _callAnthropic(apiKey, systemPrompt, userPrompt);
      case AiProvider.none:
        throw Exception('Proveedor no configurado');
    }
  }

  Routine? _parseRoutineJson(
    String response, {
    required List<String> targetMuscles,
    UserProfile? profile,
  }) {
    try {
      final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start < 0 || end <= start) return null;

      final json = jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
      return _parseRoutineFromMap(json, targetMuscles: targetMuscles, profile: profile);
    } catch (_) {
      return null;
    }
  }

  List<Routine> _parseRoutineProgramJson(
    String response, {
    required List<String> targetMuscles,
    UserProfile? profile,
  }) {
    try {
      final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final start = cleaned.indexOf('{');
      final arrayStart = cleaned.indexOf('[');
      final useObject = start >= 0 && (arrayStart < 0 || start < arrayStart);

      if (useObject) {
        final end = cleaned.lastIndexOf('}');
        if (end <= start) return const [];
        final json = jsonDecode(cleaned.substring(start, end + 1));
        if (json is Map<String, dynamic>) {
          final routines = json['routines'];
          if (routines is List) {
            return _parseRoutineList(routines, targetMuscles: targetMuscles, profile: profile);
          }
          final single = _parseRoutineFromMap(json, targetMuscles: targetMuscles, profile: profile);
          return single == null ? const [] : [single];
        }
      }

      if (arrayStart >= 0) {
        final end = cleaned.lastIndexOf(']');
        if (end <= arrayStart) return const [];
        final json = jsonDecode(cleaned.substring(arrayStart, end + 1));
        if (json is List) {
          return _parseRoutineList(json, targetMuscles: targetMuscles, profile: profile);
        }
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }

  List<Routine> _parseRoutineList(
    List<dynamic> items, {
    required List<String> targetMuscles,
    UserProfile? profile,
  }) {
    final routines = <Routine>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final routine = _parseRoutineFromMap(item, targetMuscles: targetMuscles, profile: profile);
      if (routine != null) routines.add(routine);
    }
    return routines;
  }

  Routine? _parseRoutineFromMap(
    Map<String, dynamic> json, {
    required List<String> targetMuscles,
    UserProfile? profile,
  }) {
    try {
      final parsedMuscles = (json['target_muscles'] as List?)
              ?.map((m) => m.toString())
              .where((m) => m.isNotEmpty)
              .toList() ??
          targetMuscles;

      final exercises = (json['exercises'] as List? ?? []).asMap().entries.map((e) {
        final ex = e.value as Map<String, dynamic>;
        final loggingType = ExerciseLoggingType.fromJson(ex['logging_type'] as String?);
        final isCardio = loggingType == ExerciseLoggingType.cardio;
        return RoutineExercise(
          id: '',
          exerciseId: ex['name'] as String? ?? '',
          exerciseName: ex['name'] as String? ?? '',
          orderIndex: e.key,
          targetSets: ex['sets'] as int? ?? AppConstants.defaultSets,
          targetReps: isCardio ? 0 : (ex['reps'] as int? ?? AppConstants.defaultReps),
          targetWeight: isCardio
              ? null
              : GymWeight.snapKgOrNull(
                  (ex['weight_kg'] as num?)?.toDouble(),
                  profile?.unitSystem ?? 'kg',
                ),
          restSeconds: isCardio ? 0 : (ex['rest_seconds'] as int? ?? AppConstants.defaultRestSeconds),
          loggingType: loggingType,
          targetDurationSeconds: ex['duration_seconds'] as int?,
          targetDistanceMeters: (ex['distance_meters'] as num?)?.toDouble(),
          targetInclinePercent: (ex['incline_percent'] as num?)?.toDouble(),
          targetSteps: ex['steps'] as int?,
        );
      }).toList();

      if (exercises.isEmpty) return null;

      return Routine(
        id: '',
        userId: profile?.id ?? '',
        name: json['name'] as String? ?? 'Rutina IA',
        description: json['description'] as String?,
        targetMuscles: parsedMuscles,
        exercises: exercises,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAiGenerated: true,
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _catalogNamesForMuscles(List<Exercise> catalog, List<String> targetMuscles) {
    return AiRoutineSanitizer.namesForMuscles(
      AiRoutineSanitizer.catalogForAi(catalog),
      targetMuscles,
    );
  }

  Future<String> _loadUserContext({
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    WorkoutWeeklyStats? weeklyStats,
    List<PersonalRecord>? personalRecords,
    List<Workout>? recentWorkouts,
    List<Routine>? routines,
    CoachNutritionSnapshot? nutrition,
  }) async {
    final metrics = bodyMetrics ?? await _profileService.getBodyMetricSnapshots();
    return AiCoachContextBuilder.build(
      profile: profile,
      bodyMetrics: metrics,
      weeklyStats: weeklyStats,
      personalRecords: personalRecords,
      recentWorkouts: recentWorkouts,
      routines: routines,
      nutrition: nutrition,
    );
  }

  Future<String> _callOpenAI(String apiKey, String system, String user) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
        'max_tokens': 2000,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error OpenAI: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['choices'][0]['message']['content'] as String;
  }

  Future<String> _callGemini(String apiKey, String system, String user) async {
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': system},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': user},
            ],
          },
        ],
        'generationConfig': {'maxOutputTokens': 2000, 'temperature': 0.7},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error Gemini: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  Future<String> _callAnthropic(String apiKey, String system, String user) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'claude-3-5-haiku-latest',
        'max_tokens': 2000,
        'system': system,
        'messages': [
          {'role': 'user', 'content': user},
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error Anthropic: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    return content.first['text'] as String;
  }

  /// Sugiere peso/reps (o cardio) para todos los ejercicios de un entreno en una sola llamada.
  Future<AiWorkoutSuggestions?> suggestWorkoutSets({
    required UserProfile profile,
    required String payloadJson,
  }) async {
    if (!profile.hasAiKey) return null;

    final lang = _resolveLanguageCode(profile: profile);
    final usesLb = UnitConverter.isLb(profile.unitSystem);
    final weightNote = usesLb
        ? 'El usuario ve libras en la app, pero responde pesos en weight_kg (kilogramos, como en el historial). Usa incrementos de gimnasio: pesos que en lb sean múltiplos de 2.5 (ej. 10, 12.5, 15 lb por mancuerna).'
        : 'Express strength weights as weight_kg (kilograms). Use gym increments: multiples of 0.5 kg (e.g. 10, 12.5, 20 kg).';

    final goalBlock = ProactiveWorkoutAiRules.goalProgrammingBlock(profile);

    final systemPrompt = '''
Eres un programador de entrenamiento de FitForge.
${languageInstruction(lang)}
Responde ÚNICAMENTE con JSON válido. Sin markdown ni texto extra.
$weightNote

$goalBlock

Reglas generales:
- Usa el historial (máx. 5 sesiones), objetivo y experiencia del usuario.
- recovery_pct indica recuperación muscular (100 = totalmente recuperado). Si recovery_pct < 60, no subas peso; mantén o reduce; reduce series de trabajo.
- days_since_last: días desde la última sesión de ese ejercicio.
- latest_session_summary resume la sesión más reciente; recent_top_set resume la mejor serie reciente.
- Si existe latest_session_summary o recent_top_set, tómalos como ancla principal. No bajes el peso de trabajo frente al historial reciente salvo que recovery_pct < 60, hayan pasado muy pocos días desde la última sesión, el rir reciente haya sido 0-1, o el objetivo pida claramente menos carga.
- Si el usuario ya hizo por ejemplo 30 kg x 10 recientemente con buena recuperación, no sugieras 20 kg x 10 por defecto. Mantén o micro-progresa.
- set_count es la plantilla de la rutina; history_avg_set_count es el promedio histórico. NO estás obligado a mantener set_count: ajusta series según objetivo.
- Para cardio (is_cardio true): usa duration_seconds, distance_meters, incline_percent o steps; no uses peso/reps.
- Si no hay historial, usa valores conservadores según objetivo y experiencia.
- Devuelve TODOS los ejercicios del payload con su exercise_id exacto.
- En el historial, rir = repeticiones en reserva (0 = al fallo, 3 = fácil). Si el último set tuvo rir 0-1, no subas peso salvo objetivo Fuerza con buena recuperación. Si rir ≥ 2, puedes progresar.
''';

    final userPrompt = '''
Datos del entrenamiento a iniciar:
$payloadJson

Responde SOLO con este JSON (ejemplo con aproximaciones + trabajo en un compuesto):
{
  "exercises": [
    {
      "exercise_id": "id del ejercicio",
      "sets": [
        {"set_number": 1, "weight_kg": 40, "reps": 10},
        {"set_number": 2, "weight_kg": 60, "reps": 5},
        {"set_number": 3, "weight_kg": 80, "reps": 5},
        {"set_number": 4, "weight_kg": 80, "reps": 5},
        {"set_number": 5, "weight_kg": 80, "reps": 5}
      ]
    }
  ]
}
''';

    try {
      final response = await _complete(
        profile: profile,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
      return AiWorkoutSuggestionsParser.parse(response);
    } catch (_) {
      return null;
    }
  }

  /// Estima macros de un alimento por texto (búsqueda / descripción).
  Future<FoodNutritionEstimate?> estimateFoodFromText({
    required String query,
    UserProfile? profile,
  }) async {
    final lang = _resolveLanguageCode(profile: profile);
    final system = '''
Eres un nutricionista de FitForge. ${languageInstruction(lang)}
Responde SOLO JSON válido sin markdown.

Reglas:
- Si el usuario lista varios alimentos, SUMA cada uno por separado.
- Si da calorías explícitas (ej. "56 kcal cada una"), usa ese valor exacto para ese ítem.
- "Sin aceite" en huevos = sin grasa añadida, pero conserva la grasa natural del huevo (~5 g grasa por huevo grande).
- serving_description: describe la porción real (ej. "2 huevos + 2 tortillas"), no uses 100 g por defecto.
- reference_amount_g: peso total estimado en gramos de TODO lo descrito (huevos + tortillas + etc.).
- calories_kcal debe ser el TOTAL para reference_amount_g (no confundir con kcal/100g).
- Si el usuario indica gramos (ej. "300 g espagueti cocido"), calories_kcal = (kcal por 100 g) × (gramos / 100). Pasta cocida ~131 kcal/100g, arroz cocido ~130 kcal/100g.
- NUNCA pongas reference_amount_g=300 con calories_kcal de solo 100 g de comida.
- Frutas por peso: manzana ~52 kcal/100g, plátano ~89 kcal/100g.
- Los macros deben ser coherentes con las calorías (proteína/carbs ~4 kcal/g, grasa ~9 kcal/g).
- name: nombre ESPECÍFICO del plato con ingredientes o preparación visibles (máx. ~70 caracteres).
  Buenos: "2 huevos revueltos con 2 tortillas de maíz", "Avena con plátano y mantequilla de maní".
  Malos: "Comida", "Desayuno", "Plato", "Huevos" (demasiado genérico).
''';
    final hints = FoodQueryHints.labeledKcalTotal(query);
    final eggs = FoodQueryHints.eggCount(query);
    final hintsBlock = (hints > 0 || eggs > 0)
        ? '''

DATOS OBLIGATORIOS del usuario (debes respetarlos en el total):
${eggs > 0 ? '- $eggs huevo(s) grande(s) sin aceite añadido: ~${eggs * FoodQueryHints.eggKcal} kcal' : ''}
${hints > 0 ? '- Ítems con kcal explícitas en el texto: mínimo $hints kcal (suma exacta de lo indicado)' : ''}
- calories_kcal DEBE ser >= ${(hints + eggs * FoodQueryHints.eggKcal)} kcal
'''
        : '';

    final user = '''
Comida descrita: "$query"
$hintsBlock
JSON:
{
  "name": "nombre específico del plato con ingredientes visibles",
  "brand": null,
  "calories_kcal": 0,
  "protein_g": 0,
  "carbs_g": 0,
  "fat_g": 0,
  "fiber_g": 0,
  "serving_description": "2 huevos + 2 tortillas",
  "reference_amount_g": 180,
  "ingredients": ["ingrediente 1"]
}
''';
    try {
      final response = await _complete(profile: profile, systemPrompt: system, userPrompt: user);
      final parsed = _parseFoodEstimate(response);
      if (parsed == null) return null;
      return FoodQueryHints.reconcile(query, parsed);
    } catch (_) {
      return null;
    }
  }

  /// Estima macros desde foto (OpenAI vision o Gemini).
  Future<FoodNutritionEstimate?> estimateFoodFromImage({
    required List<int> imageBytes,
    UserProfile? profile,
  }) async {
    if (!await _profileService.hasUsableAiKey(profile)) return null;

    final aiProvider = _profileService.resolveAiProvider(profile);
    final apiKey = await _profileService.getApiKey(aiProvider);
    if (apiKey == null || apiKey.isEmpty) return null;

    final lang = _resolveLanguageCode(profile: profile);
    final prompt = '''
Identifica la comida en la imagen y estima nutrición de la porción visible en el plato.
${languageInstruction(lang)}
Responde SOLO JSON válido sin markdown.

Reglas:
- Si aparece una balanza de cocina con display numérico legible, usa ESE peso en gramos como reference_amount_g (prioridad sobre estimación visual del plato).
- Lee dígitos de la pantalla (g, kg, oz, lb) y convierte todo a gramos totales del alimento pesado.
- Si la foto muestra comida en un plato/bowl Y una balanza en la misma imagen, el número de la balanza es el peso de referencia.
- reference_amount_g: peso total estimado en gramos de TODO lo visible (no uses 100 por defecto).
- calories_kcal, protein_g, carbs_g, fat_g: TOTALES para esa porción (no valores por 100 g).
- serving_description: describe la porción real (ej. "1 plato ~280 g", "2 tacos ~180 g").
- Si hay varios ítems, inclúyelos en ingredients y suma todo en reference_amount_g.
- name: identifica el plato con DETALLE: proteína principal, guarnición, salsa o método de cocción si se ven (máx. ~70 caracteres).
  Buenos: "Pechuga de pollo a la plancha con arroz blanco y brócoli", "Tacos de bistec con cebolla y cilantro", "Ensalada César con pollo empanizado".
  Malos: "Comida", "Plato", "Almuerzo", "Pollo", "Arroz con algo".
- ingredients: lista cada componente visible del plato, no solo el principal.
- ingredient_portions: OBLIGATORIO si hay varios componentes. Array de objetos con name y grams_g (peso estimado de cada uno).
  La suma de grams_g debe aproximar reference_amount_g.
  Ejemplo: [{"name": "pechuga de pollo", "grams_g": 150}, {"name": "arroz blanco", "grams_g": 120}, {"name": "brócoli", "grams_g": 50}]

JSON:
{
  "name": "nombre específico del plato con ingredientes visibles",
  "brand": null,
  "calories_kcal": 0,
  "protein_g": 0,
  "carbs_g": 0,
  "fat_g": 0,
  "fiber_g": 0,
  "serving_description": "1 plato ~280 g",
  "reference_amount_g": 280,
  "ingredients": ["pechuga de pollo", "arroz blanco", "brócoli"],
  "ingredient_portions": [
    {"name": "pechuga de pollo", "grams_g": 150},
    {"name": "arroz blanco", "grams_g": 120},
    {"name": "brócoli", "grams_g": 50}
  ]
}
''';

    try {
      final String response;
      switch (aiProvider) {
        case AiProvider.openai:
          response = await _callOpenAIVision(apiKey, prompt, imageBytes);
        case AiProvider.gemini:
          response = await _callGeminiVision(apiKey, prompt, imageBytes);
        case AiProvider.anthropic:
          response = await _callAnthropicVision(apiKey, prompt, imageBytes);
        case AiProvider.none:
          return null;
      }
      return _parseFoodEstimate(response);
    } catch (_) {
      return null;
    }
  }

  /// Aplica una corrección del usuario sin rehacer el plato desde cero.
  Future<FoodNutritionEstimate?> reviseFoodEstimate({
    required FoodNutritionEstimate previous,
    required String correction,
    List<int>? imageBytes,
    UserProfile? profile,
  }) async {
    final trimmed = correction.trim();
    if (trimmed.isEmpty) return null;

    final lang = _resolveLanguageCode(profile: profile);
    final system = _foodRevisionSystemPrompt(lang);
    final user = _foodRevisionUserPrompt(previous, trimmed);

    try {
      final aiProvider = _profileService.resolveAiProvider(profile);
      final canUseVision = imageBytes != null &&
          imageBytes.isNotEmpty &&
          await _profileService.hasUsableAiKey(profile);

      final String response;
      if (canUseVision) {
        final apiKey = await _profileService.getApiKey(aiProvider);
        if (apiKey == null || apiKey.isEmpty) return null;
        final visionPrompt = '$system\n\n$user';
        switch (aiProvider) {
          case AiProvider.openai:
            response = await _callOpenAIVision(apiKey, visionPrompt, imageBytes);
          case AiProvider.gemini:
            response = await _callGeminiVision(apiKey, visionPrompt, imageBytes);
          case AiProvider.anthropic:
            response = await _callAnthropicVision(apiKey, visionPrompt, imageBytes);
          case AiProvider.none:
            return null;
        }
      } else {
        response = await _complete(profile: profile, systemPrompt: system, userPrompt: user);
      }

      final parsed = _parseFoodEstimate(response);
      if (parsed == null) return null;
      return FoodEstimateParser.stabilizeRevision(
        previous: previous,
        revised: parsed,
        correction: trimmed,
      );
    } catch (_) {
      return null;
    }
  }

  String _foodRevisionSystemPrompt(String lang) {
    return '''
Eres un nutricionista de FitForge. ${languageInstruction(lang)}
El usuario ya tiene una estimación y pide un AJUSTE puntual, no un plato nuevo.
Responde SOLO JSON válido sin markdown.

Reglas obligatorias:
- Conserva TODOS los ingredientes y componentes de la estimación anterior salvo que la corrección pida explícitamente quitar algo.
- Si corrige un ingrediente (ej. cerdo→pollo, arroz frito→arroz blanco), cambia SOLO ese ítem y recalcula macros totales del plato completo.
- NO elimines otros alimentos del plato (arroz, brócoli, verduras, etc.) al corregir un solo ítem.
- Si la corrección menciona peso en gramos o hay balanza visible en la imagen, actualiza reference_amount_g con ese peso.
- ingredients debe listar TODOS los componentes finales del plato, no solo el corregido.
- ingredient_portions: si hay varios componentes, incluye name y grams_g de cada uno; la suma debe aproximar reference_amount_g.
- Si actualizas ingredientes o preparación, actualiza también name para que siga siendo específico y descriptivo.
- calories_kcal y macros son TOTALES para reference_amount_g del plato completo.
- Los macros deben ser coherentes con las calorías.
''';
  }

  String _foodRevisionUserPrompt(FoodNutritionEstimate previous, String correction) {
    final contextJson = jsonEncode(FoodEstimateParser.toRevisionContext(previous));
    return '''
ESTIMACIÓN ANTERIOR (base obligatoria):
$contextJson

CORRECCIÓN DEL USUARIO:
"$correction"

Devuelve la estimación ACTUALIZADA del plato completo aplicando solo la corrección.
JSON:
{
  "name": "nombre específico del plato con ingredientes visibles",
  "brand": null,
  "calories_kcal": 0,
  "protein_g": 0,
  "carbs_g": 0,
  "fat_g": 0,
  "fiber_g": 0,
  "serving_description": "1 plato ~280 g",
  "reference_amount_g": 280,
  "ingredients": ["todos los ingredientes del plato"],
  "ingredient_portions": [
    {"name": "ingrediente 1", "grams_g": 120},
    {"name": "ingrediente 2", "grams_g": 80}
  ]
}
''';
  }

  FoodNutritionEstimate? _parseFoodEstimate(String response) {
    return FoodEstimateParser.parse(response);
  }

  Future<String> _callOpenAIVision(String apiKey, String prompt, List<int> imageBytes) async {
    final b64 = base64Encode(imageBytes);
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$b64'},
              },
            ],
          },
        ],
        'max_tokens': 800,
        'temperature': 0.3,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error OpenAI vision: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['choices'][0]['message']['content'] as String;
  }

  Future<String> _callGeminiVision(String apiKey, String prompt, List<int> imageBytes) async {
    final b64 = base64Encode(imageBytes);
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {'inline_data': {'mime_type': 'image/jpeg', 'data': b64}},
            ],
          },
        ],
        'generationConfig': {'maxOutputTokens': 800, 'temperature': 0.3},
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error Gemini vision: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  Future<String> _callAnthropicVision(String apiKey, String prompt, List<int> imageBytes) async {
    final b64 = base64Encode(imageBytes);
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'claude-3-5-haiku-latest',
        'max_tokens': 800,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': b64,
                },
              },
              {'type': 'text', 'text': prompt},
            ],
          },
        ],
        'temperature': 0.3,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error Anthropic vision: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    return content.first['text'] as String;
  }
}
