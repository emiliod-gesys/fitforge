import 'package:fitforge/core/workout/smart_routine_builder.dart';
import 'package:fitforge/core/workout/smart_routine_catalog.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _exercise(String id, String name, String primary) {
  return Exercise(
    catalogId: id,
    name: name,
    muscles: [primary],
    isBundled: true,
  );
}

SmartMuscleTarget _target(String id) {
  return SmartRoutineCatalog.targets.firstWhere((target) => target.id == id);
}

void main() {
  final catalog = [
    _exercise('ff_chest_barbell_bench_press', 'Press banca con barra', 'Pecho'),
    _exercise('ff_chest_dumbbell_bench_press', 'Press banca con mancuernas', 'Pecho'),
    _exercise('ff_chest_incline_barbell_bench_press', 'Press inclinado', 'Pecho superior'),
    _exercise('ff_legs_back_squat', 'Sentadilla trasera', 'Cuádriceps'),
    _exercise('ff_legs_leg_press_machine', 'Prensa', 'Cuádriceps'),
    _exercise('ff_custom_quad', 'Extensión rara', 'Cuádriceps'),
    _exercise('ff_abs_crunch', 'Crunch', 'Abdominales'),
  ];

  test('prioriza el ejercicio reciente y luego el más habitual del gym', () {
    final routine = SmartRoutineBuilder.build(
      targets: [_target('cuadriceps')],
      catalog: catalog,
      recent: const [
        RecentExerciseRef(id: 'ff_custom_quad', name: 'Extensión rara'),
      ],
      languageCode: 'es',
      namePrefix: 'Rutina inteligente',
    );

    expect(routine.exercises.first.exerciseId, 'ff_custom_quad');
    expect(routine.exercises[1].exerciseId, 'ff_legs_back_squat');
    expect(routine.exercises.map((e) => e.exerciseId), isNot(contains('ff_abs_crunch')));
  });

  test('sin historial usa el ejercicio más habitual y no duplica el equipo', () {
    final routine = SmartRoutineBuilder.build(
      targets: [_target('pecho')],
      catalog: catalog,
      recent: const [],
      languageCode: 'es',
      namePrefix: 'Rutina inteligente',
    );

    expect(routine.exercises.single.exerciseId, 'ff_chest_barbell_bench_press');
    expect(routine.exercises.single.targetSets, 5);
    expect(routine.exercises.single.targetSetDetails, hasLength(5));
  });

  test('el mismo press con barra y mancuernas queda en uno solo con más series', () {
    final routine = SmartRoutineBuilder.build(
      targets: [
        _target('pecho_superior'),
        _target('pecho_inferior'),
        _target('deltoides_anterior'),
        _target('deltoides_lateral'),
        _target('triceps'),
      ],
      catalog: [
        _exercise(
          'ff_chest_incline_barbell_bench_press',
          'Press banca inclinado con barra',
          'Pecho superior',
        ),
        _exercise(
          'ff_chest_incline_dumbbell_bench_press',
          'Press banca inclinado con mancuernas',
          'Pecho superior',
        ),
        _exercise(
          'ff_chest_low_to_high_cable_fly',
          'Cruce bajo a alto en polea',
          'Pecho superior',
        ),
        _exercise(
          'ff_chest_decline_barbell_bench_press',
          'Press banca declinado con barra',
          'Pecho inferior',
        ),
        _exercise(
          'ff_chest_decline_dumbbell_bench_press',
          'Press banca declinado con mancuernas',
          'Pecho inferior',
        ),
        _exercise(
          'ff_shoulders_dumbbell_shoulder_press',
          'Press de hombro con mancuernas',
          'Deltoides anterior',
        ),
        _exercise(
          'ff_shoulders_shoulder_press_machine',
          'Press de hombro en máquina',
          'Deltoides anterior',
        ),
        _exercise(
          'ff_shoulders_dumbbell_lateral_raise',
          'Elevación lateral con mancuernas',
          'Deltoides lateral',
        ),
        _exercise('ff_triceps_parallel_bar_dip', 'Fondos en paralelas', 'Tríceps'),
      ],
      recent: const [
        RecentExerciseRef(id: 'ff_triceps_parallel_bar_dip', name: 'Fondos en paralelas'),
      ],
      languageCode: 'es',
      namePrefix: 'Rutina inteligente',
    );

    final byId = {for (final exercise in routine.exercises) exercise.exerciseId: exercise};
    expect(byId.containsKey('ff_chest_incline_dumbbell_bench_press'), isFalse);
    expect(byId.containsKey('ff_chest_decline_dumbbell_bench_press'), isFalse);
    expect(byId.containsKey('ff_shoulders_shoulder_press_machine'), isFalse);
    expect(byId['ff_chest_incline_barbell_bench_press']!.targetSets, 5);
    expect(byId['ff_chest_decline_barbell_bench_press']!.targetSets, 5);
    expect(byId['ff_shoulders_dumbbell_shoulder_press']!.targetSets, 5);
    expect(byId['ff_shoulders_dumbbell_lateral_raise']!.targetSets, 3);
    expect(byId['ff_triceps_parallel_bar_dip']!.targetSets, 3);
    expect(byId.containsKey('ff_chest_low_to_high_cable_fly'), isFalse);
  });

  test('un press y una apertura siguen siendo dos ejercicios', () {
    final routine = SmartRoutineBuilder.build(
      targets: [_target('pecho')],
      catalog: [
        _exercise('ff_chest_dumbbell_bench_press', 'Press banca con mancuernas', 'Pecho'),
        _exercise('ff_chest_barbell_bench_press', 'Press banca con barra', 'Pecho'),
        _exercise('ff_chest_dumbbell_fly', 'Aperturas con mancuernas', 'Pecho'),
      ],
      recent: const [
        RecentExerciseRef(
          id: 'ff_chest_dumbbell_bench_press',
          name: 'Press banca con mancuernas',
        ),
      ],
      languageCode: 'es',
      namePrefix: 'Rutina inteligente',
    );

    expect(routine.exercises.map((e) => e.exerciseId), [
      'ff_chest_dumbbell_bench_press',
      'ff_chest_dumbbell_fly',
    ]);
    expect(routine.exercises[0].targetSets, 5);
    expect(routine.exercises[1].targetSets, 3);
  });

  test('pecho no mezcla pecho superior', () {
    final routine = SmartRoutineBuilder.build(
      targets: [_target('pecho_superior')],
      catalog: catalog,
      recent: const [],
      languageCode: 'en',
      namePrefix: 'Smart routine',
    );

    expect(routine.exercises.single.exerciseId, 'ff_chest_incline_barbell_bench_press');
    expect(routine.name, 'Smart routine · Upper chest');
  });

  test('varios músculos no repiten ejercicios y respetan el tope', () {
    final bigCatalog = [
      for (var i = 0; i < 8; i++)
        _exercise('chest_$i', 'Chest $i', 'Pecho'),
      for (var i = 0; i < 8; i++)
        _exercise('lat_$i', 'Lat $i', 'Dorsales'),
    ];
    final routine = SmartRoutineBuilder.build(
      targets: [_target('pecho'), _target('dorsales')],
      catalog: bigCatalog,
      recent: const [],
      languageCode: 'es',
      namePrefix: 'Rutina inteligente',
    );

    final ids = routine.exercises.map((e) => e.exerciseId).toList();
    expect(ids.length, lessThanOrEqualTo(SmartRoutineBuilder.maxExercises));
    expect(ids.toSet().length, ids.length);
    expect(ids.where((id) => id.startsWith('chest_')).length, 4);
    expect(ids.where((id) => id.startsWith('lat_')).length, 4);
  });

  test('si hay más de ocho músculos, entra al menos uno de cada uno', () {
    final targets = SmartRoutineCatalog.targets.take(9).toList();
    final catalog = [
      for (final target in targets)
        _exercise('ex_${target.id}', target.labelEs, target.labelEs),
    ];
    final routine = SmartRoutineBuilder.build(
      targets: targets,
      catalog: catalog,
      recent: const [],
      languageCode: 'es',
      namePrefix: 'Rutina inteligente',
    );

    expect(routine.exercises.length, 9);
    expect(
      routine.exercises.map((e) => e.exerciseId).toSet(),
      {for (final target in targets) 'ex_${target.id}'},
    );
  });
}
