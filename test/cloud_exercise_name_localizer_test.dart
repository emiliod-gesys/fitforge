import 'package:fitforge/core/utils/cloud_exercise_name_localizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localize uses phrase rules for common cloud exercise names', () {
    final fly = CloudExerciseNameLocalizer.localize(
      nameEn: 'dumbbell one arm bench fly',
      nameEs: 'dumbbell one arm bench fly',
      locale: 'es',
    );
    expect(fly.toLowerCase(), contains('mancuerna'));
    expect(fly.toLowerCase(), isNot(contains('dumbbell')));

    final curl = CloudExerciseNameLocalizer.localize(
      nameEn: 'dumbbell over bench neutral wrist curl',
      nameEs: 'dumbbell over bench neutral wrist curl',
      locale: 'es',
    );
    expect(curl.toLowerCase(), contains('muñeca'));
    expect(curl.toLowerCase(), isNot(contains('wrist curl')));

    final triceps = CloudExerciseNameLocalizer.localize(
      nameEn: 'dumbbell one arm triceps extension (on bench)',
      nameEs: 'dumbbell one arm triceps extension (on bench)',
      locale: 'es',
    );
    expect(triceps.toLowerCase(), contains('tríceps'));
  });

  test('localize keeps English names in English locale', () {
    expect(
      CloudExerciseNameLocalizer.localize(
        nameEn: 'barbell bench press',
        nameEs: 'barbell bench press',
        locale: 'en',
      ),
      'barbell bench press',
    );
  });
}
