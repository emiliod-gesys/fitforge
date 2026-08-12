import 'package:fitforge/core/utils/quantity_format.dart';
import 'package:fitforge/core/utils/unit_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuantityFormat', () {
    test('groups thousands with commas', () {
      expect(QuantityFormat.integer(1293929), '1,293,929');
      expect(QuantityFormat.integer(19998), '19,998');
      expect(QuantityFormat.integer(12), '12');
    });

    test('keeps a period as the decimal separator', () {
      expect(QuantityFormat.decimal(171.2, decimals: 1), '171.2');
      expect(QuantityFormat.decimal(1000.5, decimals: 1), '1,000.5');
    });

    test('formats kcal labels', () {
      expect(QuantityFormat.kcal(19998), '19,998 kcal');
    });
  });

  group('UnitConverter grouped quantities', () {
    test('formatVolume groups lb totals', () {
      final kg = 1293929 / UnitConverter.lbPerKg;
      expect(UnitConverter.formatVolume(kg, 'lb'), '1,293,929 lb');
    });

    test('formatMass keeps body-weight decimals', () {
      expect(UnitConverter.formatMass(77.655, 'lb'), '171.2 lb');
    });
  });
}
