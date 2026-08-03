import 'package:fitforge/core/utils/age_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgeCalculator', () {
    test('computes age after birthday in the year', () {
      final asOf = DateTime(2026, 8, 2);
      expect(
        AgeCalculator.yearsFromDateOfBirth(DateTime(2000, 3, 1), asOf),
        26,
      );
    });

    test('computes age before birthday in the year', () {
      final asOf = DateTime(2026, 8, 2);
      expect(
        AgeCalculator.yearsFromDateOfBirth(DateTime(2000, 12, 1), asOf),
        25,
      );
    });

    test('estimates date of birth from age', () {
      final asOf = DateTime(2026, 8, 2);
      expect(
        AgeCalculator.estimateDateOfBirthFromAge(30, asOf),
        DateTime(1996, 8, 2),
      );
    });

    test('validates age range', () {
      expect(AgeCalculator.isValidAge(13), isTrue);
      expect(AgeCalculator.isValidAge(12), isFalse);
      expect(AgeCalculator.isValidAge(120), isFalse);
    });
  });
}
