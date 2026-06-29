import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge/data/bundled_exercise_catalog.dart';
import 'package:fitforge/models/exercise_logging.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BundledExerciseCatalog.clearCache();
  });

  test('loads full Spanish catalog from Excel import', () async {
    final exercises = await BundledExerciseCatalog.load(locale: 'es');

    expect(exercises.length, 200);
    expect(exercises.every((e) => e.isBundled), isTrue);
    expect(exercises.any((e) => e.catalogId == 'ff_back_pull_up'), isTrue);
    expect(
      exercises.firstWhere((e) => e.catalogId == 'ff_back_pull_up').name,
      'Dominada prona',
    );
  });

  test('bodyweight exercises allow optional added weight', () async {
    final exercises = await BundledExerciseCatalog.load(locale: 'es');
    final pushUp = exercises.firstWhere((e) => e.catalogId == 'ff_chest_push_up');

    expect(pushUp.loadMode, ExerciseLoadMode.bodyweight);
    expect(pushUp.weightOptional, isTrue);
    expect(pushUp.muscles, isNotEmpty);
  });

  test('dual load dumbbell exercises use per-arm weight', () async {
    final exercises = await BundledExerciseCatalog.load(locale: 'es');
    final curl = exercises.firstWhere(
      (e) => e.catalogId == 'ff_biceps_alternating_dumbbell_curl',
    );

    expect(curl.perArmWeight, isTrue);
    expect(curl.unilateral, isTrue);
  });

  test('jump rope logs as cardio duration', () async {
    final exercises = await BundledExerciseCatalog.load(locale: 'es');
    final rope = exercises.firstWhere((e) => e.catalogId == 'ff_cardio_jump_rope');

    expect(rope.loggingType, ExerciseLoggingType.cardio);
    expect(rope.category, 'Cardio');
    expect(rope.isCardio, isTrue);
    expect(rope.cardioConfig, isNotNull);
  });

  test('cardio machine exercises are in Cardio category', () async {
    final exercises = await BundledExerciseCatalog.load(locale: 'es');
    final treadmill = exercises.firstWhere((e) => e.catalogId == 'ff_cardio_treadmill');

    expect(treadmill.loggingType, ExerciseLoggingType.cardio);
    expect(treadmill.loadMode, ExerciseLoadMode.cardioMachine);
    expect(treadmill.cardioConfig?.enabledMetrics, contains(CardioMetric.duration));
  });

  test('loads English names when locale is en', () async {
    BundledExerciseCatalog.clearCache();
    final exercises = await BundledExerciseCatalog.load(locale: 'en');
    final pullUp = exercises.firstWhere((e) => e.catalogId == 'ff_back_pull_up');

    expect(pullUp.name, 'Pull Up');
  });
}
