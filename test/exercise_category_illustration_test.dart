import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/utils/exercise_category_illustration.dart';
import 'package:flutter_body_heatmap/flutter_body_heatmap.dart';

void main() {
  group('ExerciseCategoryIllustration', () {
    test('resuelve categorías principales en español', () {
      expect(
        ExerciseCategoryIllustration.resolve(category: 'Abdominales')?.side,
        BodySide.front,
      );
      expect(
        ExerciseCategoryIllustration.resolve(category: 'Pecho')?.data.keys,
        contains(Muscle.chest),
      );
      expect(
        ExerciseCategoryIllustration.resolve(category: 'Trapecios')?.side,
        BodySide.back,
      );
      expect(
        ExerciseCategoryIllustration.resolve(category: 'Pantorrillas')?.data.keys,
        contains(Muscle.calves),
      );
    });

    test('prioriza músculos sobre categoría genérica', () {
      final config = ExerciseCategoryIllustration.resolve(
        category: 'Brazos',
        muscles: ['Tríceps'],
      );
      expect(config?.side, BodySide.back);
      expect(config?.data.keys, contains(Muscle.triceps));
    });

    test('devuelve null para categoría desconocida', () {
      expect(
        ExerciseCategoryIllustration.resolve(category: 'Otros'),
        isNull,
      );
    });
  });
}
