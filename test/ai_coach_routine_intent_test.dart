import 'package:fitforge/core/utils/ai_routine_sanitizer.dart';
import 'package:fitforge/core/utils/exercise_matcher.dart';
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
}
