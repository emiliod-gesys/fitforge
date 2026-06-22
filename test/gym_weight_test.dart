import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/utils/gym_weight.dart';
import 'package:fitforge/core/utils/unit_converter.dart';

void main() {
  group('GymWeight.snapKg', () {
    test('snaps to 2.5 lb increments when user uses lb', () {
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
}
