import 'package:fitforge/core/utils/rir_weight_adjustment.dart';
import 'package:fitforge/core/utils/unit_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RirWeightAdjustment', () {
    test('kg: solo RIR 3+ sube 2.5; 0, 1 y 2 mantienen', () {
      expect(
        RirWeightAdjustment.apply(baselineKg: 80, rir: 0, unitSystem: 'kg'),
        80,
      );
      expect(
        RirWeightAdjustment.apply(baselineKg: 80, rir: 1, unitSystem: 'kg'),
        80,
      );
      expect(
        RirWeightAdjustment.apply(baselineKg: 80, rir: 2, unitSystem: 'kg'),
        80,
      );
      expect(
        RirWeightAdjustment.apply(baselineKg: 80, rir: 3, unitSystem: 'kg'),
        82.5,
      );
    });

    test('lb: RIR 3+ sube 5 lb enteras', () {
      final baseline = UnitConverter.displayToKg(185, 'lb');
      final next = RirWeightAdjustment.apply(
        baselineKg: baseline,
        rir: 3,
        unitSystem: 'lb',
      );
      expect(next, isNotNull);
      expect(UnitConverter.kgToDisplay(next!, 'lb').round(), 190);
    });

    test('lb: RIR 0 no baja el peso', () {
      final baseline = UnitConverter.displayToKg(100, 'lb');
      final next = RirWeightAdjustment.apply(
        baselineKg: baseline,
        rir: 0,
        unitSystem: 'lb',
      );
      expect(UnitConverter.kgToDisplay(next!, 'lb').round(), 100);
    });

    test('sin peso de trabajo no ajusta', () {
      expect(
        RirWeightAdjustment.apply(baselineKg: null, rir: 2, unitSystem: 'kg'),
        isNull,
      );
      expect(
        RirWeightAdjustment.apply(baselineKg: 0, rir: 2, unitSystem: 'kg'),
        isNull,
      );
    });

    test('formatLabel usa +3 para RIR 3+', () {
      expect(RirWeightAdjustment.formatLabel(0), '0');
      expect(RirWeightAdjustment.formatLabel(2), '2');
      expect(RirWeightAdjustment.formatLabel(3), '+3');
    });
  });
}
