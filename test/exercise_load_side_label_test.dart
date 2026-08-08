import 'package:fitforge/core/utils/exercise_load.dart';
import 'package:fitforge/data/bundled_exercise_catalog.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseLoad.isLowerBodySideLoad', () {
    test('detects leg machines by name', () {
      expect(
        ExerciseLoad.isLowerBodySideLoad(exerciseName: 'Prensa de piernas'),
        isTrue,
      );
      expect(
        ExerciseLoad.isLowerBodySideLoad(
            exerciseName: 'Extensión de cuádriceps'),
        isTrue,
      );
      expect(
        ExerciseLoad.isLowerBodySideLoad(exerciseName: 'Leg curl'),
        isTrue,
      );
    });

    test('does not flag arm exercises', () {
      expect(
        ExerciseLoad.isLowerBodySideLoad(
            exerciseName: 'Curl de bíceps con mancuernas'),
        isFalse,
      );
      expect(
        ExerciseLoad.isLowerBodySideLoad(exerciseName: 'Press militar'),
        isFalse,
      );
    });

    test('uses category from catalog exercise', () {
      const legs = Exercise(
        name: 'Máquina desconocida',
        category: 'Piernas',
        loadMode: ExerciseLoadMode.machineStack,
        isBundled: true,
      );
      expect(
        ExerciseLoad.isLowerBodySideLoad(
          exerciseName: legs.name,
          exercise: legs,
        ),
        isTrue,
      );
    });

    test('weightLabel picks leg suffix when requested', () {
      expect(
        ExerciseLoad.weightLabel(
          'kg',
          'Prensa',
          perArmWeight: true,
          useLegLabel: true,
          perLegSuffix: '(por pierna)',
        ),
        'kg (por pierna)',
      );
      expect(
        ExerciseLoad.weightLabel(
          'kg',
          'Curl',
          perArmWeight: true,
          useLegLabel: false,
        ),
        'kg (por brazo)',
      );
    });
  });

  group('ExerciseLoad.supportsPerArmToggle', () {
    test('leg extension machine supports combined/per-leg toggle', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final catalog = await BundledExerciseCatalog.load(locale: 'es');
      final legExt = catalog
          .firstWhere((e) => e.catalogId == 'ff_legs_leg_extension_machine');

      expect(legExt.loadMode, ExerciseLoadMode.machineStack);
      expect(legExt.perArmWeight, isFalse);
      expect(
        ExerciseLoad.supportsPerArmToggle(legExt.id, catalog, legExt.name),
        isTrue,
      );
      expect(
        ExerciseLoad.resolvePerArmWeight(
          exerciseId: legExt.id,
          catalog: catalog,
          exerciseName: legExt.name,
        ),
        isFalse,
      );
      expect(
        ExerciseLoad.resolvePerArmWeight(
          exerciseId: legExt.id,
          catalog: catalog,
          exerciseName: legExt.name,
          sessionOverride: true,
        ),
        isTrue,
      );
      expect(
        ExerciseLoad.resolvePerArmWeight(
          exerciseId: legExt.id,
          catalog: catalog,
          exerciseName: legExt.name,
          sessionOverride: false,
        ),
        isFalse,
      );
      expect(
          ExerciseLoad.combinedModeUsesLegLabel(
              exerciseName: legExt.name, exercise: legExt),
          isTrue);
    });

    test('concentration curl supports per-arm toggle via dumbbell equipment',
        () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final catalog = await BundledExerciseCatalog.load(locale: 'en');
      final concentration = catalog.firstWhere(
        (e) => e.catalogId == 'ff_biceps_concentration_curl',
      );

      expect(concentration.name, 'Concentration Curl');
      expect(concentration.equipment, contains('Dumbbell'));
      expect(concentration.unilateral, isTrue);
      expect(
        ExerciseLoad.supportsPerArmToggle(
            concentration.id, catalog, concentration.name),
        isTrue,
      );
      expect(
        ExerciseLoad.resolvePerArmWeight(
          exerciseId: concentration.id,
          catalog: catalog,
          exerciseName: concentration.name,
        ),
        isTrue,
      );
      expect(
        ExerciseLoad.weightLabel(
          'kg',
          concentration.name,
          perArmWeight: ExerciseLoad.resolvePerArmWeight(
            exerciseId: concentration.id,
            catalog: catalog,
            exerciseName: concentration.name,
          ),
        ),
        'kg (por brazo)',
      );
    });

    test('unilateral cable row supports and defaults to per-arm', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final catalog = await BundledExerciseCatalog.load(locale: 'en');
      final cableRow = catalog.firstWhere(
        (e) => e.catalogId == 'ff_back_high_cable_row',
      );

      expect(cableRow.equipment, contains('Cable'));
      expect(cableRow.unilateral, isTrue);
      expect(
        ExerciseLoad.supportsPerArmToggle(cableRow.id, catalog, cableRow.name),
        isTrue,
      );
      expect(
        ExerciseLoad.resolvePerArmWeight(
          exerciseId: cableRow.id,
          catalog: catalog,
          exerciseName: cableRow.name,
        ),
        isTrue,
      );
    });

    test('cloud exercises respect per-arm and unilateral metadata', () {
      const cloudExercise = Exercise(
        catalogId: 'ext_cable_one_arm_bent_over_row',
        name: 'Cable One Arm Bent Over Row',
        equipment: ['Cable'],
        perArmWeight: true,
        unilateral: true,
      );
      const catalog = [cloudExercise];

      expect(
        ExerciseLoad.perArmWeightForExerciseId(cloudExercise.id, catalog),
        isTrue,
      );
      expect(
        ExerciseLoad.unilateralForExerciseId(cloudExercise.id, catalog),
        isTrue,
      );
      expect(
        ExerciseLoad.supportsPerArmToggle(
          cloudExercise.id,
          catalog,
          cloudExercise.name,
        ),
        isTrue,
      );
      expect(
        ExerciseLoad.resolvePerArmWeight(
          exerciseId: cloudExercise.id,
          catalog: catalog,
          exerciseName: cloudExercise.name,
        ),
        isTrue,
      );
    });
  });
}
