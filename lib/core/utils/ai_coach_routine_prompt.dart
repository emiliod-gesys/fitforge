import '../../models/exercise.dart';
import '../../services/routine_limit_service.dart';

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

  static String equipmentLabel(String key) {
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
When the user asks for a workout routine or training plan to save in FitForge, you MUST respond with valid routine JSON only (no markdown prose as the main answer) so the app can add it to their library.
Do not reply with a generic tip list when they asked for a routine; produce the structured routine.''';
    }
    return '''
Cuando el usuario pida una rutina o plan de entrenamiento para guardar en FitForge, DEBES responder SOLO con JSON válido de rutina (sin markdown como respuesta principal) para que la app pueda agregarla.
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
