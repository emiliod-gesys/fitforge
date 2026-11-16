import 'package:fitforge/core/utils/ai_routine_sanitizer.dart';
import 'package:fitforge/core/utils/exercise_matcher.dart';
import 'package:fitforge/models/coach_chat_turn.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/routine.dart';
import 'package:fitforge/services/ai_coach_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routine intents', () {
    test('save intent does not trigger creation', () {
      expect(AiCoachService.isRoutineSaveIntent('guarda la rutina'), isTrue);
      expect(AiCoachService.isRoutineCreationRequest('guarda la rutina'), isFalse);
    });

    test('create intent still works', () {
      expect(AiCoachService.isRoutineCreationRequest('crea una rutina de piernas'), isTrue);
      expect(AiCoachService.isRoutineSaveIntent('crea una rutina de piernas'), isFalse);
    });

    test('voz arma la rutina y no la lee', () {
      expect(AiCoachService.voiceShouldBuildRoutine('piernas'), isTrue);
      expect(AiCoachService.voiceShouldBuildRoutine('pecho y triceps'), isTrue);
      expect(AiCoachService.voiceShouldBuildRoutine('recomiendame espalda'), isTrue);
      expect(AiCoachService.voiceShouldBuildRoutine('día de hombros'), isTrue);
      expect(AiCoachService.voiceShouldBuildRoutine('hoy toca gluteos'), isTrue);
      expect(AiCoachService.voiceShouldBuildRoutine('qué puedo almorzar'), isFalse);
      expect(AiCoachService.voiceShouldBuildRoutine('me duele el hombro'), isFalse);
      expect(AiCoachService.voiceShouldBuildRoutine('cómo va mi rutina'), isFalse);
      expect(AiCoachService.voiceShouldBuildRoutine('cuál es mi record de pecho'), isFalse);
      expect(AiCoachService.voiceShouldBuildRoutine('cómo hago press de pecho'), isFalse);
      expect(
        AiCoachService.voiceShouldBuildRoutine(
          'agrega un ejercicio de pecho superior',
        ),
        isFalse,
      );
      expect(
        AiCoachService.voiceShouldBuildRoutine(
          'agrega un ejercicio de pecho superior al entrenamiento',
        ),
        isFalse,
      );
      expect(
        AiCoachService.parseTargetMuscles(
          'agrega un ejercicio de pecho superior',
        ),
        ['Pecho'],
      );
      expect(AiCoachService.isRoutineCreationRequest('cómo va mi entrenamiento'), isFalse);
      expect(AiCoachService.shouldGenerateStructuredRoutine('cómo va mi entrenamiento'), isFalse);
    });

    test('una rutina escrita no se muestra como texto', () {
      const written = '''
Para pecho:
1. Press banca - 4 series de 8 repeticiones
2. Press inclinado - 3 series de 10
3. Aperturas - 3 series de 12
''';
      expect(AiCoachService.looksLikeWrittenRoutine(written), isTrue);
      expect(
        AiCoachService.looksLikeWrittenRoutine('Haz 4 series de 8 en sentadilla.'),
        isFalse,
      );
      expect(
        AiCoachService.looksLikeWrittenRoutine('1. Pollo\n2. Arroz\n3. Ensalada'),
        isFalse,
      );
    });

    test('piernas completas es una rutina', () {
      expect(AiCoachService.isRoutineCreationRequest('piernas completas'), isTrue);
      expect(AiCoachService.isRoutineCreationRequest('rutina completa de piernas'), isTrue);
      expect(
        AiCoachService.parseTargetMuscles('una rutina de piernas completas'),
        containsAll(['Piernas', 'Glúteos']),
      );
    });

    test('hombros con brazos o abdomen incluye cada grupo', () {
      expect(
        AiCoachService.parseTargetMuscles('Crea una rutina de hombros y brazos'),
        containsAll(['Hombros', 'Bíceps', 'Tríceps']),
      );
      expect(
        AiCoachService.parseTargetMuscles('hombros y abdomen'),
        containsAll(['Hombros', 'Abdominales']),
      );
    });

    test('rutina de musculos concretos', () {
      expect(
        AiCoachService.isRoutineCreationRequest('rutina de biceps y triceps'),
        isTrue,
      );
    });

    test('plan de entrenamiento', () {
      expect(
        AiCoachService.isRoutineCreationRequest('hazme un plan de entrenamiento de piernas'),
        isTrue,
      );
    });

    test('muscles with training intent', () {
      expect(
        AiCoachService.isRoutineCreationRequest('quiero entrenar biceps y triceps hoy'),
        isTrue,
      );
    });

    test('editable routine request', () {
      expect(
        AiCoachService.isRoutineCreationRequest('crea una rutina editable de espalda'),
        isTrue,
      );
    });

    test('upper body strength without duration', () {
      expect(
        AiCoachService.isRoutineCreationRequest(
          'Crea una rutina de tren superior enfocada en fuerza',
        ),
        isTrue,
      );
      expect(AiCoachService.userSpecifiedDuration('Crea una rutina de tren superior'), isFalse);
      expect(AiCoachService.parseDurationMinutes('Crea una rutina de tren superior'), 45);
    });

    test('workout phrasing without rutina keyword', () {
      expect(
        AiCoachService.isRoutineCreationRequest('crea un entrenamiento de tren superior'),
        isTrue,
      );
    });

    test('retina typo is treated as rutina', () {
      expect(
        AiCoachService.isRoutineCreationRequest('Crea una retina de tren superior enfocada en fuerza'),
        isTrue,
      );
    });

    test('tren superior maps to upper body muscles', () {
      final muscles = AiCoachService.parseTargetMuscles('rutina de tren superior');
      expect(muscles, contains('Pecho'));
      expect(muscles, contains('Espalda'));
    });

    test('weekly ULPPL program in english', () {
      expect(
        AiCoachService.isRoutineCreationRequest(
          'Create a ULPPL routine for the week focusing on progressive overload',
        ),
        isTrue,
      );
      expect(
        AiCoachService.isMultiRoutineProgramRequest(
          'Create a ULPPL routine for the week focusing on progressive overload',
        ),
        isTrue,
      );
      expect(
        AiCoachService.expectedProgramRoutineCount('Create a ULPPL routine for the week'),
        5,
      );
    });

    test('plan semanal en español', () {
      expect(
        AiCoachService.isRoutineCreationRequest('crea un plan semanal de entrenamiento'),
        isTrue,
      );
      expect(AiCoachService.isMultiRoutineProgramRequest('plan semanal push pull legs'), isTrue);
    });
  });

  group('language instruction', () {
    test('english prompt allows bilingual responses', () {
      final instruction = AiCoachService.languageInstruction('en');
      expect(instruction, contains('English'));
      expect(instruction, contains('Spanish'));
    });

    test('spanish prompt allows bilingual responses', () {
      final instruction = AiCoachService.languageInstruction('es');
      expect(instruction, contains('español'));
      expect(instruction, contains('inglés'));
    });
  });

  group('spoken routine json', () {
    test('spanish keys become a routine instead of raw json', () {
      const answer = '''
Para un entrenamiento de piernas completo, aquí tienes una rutina estructurada.
json
{
  "nombre": "Piernas Completas",
  "ejercicios": [
    {"nombre": "Sentadilla", "series": 4, "repeticiones": 8},
    {"nombre": "Peso muerto rumano", "series": 3, "repeticiones": 10}
  ]
}
''';
      final routine = AiCoachService.parseSpokenRoutine(answer, targetMuscles: const ['Piernas']);
      expect(routine?.name, 'Piernas Completas');
      expect(routine?.exercises.map((exercise) => exercise.exerciseName), [
        'Sentadilla',
        'Peso muerto rumano',
      ]);
      expect(AiCoachService.withoutRoutineJson(answer), isNot(contains('{')));
      expect(AiCoachService.withoutRoutineJson(answer), isNot(contains('ejercicios')));
    });
  });

  group('fitness scope instruction', () {
    test('english scope limits to fitness topics', () {
      final instruction = AiCoachService.fitnessScopeInstruction('en');
      expect(instruction, contains('ONLY'));
      expect(instruction, contains('fitness'));
      expect(instruction, contains('decline'));
    });

    test('spanish scope limits to fitness topics', () {
      final instruction = AiCoachService.fitnessScopeInstruction('es');
      expect(instruction, contains('ÚNICAMENTE'));
      expect(instruction, contains('fitness'));
      expect(instruction, contains('Rechaza'));
    });
  });

  group('AiRoutineSanitizer', () {
    final catalog = [
      const Exercise(
        name: 'Curl con barra',
        category: 'Brazos',
        muscles: ['Bíceps'],
        imageUrl: 'https://wger.de/media/1.jpg',
      ),
      const Exercise(
        name: 'Curl martillo',
        category: 'Brazos',
        muscles: ['Bíceps'],
        imageUrl: 'https://wger.de/media/2.jpg',
      ),
      const Exercise(
        name: 'Extensiones de tríceps en polea',
        category: 'Brazos',
        muscles: ['Tríceps'],
        imageUrl: 'https://wger.de/media/3.jpg',
      ),
      const Exercise(
        name: 'Fondos en paralelas',
        category: 'Brazos',
        muscles: ['Tríceps'],
        imageUrl: 'https://wger.de/media/4.jpg',
      ),
      const Exercise(name: 'Ejercicio de prueba', category: 'Brazos', isUserCustom: true),
    ];

    test('excludes exercises without illustration', () {
      final catalog = [
        const Exercise(
          name: 'Curl con barra',
          category: 'Brazos',
          muscles: ['Bíceps'],
          imageUrl: 'https://wger.de/media/exercise-images/1/test.jpg',
        ),
        const Exercise(name: 'Curl martillo', category: 'Brazos', muscles: ['Bíceps']),
        const Exercise(
          name: 'biceps',
          category: 'Brazos',
          muscles: ['Bíceps'],
          imageUrl: 'https://wger.de/media/exercise-images/2/test.jpg',
        ),
      ];

      final filtered = AiRoutineSanitizer.catalogForAi(catalog);
      expect(filtered.map((e) => e.name), ['Curl con barra']);
    });

    test('includes custom exercise only with local photo', () {
      final catalog = [
        const Exercise(
          supabaseId: 'abc',
          name: 'Mi prensa',
          category: 'Piernas',
          isUserCustom: true,
          imageUrl: '/data/user/0/photo.jpg',
        ),
        const Exercise(
          supabaseId: 'def',
          name: 'Sin foto',
          category: 'Piernas',
          isUserCustom: true,
        ),
      ];

      expect(AiRoutineSanitizer.hasIllustration(catalog[0]), isTrue);
      expect(AiRoutineSanitizer.hasIllustration(catalog[1]), isFalse);
    });

    test('excludes low quality custom names from AI catalog', () {
      final filtered = AiRoutineSanitizer.catalogForAi(catalog);
      expect(filtered.any((e) => e.name == 'Ejercicio de prueba'), isFalse);
    });

    test('deduplicates exercises and substitutes alternatives', () {
      final routine = Routine(
        id: '',
        userId: 'u1',
        name: 'Brazos',
        targetMuscles: const ['Bíceps', 'Tríceps'],
        exercises: const [
          RoutineExercise(
            id: '',
            exerciseId: 'Curl con barra',
            exerciseName: 'Curl con barra',
            orderIndex: 0,
          ),
          RoutineExercise(
            id: '',
            exerciseId: 'Curl con barra',
            exerciseName: 'Curl con barra',
            orderIndex: 1,
          ),
          RoutineExercise(
            id: '',
            exerciseId: 'Extensiones de tríceps en polea',
            exerciseName: 'Extensiones de tríceps en polea',
            orderIndex: 2,
          ),
          RoutineExercise(
            id: '',
            exerciseId: 'Ejercicio de prueba',
            exerciseName: 'Ejercicio de prueba',
            orderIndex: 3,
          ),
        ],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        isAiGenerated: true,
      );

      final sanitized = ExerciseMatcher.enrich(routine, catalog);
      final names = sanitized.exercises.map((e) => e.exerciseName).toList();

      expect(names, contains('Curl con barra'));
      expect(names, contains('Extensiones de tríceps en polea'));
      expect(names, isNot(contains('Ejercicio de prueba')));
      expect(names.toSet().length, names.length);
      expect(names.length, greaterThanOrEqualTo(3));
    });
  });

  group('conversation context', () {
    test('follow-up create routine inherits chest from prior user message', () {
      expect(
        AiCoachService.isRoutineCreationRequest('crea la rutina en el app'),
        isTrue,
      );
      expect(
        AiCoachService.parseTargetMuscles('crea la rutina en el app'),
        isEmpty,
      );

      final history = [
        const CoachChatTurn(
          isUser: true,
          content: '¿Qué ejercicios me recomiendas para pecho hoy?',
        ),
        const CoachChatTurn(
          isUser: false,
          content: '### Ejercicios para Pecho\n1. Press de Banca Plano',
        ),
      ];

      final muscles = AiCoachService.resolveTargetMuscles(
        currentMessage: 'crea la rutina en el app',
        history: history,
      );
      expect(muscles, contains('Pecho'));
      expect(
        AiCoachService.priorCoachAdvice(history),
        contains('Press de Banca Plano'),
      );
    });

    test('current message muscles win over history', () {
      final history = [
        const CoachChatTurn(isUser: true, content: 'rutina de pecho'),
      ];
      final muscles = AiCoachService.resolveTargetMuscles(
        currentMessage: 'crea una rutina de piernas',
        history: history,
      );
      expect(muscles, contains('Piernas'));
      expect(muscles, isNot(contains('Pecho')));
    });

    test('trimChatHistory keeps newest turns', () {
      final history = List.generate(
        20,
        (i) => CoachChatTurn(isUser: i.isEven, content: 'mensaje $i'),
      );
      final trimmed = AiCoachService.trimChatHistory(history, maxTurns: 4);
      expect(trimmed.length, 4);
      expect(trimmed.first.content, 'mensaje 16');
      expect(trimmed.last.content, 'mensaje 19');
    });
  });
}
