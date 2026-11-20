import 'package:fitforge/core/subscription/subscription_features.dart';
import 'package:fitforge/core/utils/exercise_smart_search.dart';
import 'package:fitforge/data/bundled_exercise_catalog.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const frontDumbbell = Exercise(
    name: 'Elevación frontal con mancuernas',
    category: 'Hombros',
    muscles: ['Deltoides anterior'],
    equipment: ['Mancuernas'],
    isBundled: true,
  );
  const frontCable = Exercise(
    name: 'Elevación frontal en polea',
    category: 'Hombros',
    muscles: ['Deltoides anterior'],
    equipment: ['Polea'],
    isBundled: true,
  );
  const shoulderPress = Exercise(
    name: 'Press de hombros con mancuernas',
    category: 'Hombros',
    muscles: ['Deltoides anterior'],
    equipment: ['Mancuernas'],
    isBundled: true,
  );
  const bench = Exercise(
    name: 'Press de banca',
    category: 'Pecho',
    muscles: ['Pecho'],
    equipment: ['Barra'],
    isBundled: true,
  );
  const barbellCurl = Exercise(
    name: 'Curl de bíceps con barra',
    category: 'Bíceps',
    muscles: ['Bíceps'],
    equipment: ['Barra'],
    isBundled: true,
  );
  const dumbbellCurl = Exercise(
    name: 'Curl de bíceps con mancuernas',
    category: 'Bíceps',
    muscles: ['Bíceps'],
    equipment: ['Mancuernas'],
    isBundled: true,
  );
  const legCurl = Exercise(
    name: 'Curl femoral en máquina',
    category: 'Piernas',
    muscles: ['Femoral'],
    equipment: ['Máquina'],
    isBundled: true,
  );

  final catalog = [
    bench,
    frontCable,
    shoulderPress,
    dumbbellCurl,
    barbellCurl,
    legCurl,
    frontDumbbell,
  ];

  test('front delt with dumbbells prefers the dumbbell front raise', () {
    final intent = ExerciseSmartSearch.interpret(
      'para hombro frontal con mancuernas',
    );

    expect(intent.isEmpty, isFalse);
    expect(intent.cloudQuery, 'dumbbell front raise');

    final ranked = ExerciseSmartSearch.rank(catalog, intent);
    expect(ranked, isNotEmpty);
    expect(ranked.first.name, frontDumbbell.name);
    expect(ranked.map((e) => e.name), isNot(contains(frontCable.name)));
    expect(ranked.map((e) => e.name), isNot(contains(bench.name)));
    expect(ranked.indexOf(frontDumbbell), lessThan(ranked.indexOf(shoulderPress)));
  });

  test('barbell curl stays on the bar', () {
    final ranked = ExerciseSmartSearch.rank(
      catalog,
      ExerciseSmartSearch.interpret('curl de biceps con barra'),
    );
    expect(ranked.first.name, barbellCurl.name);
    expect(ranked.map((e) => e.name), isNot(contains(dumbbellCurl.name)));
  });

  test('machine hamstring curl is the femoral recommendation', () {
    final ranked = ExerciseSmartSearch.rank(
      catalog,
      ExerciseSmartSearch.interpret('femoral en maquina'),
    );
    expect(ranked.first.name, legCurl.name);
  });

  test('filler words alone do not invent a search', () {
    expect(
      ExerciseSmartSearch.interpret('para con de').isEmpty,
      isTrue,
    );
  });

  test('smart exercise search is gymrat and gymrat pro', () {
    expect(SubscriptionTier.free.hasSmartExerciseSearch, isFalse);
    expect(SubscriptionTier.gymrat.hasSmartExerciseSearch, isTrue);
    expect(SubscriptionTier.gymratPro.hasSmartExerciseSearch, isTrue);
  });

  test('upper chest dumbbells do not pull other incline movements', () {
    const inclineBench = Exercise(
      catalogId: 'ff_chest_incline_dumbbell_bench_press',
      name: 'Press banca inclinado con mancuernas',
      category: 'Pecho',
      muscles: ['Pecho superior', 'Tríceps', 'Deltoides anterior'],
      equipment: ['Mancuernas'],
      isBundled: true,
    );
    const inclineCurl = Exercise(
      catalogId: 'ff_biceps_incline_dumbbell_curl',
      name: 'Curl de bíceps inclinado con mancuernas',
      category: 'Bíceps',
      muscles: ['Bíceps', 'Antebrazos'],
      equipment: ['Mancuernas'],
      isBundled: true,
    );
    const inclineRow = Exercise(
      catalogId: 'ff_back_dumbbell_incline_row',
      name: 'Remo inclinado con mancuernas',
      category: 'Espalda',
      muscles: ['Espalda alta'],
      equipment: ['Mancuernas'],
      isBundled: true,
    );
    const flatBench = Exercise(
      catalogId: 'ff_chest_dumbbell_bench_press',
      name: 'Press banca con mancuernas',
      category: 'Pecho',
      muscles: ['Pecho'],
      equipment: ['Mancuernas'],
      isBundled: true,
    );
    const oneArm = Exercise(
      name: 'Mancuerna a una mano',
      category: 'Brazos',
      muscles: ['Bíceps'],
      equipment: ['Mancuernas'],
      isBundled: false,
    );

    final ranked = ExerciseSmartSearch.rank(
      [inclineCurl, inclineRow, flatBench, oneArm, inclineBench],
      ExerciseSmartSearch.interpret('para pecho superior con mancuerna'),
    );

    expect(ranked, isNotEmpty);
    expect(ranked.first.catalogId, inclineBench.catalogId);
    expect(ranked.map((e) => e.catalogId), isNot(contains(inclineCurl.catalogId)));
    expect(ranked.map((e) => e.catalogId), isNot(contains(inclineRow.catalogId)));
    expect(ranked.map((e) => e.name), isNot(contains(flatBench.name)));
    expect(ranked.map((e) => e.name), isNot(contains(oneArm.name)));
  });

  test('bundled catalog puts the dumbbell front raise first', () async {
    final exercises = await BundledExerciseCatalog.load(locale: 'es');
    final ranked = ExerciseSmartSearch.rank(
      exercises,
      ExerciseSmartSearch.interpret('para hombro frontal con mancuernas'),
    );

    expect(ranked, isNotEmpty);
    expect(ranked.first.catalogId, 'ff_shoulders_dumbbell_front_raise');
  });

  test('bundled upper chest dumbbells lead with the incline press', () async {
    final exercises = await BundledExerciseCatalog.load(locale: 'es');
    final ranked = ExerciseSmartSearch.rank(
      exercises,
      ExerciseSmartSearch.interpret('para pecho superior con mancuerna'),
    );

    expect(ranked, isNotEmpty);
    expect(ranked.first.catalogId, 'ff_chest_incline_dumbbell_bench_press');
    expect(
      ranked.map((e) => e.catalogId),
      isNot(contains('ff_biceps_incline_dumbbell_curl')),
    );
    expect(
      ranked.map((e) => e.catalogId),
      isNot(contains('ff_back_dumbbell_incline_row')),
    );
    for (final exercise in ranked) {
      final primary = exercise.muscles.isEmpty
          ? ''
          : exercise.muscles.first.toLowerCase();
      expect(
        primary.contains('pecho') || primary.contains('chest'),
        isTrue,
        reason: exercise.name,
      );
    }
  });
}
