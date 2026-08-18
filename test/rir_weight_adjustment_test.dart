import 'package:fitforge/core/utils/rir_weight_adjustment.dart';
import 'package:fitforge/core/utils/unit_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RirWeightAdjustment', () {
    test('kg: RIR 0 baja 2.5, RIR 1 mantiene, RIR 2 y +3 suben 2.5', () {
      expect(
        RirWeightAdjustment.apply(baselineKg: 80, rir: 0, unitSystem: 'kg'),
        77.5,
      );
      expect(
        RirWeightAdjustment.apply(baselineKg: 80, rir: 1, unitSystem: 'kg'),
        80,
      );
      expect(
        RirWeightAdjustment.apply(baselineKg: 80, rir: 2, unitSystem: 'kg'),
        82.5,
      );
      expect(
        RirWeightAdjustment.apply(baselineKg: 80, rir: 3, unitSystem: 'kg'),
        82.5,
      );
    });

    test('lb: RIR 2 sube 5 lb enteras', () {
      final baseline = UnitConverter.displayToKg(185, 'lb');
      final next = RirWeightAdjustment.apply(
        baselineKg: baseline,
        rir: 2,
        unitSystem: 'lb',
      );
      expect(next, isNotNull);
      expect(UnitConverter.kgToDisplay(next!, 'lb').round(), 190);
    });

    test('lb: RIR 0 baja 5 lb', () {
      final baseline = UnitConverter.displayToKg(100, 'lb');
      final next = RirWeightAdjustment.apply(
        baselineKg: baseline,
        rir: 0,
        unitSystem: 'lb',
      );
      expect(UnitConverter.kgToDisplay(next!, 'lb').round(), 95);
    });

    test('no baja de 0', () {
      expect(
        RirWeightAdjustment.apply(baselineKg: 2, rir: 0, unitSystem: 'kg'),
        0,
      );
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
