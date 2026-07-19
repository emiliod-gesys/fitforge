import 'package:fitforge/core/utils/similar_exercises.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _ex({
  required String id,
  required String name,
  String category = '',
  List<String> muscles = const [],
}) =>
    Exercise(
      catalogId: id,
      name: name,
      category: category,
      muscles: muscles,
    );

void main() {
  test('find keeps only exercises with the same primary muscle group', () {
    const catalog = [
      Exercise(catalogId: 'ff_1', name: 'Bench Press', category: 'Pecho', muscles: ['Pectoral']),
      Exercise(catalogId: 'ff_2', name: 'Incline Press', category: 'Pecho', muscles: ['Pectoral']),
      Exercise(catalogId: 'ff_3', name: 'Lat Pulldown', category: 'Espalda', muscles: ['Dorsal']),
      Exercise(
        catalogId: 'ff_4',
        name: 'Close Grip Bench',
        category: 'Pecho',
        muscles: ['Pectoral', 'Tríceps'],
      ),
    ];

    final similar = SimilarExercises.find(
      exerciseName: 'Bench Press',
      exerciseId: 'ff_1',
      catalog: catalog,
      excludeIds: const {},
    );

    expect(similar.map((e) => e.id).toList(), ['ff_4', 'ff_2']);
  });

  test('find excludes forearm exercises when primary muscle is not forearms', () {
    const catalog = [
      Exercise(catalogId: 'ff_1', name: 'Dead Hang', category: 'Antebrazos', muscles: ['Antebrazo']),
      Exercise(
        catalogId: 'ff_2',
        name: 'Farmer Walk',
        category: 'Antebrazos',
        muscles: ['Antebrazo'],
      ),
      Exercise(
        catalogId: 'ff_3',
        name: 'Barbell Curl',
        category: 'Bíceps',
        muscles: ['Bíceps', 'Antebrazo'],
      ),
    ];

    final similar = SimilarExercises.find(
      exerciseName: 'Barbell Curl',
      exerciseId: 'ff_3',
      catalog: catalog,
      excludeIds: const {},
    );

    expect(similar, isEmpty);
  });

  test('filterCloudCandidates applies the same primary muscle rule', () {
    const cloud = [
      Exercise(catalogId: 'ext_1', name: 'Cable Fly', category: 'Pecho', muscles: ['Pectoral']),
      Exercise(catalogId: 'ext_2', name: 'Row', category: 'Espalda', muscles: ['Dorsal']),
    ];

    final filtered = SimilarExercises.filterCloudCandidates(
      cloud: cloud,
      primaryGroup: 'Pecho',
      exerciseId: 'ff_1',
      excludeIds: const {},
    );

    expect(filtered.map((e) => e.id), ['ext_1']);
  });
}
