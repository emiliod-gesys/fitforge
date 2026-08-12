import 'package:fitforge/core/utils/exercise_text_search.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _ex(String name, {List<String> aliases = const []}) => Exercise(
      catalogId: name,
      name: name,
      aliases: aliases,
    );

void main() {
  test('matches tokens in any order across a multi-word name', () {
    const press = Exercise(
      catalogId: '1',
      name: 'Barbell Bench Press',
      category: 'Pecho',
      muscles: ['Pectoral'],
      equipment: ['Barra'],
    );

    expect(ExerciseTextSearch.matchesExercise(press, 'press banca'), isTrue);
    expect(ExerciseTextSearch.matchesExercise(press, 'banca'), isTrue);
    expect(ExerciseTextSearch.matchesExercise(press, 'barra press'), isTrue);
    expect(ExerciseTextSearch.matchesExercise(press, 'sentadilla'), isFalse);
  });

  test('matches Spanish names when querying English tokens', () {
    expect(
      ExerciseTextSearch.matchesExercise(
        _ex('Press de banca con barra'),
        'bench',
      ),
      isTrue,
    );
  });

  test('matches hammer curl from curl martillo', () {
    expect(
      ExerciseTextSearch.matchesExercise(_ex('Hammer Curl'), 'curl martillo'),
      isTrue,
    );
  });

  test('ignores stopwords like de/con', () {
    expect(
      ExerciseTextSearch.matchesExercise(
        _ex('Press banca inclinada'),
        'press de banca',
      ),
      isTrue,
    );
  });

  test('ranks closer name matches first', () {
    final ranked = ExerciseTextSearch.rank(
      [
        _ex('Incline Dumbbell Press'),
        _ex('Bench Press'),
        _ex('Shoulder Press'),
      ],
      'bench press',
    );
    expect(ranked.first.name, 'Bench Press');
  });
}
