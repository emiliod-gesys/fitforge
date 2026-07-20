import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/utils/gym_weight.dart';
import 'package:fitforge/core/utils/unit_converter.dart';

void main() {
  group('GymWeight.snapKg', () {
    test('snaps to whole lb when user uses lb', () {
      // 4.5 kg ≈ 9.92 lb → 10 lb
      final snapped = GymWeight.snapKg(4.5, 'lb');
      final displayLb = UnitConverter.kgToDisplay(snapped, 'lb');
      expect(displayLb, closeTo(10.0, 0.01));
    });

    test('snaps to 0.5 kg increments when user uses kg', () {
      expect(GymWeight.snapKg(4.48, 'kg'), 4.5);
      expect(GymWeight.snapKg(77.3, 'kg'), 77.5);
    });

    test('keeps already-round gym weights', () {
      final tenLbKg = UnitConverter.displayToKg(10, 'lb');
      expect(GymWeight.snapKg(tenLbKg, 'lb'), closeTo(tenLbKg, 0.001));
      expect(GymWeight.snapKg(20, 'kg'), 20);
    });
  });

  group('GymWeight.formatDisplay', () {
    test('shows whole lb without decimals', () {
      final kg = UnitConverter.displayToKg(55, 'lb');
      expect(GymWeight.formatDisplay(kg, 'lb'), '55');
    });

    test('shows kg as integer when whole', () {
      expect(GymWeight.formatDisplay(20, 'kg'), '20');
    });

    test('shows kg with single .5 decimal when needed', () {
      expect(GymWeight.formatDisplay(20.5, 'kg'), '20.5');
      expect(GymWeight.formatDisplay(77.3, 'kg'), '77.5');
    });
  });
}
