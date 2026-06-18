import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/data/exercise_translation_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExerciseTranslationStore', () {
    test('resolveName usa fallback si no hay entrada', () {
      final store = ExerciseTranslationStore();
      expect(
        store.resolveName(exerciseId: '99999', fallback: 'Bench Press', locale: 'es'),
        'Bench Press',
      );
    });
  });
}
