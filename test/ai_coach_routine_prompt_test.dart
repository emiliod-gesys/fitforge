import 'package:fitforge/core/utils/ai_coach_routine_prompt.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/services/routine_limit_service.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseAvailableEquipment detects dumbbells and ignores full gym', () {
    expect(
      AiCoachRoutinePrompt.parseAvailableEquipment('solo tengo mancuernas en casa'),
      ['dumbbell'],
    );
    expect(
      AiCoachRoutinePrompt.parseAvailableEquipment('tengo acceso a todo el gimnasio'),
      isEmpty,
    );
  });

  test('glutes with only dumbbells stays on that muscle and gear', () {
    const message = 'Crea una rutina para gluteos pero solo con mancuernas';
    expect(AiCoachRoutinePrompt.requestsExclusiveEquipment(message), isTrue);
    expect(AiCoachRoutinePrompt.parseAvailableEquipment(message), ['dumbbell']);

    const catalog = [
      Exercise(
        catalogId: 'hip',
        name: 'Dumbbell Hip Thrust',
        equipment: ['Dumbbell'],
        muscles: ['Glutes'],
      ),
      Exercise(
        catalogId: 'rdl',
        name: 'Dumbbell Romanian Deadlift',
        equipment: ['Dumbbell'],
        muscles: ['Glutes'],
      ),
      Exercise(
        catalogId: 'bar',
        name: 'Barbell Hip Thrust',
        equipment: ['Barbell'],
        muscles: ['Glutes'],
      ),
      Exercise(
        catalogId: 'curl',
        name: 'Dumbbell Curl',
        equipment: ['Dumbbell'],
        muscles: ['Biceps'],
      ),
    ];

    final matches = AiCoachRoutinePrompt.matchingExercises(
      catalog: catalog,
      equipment: const ['dumbbell'],
      muscles: const ['Glúteos'],
    );
    expect(matches.map((exercise) => exercise.name), [
      'Dumbbell Hip Thrust',
      'Dumbbell Romanian Deadlift',
    ]);

    final routine = AiCoachRoutinePrompt.routineFromExercises(
      exercises: matches,
      muscles: const ['Glúteos'],
      equipment: const ['dumbbell'],
      languageCode: 'es',
      userId: 'user',
    );
    expect(routine.name, 'Glúteos con mancuernas');

    final legs = AiCoachRoutinePrompt.routineFromExercises(
      exercises: const [
        Exercise(catalogId: 'calf', name: 'Calf Raise', muscles: ['Calves']),
        Exercise(catalogId: 'glute', name: 'Hip Thrust', muscles: ['Glutes']),
        Exercise(catalogId: 'ham', name: 'Romanian Deadlift', muscles: ['Hamstrings']),
        Exercise(catalogId: 'quad', name: 'Back Squat', muscles: ['Quadriceps']),
      ],
      muscles: const ['Piernas', 'Glúteos'],
      equipment: const [],
      languageCode: 'es',
      userId: 'user',
    );
    expect(legs.name, 'Piernas completas');
    expect(legs.exercises.map((exercise) => exercise.exerciseName), [
      'Back Squat',
      'Romanian Deadlift',
      'Hip Thrust',
      'Calf Raise',
    ]);
    expect(routine.exercises.map((exercise) => exercise.exerciseName), [
      'Dumbbell Hip Thrust',
      'Dumbbell Romanian Deadlift',
    ]);
  });

  test('sin músculo reparte la rutina entre grupos', () {
    final routine = AiCoachRoutinePrompt.routineFromExercises(
      exercises: const [
        Exercise(catalogId: 'chest', name: 'Bench Press', category: 'Pecho', muscles: ['Pectorales']),
        Exercise(catalogId: 'back', name: 'Lat Pulldown', category: 'Espalda', muscles: ['Dorsales']),
        Exercise(catalogId: 'legs', name: 'Back Squat', category: 'Piernas', muscles: ['Cuádriceps']),
        Exercise(catalogId: 'shoulders', name: 'Overhead Press', category: 'Hombros', muscles: ['Deltoides']),
      ],
      muscles: const [],
      equipment: const [],
      languageCode: 'es',
      userId: 'user',
    );
    expect(routine.name, 'Rutina');
    expect(routine.exercises.map((exercise) => exercise.exerciseName), [
      'Bench Press',
      'Lat Pulldown',
      'Back Squat',
      'Overhead Press',
    ]);
  });

  test('hombros y abdomen reparte y prioriza lo que ya hace', () {
    final routine = AiCoachRoutinePrompt.routineFromExercises(
      exercises: const [
        Exercise(catalogId: 'press', name: 'Overhead Press', category: 'Hombros', muscles: ['Deltoides']),
        Exercise(catalogId: 'lateral', name: 'Lateral Raise', category: 'Hombros', muscles: ['Deltoides']),
        Exercise(catalogId: 'crunch', name: 'Crunch', category: 'Abdominales', muscles: ['Abdominales']),
        Exercise(catalogId: 'plank', name: 'Plank', category: 'Abdominales', muscles: ['Abdominales']),
      ],
      muscles: const ['Hombros', 'Abdominales'],
      equipment: const [],
      languageCode: 'es',
      userId: 'user',
      frequent: const {'lateral': 4},
    );
    expect(routine.exercises.map((exercise) => exercise.exerciseName), [
      'Lateral Raise',
      'Crunch',
      'Overhead Press',
      'Plank',
    ]);
  });

  test('filterCatalogByEquipment keeps matching exercises only', () {
    const catalog = [
      Exercise(catalogId: 'ff_1', name: 'Dumbbell Curl', equipment: ['Mancuerna']),
      Exercise(catalogId: 'ff_2', name: 'Lat Pulldown', equipment: ['Máquina']),
    ];

    final filtered = AiCoachRoutinePrompt.filterCatalogByEquipment(
      catalog,
      const ['dumbbell'],
    );

    expect(filtered.map((e) => e.id), ['ff_1']);
  });

  test('buildRoutineLimitSection warns when no slots remain', () {
    const status = RoutineLimitStatus(
      used: 10,
      limit: 10,
      tier: SubscriptionTier.free,
    );

    final section = AiCoachRoutinePrompt.buildRoutineLimitSection(
      status: status,
      languageCode: 'es',
    );

    expect(section, contains('Espacios disponibles: 0'));
    expect(section, contains('NO puede guardar'));
  });
}
