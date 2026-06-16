import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/utils/unit_converter.dart';
import '../models/profile.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import 'profile_service.dart';

class AiCoachService {
  final ProfileService _profileService;

  AiCoachService(this._profileService);

  Future<String> getRecommendation({
    required String userMessage,
    List<Workout>? recentWorkouts,
    List<Routine>? routines,
    UserProfile? profile,
  }) async {
    final aiProvider = profile?.aiProvider ?? AiProvider.none;
    if (aiProvider == AiProvider.none) {
      throw Exception('Configura un proveedor de IA en tu perfil');
    }

    final apiKey = await _profileService.getApiKey(aiProvider);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Configura tu API key en el perfil');
    }

    final context = _buildContext(recentWorkouts, routines, profile);
    final usesLb = profile != null && UnitConverter.isLb(profile.unitSystem);
    final weightUnit = usesLb ? 'libras (lb)' : 'kilogramos (kg)';
    final progressionHint = usesLb ? '+5 lb o +5%' : '+2.5 kg o +5%';
    final systemPrompt = '''
Eres FitForge Coach, un entrenador personal experto en fuerza e hipertrofia.
Responde siempre en español. Sé conciso pero útil.
Basándote en el historial del usuario, recomienda ejercicios, rutinas, pesos, series y reps.
El usuario usa $weightUnit para pesos. Si sugieres pesos, exprésalos en $weightUnit con progresión gradual ($progressionHint).
Formato: usa listas y secciones claras.

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

  Future<Routine?> generateRoutine({
    required List<String> targetMuscles,
    required int durationMinutes,
    UserProfile? profile,
    List<Workout>? recentWorkouts,
  }) async {
    final prompt = '''
Genera una rutina de gimnasio de $durationMinutes minutos enfocada en: ${targetMuscles.join(', ')}.
Nivel: ${profile?.experienceLevel ?? 'intermedio'}.
Objetivo: ${profile?.fitnessGoal ?? 'hipertrofia'}.

Responde SOLO con JSON válido (sin markdown):
{
  "name": "nombre de la rutina",
  "description": "breve descripción",
  "exercises": [
    {"name": "nombre ejercicio", "sets": 3, "reps": 10, "weight_kg": null, "rest_seconds": 90}
  ]
}
''';

    final response = await getRecommendation(
      userMessage: prompt,
      recentWorkouts: recentWorkouts,
      profile: profile,
    );

    try {
      final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final exercises = (json['exercises'] as List? ?? []).asMap().entries.map((e) {
        final ex = e.value as Map<String, dynamic>;
        return RoutineExercise(
          id: '',
          exerciseId: ex['name'] as String? ?? '',
          exerciseName: ex['name'] as String? ?? '',
          orderIndex: e.key,
          targetSets: ex['sets'] as int? ?? 3,
          targetReps: ex['reps'] as int? ?? 10,
          targetWeight: (ex['weight_kg'] as num?)?.toDouble(),
          restSeconds: ex['rest_seconds'] as int? ?? 90,
        );
      }).toList();

      return Routine(
        id: '',
        userId: profile?.id ?? '',
        name: json['name'] as String? ?? 'Rutina IA',
        description: json['description'] as String?,
        targetMuscles: targetMuscles,
        exercises: exercises,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAiGenerated: true,
      );
    } catch (_) {
      return null;
    }
  }

  String _buildContext(
    List<Workout>? workouts,
    List<Routine>? routines,
    UserProfile? profile,
  ) {
    final buffer = StringBuffer();
    if (profile != null) {
      final weightText = profile.bodyWeight != null
          ? UnitConverter.formatMass(profile.bodyWeight, profile.unitSystem)
          : 'no registrado';
      buffer.writeln('Peso corporal: $weightText');
      buffer.writeln('Unidades preferidas: ${profile.unitSystem == 'lb' ? 'libras' : 'kilogramos'}');
      buffer.writeln('Objetivo: ${profile.fitnessGoal ?? 'no definido'}');
      buffer.writeln('Experiencia: ${profile.experienceLevel ?? 'intermedio'}');
    }
    if (workouts != null && workouts.isNotEmpty) {
      final unit = profile?.unitSystem ?? 'kg';
      buffer.writeln('\nÚltimos entrenamientos:');
      for (final w in workouts.take(5)) {
        buffer.writeln(
          '- ${w.name} (${w.durationMinutes} min, volumen: ${UnitConverter.formatVolume(w.totalVolume, unit)})',
        );
        for (final ex in w.exercises.take(3)) {
          final sets = ex.sets
              .where((s) => s.completed && s.weight != null)
              .map((s) => UnitConverter.formatSetLine(s.weight!, s.reps, unit))
              .join(', ');
          buffer.writeln('  ${ex.exerciseName}: $sets');
        }
      }
    }
    if (routines != null && routines.isNotEmpty) {
      buffer.writeln('\nRutinas guardadas: ${routines.map((r) => r.name).join(', ')}');
    }
    return buffer.toString();
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
        'max_tokens': 1500,
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
        'system_instruction': {'parts': [{'text': system}]},
        'contents': [
          {'role': 'user', 'parts': [{'text': user}]},
        ],
        'generationConfig': {'maxOutputTokens': 1500, 'temperature': 0.7},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error Gemini: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }
}
