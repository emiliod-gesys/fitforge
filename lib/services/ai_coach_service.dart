import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/utils/ai_coach_context.dart';
import '../core/utils/ai_routine_sanitizer.dart';
import '../core/utils/exercise_matcher.dart';
import '../core/utils/unit_converter.dart';
import '../core/utils/workout_streak.dart';
import '../models/body_metric.dart';
import '../models/exercise.dart';
import '../models/exercise_logging.dart';
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

  Future<String> getRecommendation({
    required String userMessage,
    List<Workout>? recentWorkouts,
    List<Routine>? routines,
    UserProfile? profile,
    Map<String, BodyMetricSnapshot>? bodyMetrics,
    WorkoutWeeklyStats? weeklyStats,
    List<PersonalRecord>? personalRecords,
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
    final systemPrompt = '''
Eres FitForge Coach, un entrenador personal experto en fuerza e hipertrofia.
Responde siempre en español. Sé conciso pero útil.
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
  }) async {
    final targetMuscles = parseTargetMuscles(userMessage);
    final duration = parseDurationMinutes(userMessage);
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

    final response = await _complete(
      profile: profile,
      systemPrompt: '''
Eres un generador de rutinas de gimnasio para FitForge.
Responde ÚNICAMENTE con JSON válido. Sin markdown, sin texto adicional.
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
}
