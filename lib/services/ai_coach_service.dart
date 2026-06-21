import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/utils/ai_coach_context.dart';
import '../core/utils/ai_routine_sanitizer.dart';
import '../core/utils/exercise_matcher.dart';
import '../core/utils/food_serving_parser.dart';
import '../core/utils/unit_converter.dart';
import '../core/utils/workout_streak.dart';
import '../core/utils/workout_suggestion_context.dart';
import '../models/body_metric.dart';
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
        m.contains('quiero');
  }

  static bool isRoutineCreationRequest(String message) {
    if (isRoutineSaveIntent(message)) return false;

    final m = message.toLowerCase();
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
      'plan de entrenamiento',
      'programa de entrenamiento',
    ];

    if (triggers.any(m.contains)) return true;

    if (RegExp(r'rutina\s+(de|para)\b').hasMatch(m)) return true;

    if ((m.contains('editable') || m.contains('editar') || m.contains('revisar')) &&
        (m.contains('rutina') || m.contains('plan'))) {
      return true;
    }

    final muscles = parseTargetMuscles(message);
    if (muscles.isNotEmpty && _hasTrainingPlanIntent(m)) return true;

    return m.contains('rutina') && _hasRoutineCreateVerb(m);
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
    if (RegExp(r'90', caseSensitive: false).hasMatch(message)) return 90;
    return 45;
  }

  static List<String> parseTargetMuscles(String message) {
    final m = message.toLowerCase();
    final found = <String>{};

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
  }) async {
    final aiProvider = profile?.aiProvider ?? AiProvider.none;
    if (aiProvider == AiProvider.none) {
      throw Exception('Configura un proveedor de IA en tu perfil');
    }

    final apiKey = await _profileService.getApiKey(aiProvider);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Configura tu API key en el perfil');
    }

    final metrics = bodyMetrics ?? await _profileService.getBodyMetricSnapshots();
    final context = AiCoachContextBuilder.build(
      profile: profile,
      bodyMetrics: metrics,
      weeklyStats: weeklyStats,
      personalRecords: personalRecords,
      recentWorkouts: recentWorkouts,
      routines: routines,
    );
    final usesLb = profile != null && UnitConverter.isLb(profile.unitSystem);
    final weightUnit = usesLb ? 'libras (lb)' : 'kilogramos (kg)';
    final progressionHint = usesLb ? '+5 lb o +5%' : '+2.5 kg o +5%';
    final lang = _resolveLanguageCode(languageCode: languageCode, profile: profile);
    final systemPrompt = '''
Eres FitForge Coach, un entrenador personal experto en fuerza e hipertrofia.
${languageInstruction(lang)} Sé conciso pero útil.
${fitnessScopeInstruction(lang)}
Tienes acceso al perfil completo del usuario: datos personales, objetivo, métricas corporales, nivel, racha, records y historial.
Usa esa información para personalizar ejercicios, volumen, series, reps y progresión según su propósito y estado actual.
Basándote en el historial del usuario, recomienda ejercicios, rutinas, pesos, series y reps.
El usuario usa $weightUnit para pesos. Si sugieres pesos, exprésalos en $weightUnit con progresión gradual ($progressionHint).
Formato: usa listas y secciones claras.
Si el usuario pide crear o guardar una rutina, explícale brevemente el enfoque; la app le mostrará una vista previa para guardarla cuando corresponda.

Contexto del usuario:
$context
''';

    switch (aiProvider) {
      case AiProvider.openai:
        return _callOpenAI(apiKey, systemPrompt, userMessage);
      case AiProvider.gemini:
        return _callGemini(apiKey, systemPrompt, userMessage);
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
  }) async {
    final targetMuscles = parseTargetMuscles(userMessage);
    final duration = parseDurationMinutes(userMessage);
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
    );

    final prompt = '''
El usuario pidió lo siguiente:
"$userMessage"

Genera una rutina de gimnasio de $duration minutos.
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
    final aiProvider = profile?.aiProvider ?? AiProvider.none;
    if (aiProvider == AiProvider.none) {
      throw Exception('Configura un proveedor de IA en tu perfil');
    }

    final apiKey = await _profileService.getApiKey(aiProvider);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Configura tu API key en el perfil');
    }

    switch (aiProvider) {
      case AiProvider.openai:
        return _callOpenAI(apiKey, systemPrompt, userPrompt);
      case AiProvider.gemini:
        return _callGemini(apiKey, systemPrompt, userPrompt);
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
          targetWeight: isCardio ? null : (ex['weight_kg'] as num?)?.toDouble(),
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
  }) async {
    final metrics = bodyMetrics ?? await _profileService.getBodyMetricSnapshots();
    return AiCoachContextBuilder.build(
      profile: profile,
      bodyMetrics: metrics,
      weeklyStats: weeklyStats,
      personalRecords: personalRecords,
      recentWorkouts: recentWorkouts,
      routines: routines,
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

  /// Sugiere peso/reps (o cardio) para todos los ejercicios de un entreno en una sola llamada.
  Future<AiWorkoutSuggestions?> suggestWorkoutSets({
    required UserProfile profile,
    required String payloadJson,
  }) async {
    if (!profile.hasAiKey || profile.aiProvider == AiProvider.none) return null;

    final lang = _resolveLanguageCode(profile: profile);
    final usesLb = UnitConverter.isLb(profile.unitSystem);
    final weightNote = usesLb
        ? 'El usuario ve libras en la app, pero responde pesos en weight_kg (kilogramos, como en el historial).'
        : 'Express strength weights as weight_kg (kilograms).';

    final systemPrompt = '''
Eres un programador de entrenamiento de FitForge.
${languageInstruction(lang)}
Responde ÚNICAMENTE con JSON válido. Sin markdown ni texto extra.
$weightNote

Reglas:
- Usa el historial (máx. 5 sesiones), objetivo y experiencia del usuario.
- recovery_pct indica recuperación muscular (100 = totalmente recuperado). Si recovery_pct < 60, no subas peso; mantén o reduce ligeramente; puedes reducir series.
- days_since_last: días desde la última sesión de ese ejercicio.
- set_count es la plantilla de la rutina; history_avg_set_count es el promedio histórico. Puedes ajustar el número de series según objetivo (no estás obligado a mantener set_count).
- Series permitidas: fuerza 1-8 por ejercicio; cardio 1-3. Usa set_number consecutivos 1..N donde N = cantidad de series que decidas.
- Hipertrofia: 3-5 series, 8-12 reps. Fuerza: 3-6 series, 3-6 reps, más peso. Pérdida de grasa/resistencia: 2-4 series, más reps. Mantenimiento: similar al historial o micro-progresión.
- Si el músculo está poco recuperado (recovery_pct < 60), prioriza menos series o mismo peso.
- Para cardio (is_cardio true): usa duration_seconds, distance_meters, incline_percent o steps; no uses peso/reps.
- Si no hay historial, usa valores conservadores razonables según objetivo y experiencia.
''';

    final userPrompt = '''
Datos del entrenamiento a iniciar:
$payloadJson

Responde SOLO con este JSON:
{
  "exercises": [
    {
      "exercise_id": "id del ejercicio",
      "sets": [
        {"set_number": 1, "weight_kg": 80, "reps": 10},
        {"set_number": 2, "weight_kg": 80, "reps": 10},
        {"set_number": 3, "weight_kg": 77.5, "reps": 10}
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
Estima porción típica de consumo si no se especifica cantidad.
''';
    final user = '''
Alimento: "$query"

JSON:
{
  "name": "nombre del plato",
  "brand": null,
  "calories_kcal": 0,
  "protein_g": 0,
  "carbs_g": 0,
  "fat_g": 0,
  "fiber_g": 0,
  "serving_description": "1 porción (120 g)",
  "ingredients": ["ingrediente 1"]
}
''';
    try {
      final response = await _complete(profile: profile, systemPrompt: system, userPrompt: user);
      return _parseFoodEstimate(response);
    } catch (_) {
      return null;
    }
  }

  /// Estima macros desde foto (OpenAI vision o Gemini).
  Future<FoodNutritionEstimate?> estimateFoodFromImage({
    required List<int> imageBytes,
    UserProfile? profile,
  }) async {
    final aiProvider = profile?.aiProvider ?? AiProvider.none;
    if (aiProvider == AiProvider.none || profile?.hasAiKey != true) return null;

    final apiKey = await _profileService.getApiKey(aiProvider);
    if (apiKey == null || apiKey.isEmpty) return null;

    final lang = _resolveLanguageCode(profile: profile);
    final prompt = '''
Identifica la comida en la imagen y estima nutrición de la porción visible.
${languageInstruction(lang)}
Responde SOLO JSON:
{"name":"","brand":null,"calories_kcal":0,"protein_g":0,"carbs_g":0,"fat_g":0,"fiber_g":0,"serving_description":"","ingredients":[]}
''';

    try {
      final String response;
      switch (aiProvider) {
        case AiProvider.openai:
          response = await _callOpenAIVision(apiKey, prompt, imageBytes);
        case AiProvider.gemini:
          response = await _callGeminiVision(apiKey, prompt, imageBytes);
        case AiProvider.none:
          return null;
      }
      return _parseFoodEstimate(response);
    } catch (_) {
      return null;
    }
  }

  FoodNutritionEstimate? _parseFoodEstimate(String response) {
    try {
      final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start < 0 || end <= start) return null;

      final json = jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
      final name = json['name'] as String?;
      if (name == null || name.isEmpty) return null;

      return FoodNutritionEstimate(
        name: name,
        brand: json['brand'] as String?,
        caloriesKcal: (json['calories_kcal'] as num?)?.round().clamp(0, 9999) ?? 0,
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
        fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
        servingDescription: json['serving_description'] as String?,
        ingredients: (json['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        referenceAmount: FoodServingParser.amountFromDescription(
              json['serving_description'] as String?,
            ) ??
            100,
        amountUnit: FoodServingParser.unitFromDescription(json['serving_description'] as String?),
      );
    } catch (_) {
      return null;
    }
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
}
