import 'package:fitforge/core/utils/exercise_catalog_visibility.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseCatalogVisibility', () {
    test('wger exercise with image is browsable', () {
      const exercise = Exercise(
        wgerId: 1,
        name: 'Bench press',
        imageUrl: 'https://wger.de/media/exercise-images/1/test.jpg',
      );
      expect(ExerciseCatalogVisibility.hasIllustration(exercise), isTrue);
      expect(ExerciseCatalogVisibility.isBrowsable(exercise), isTrue);
    });

    test('wger exercise without image is hidden from catalog', () {
      const exercise = Exercise(wgerId: 2, name: 'Mystery move');
      expect(ExerciseCatalogVisibility.isBrowsable(exercise), isFalse);
    });

    test('user custom exercise is always browsable', () {
      const withoutPhoto = Exercise(
        supabaseId: 'abc',
        name: 'Mi press',
        isUserCustom: true,
      );
      expect(ExerciseCatalogVisibility.isBrowsable(withoutPhoto), isTrue);
    });

    test('user custom with local photo counts as illustrated', () {
      const withPhoto = Exercise(
        supabaseId: 'abc',
        name: 'Mi press',
        isUserCustom: true,
        imageUrl: '/data/user/0/photo.jpg',
      );
      expect(ExerciseCatalogVisibility.hasIllustration(withPhoto), isTrue);
    });
  });
}
