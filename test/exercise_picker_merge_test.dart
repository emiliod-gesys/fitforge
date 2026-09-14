import 'package:fitforge/core/utils/exercise_picker_merge.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _ex(String id, String name, {bool custom = false}) => Exercise(
      catalogId: id,
      name: name,
      isUserCustom: custom,
    );

void main() {
  test('cloudCatalogSearchQuery uses muscle filter when search is short', () {
    expect(
      cloudCatalogSearchQuery(search: 'p', muscleFilter: 'Pecho'),
      'Pecho',
    );
    expect(cloudCatalogSearchQuery(search: '', muscleFilter: null), isNull);
    expect(cloudCatalogSearchQuery(search: 'press', muscleFilter: 'Pecho'), 'press');
  });

  test('filterCloudPickerExercises keeps cloud matches without local text filter', () {
    const cloud = Exercise(
      catalogId: 'ext_123',
      name: 'Cable Fly',
      category: 'Pecho',
      muscles: ['Pectoral'],
    );

    final filtered = filterCloudPickerExercises(
      exercises: [cloud],
      muscleFilter: null,
    );

    expect(filtered, hasLength(1));
    expect(
      filterBundledPickerExercises(
        exercises: [cloud],
        search: 'pulley',
      ),
      isEmpty,
    );
    expect(
      filterBundledPickerExercises(
        exercises: [cloud],
        search: 'cable fly',
      ),
      hasLength(1),
    );
  });

  test('cloudExerciseCatalogNotifierKey uses browse when no search or muscle', () {
    expect(
      cloudExerciseCatalogNotifierKey(search: '', muscleFilter: null),
      '__browse__',
    );
    expect(
      cloudExerciseCatalogNotifierKey(search: 'be', muscleFilter: null),
      'be',
    );
    expect(
      cloudExerciseCatalogNotifierKey(
        search: '',
        muscleFilter: 'Pecho',
      ),
      'Pecho',
    );
    expect(
      cloudExerciseCatalogNotifierKey(
        search: '',
        muscleFilter: null,
        cloudDisabled: true,
      ),
      isNull,
    );
  });

  test('mergeRecentExerciseIds keeps local picks first then dated usages', () {
    final merged = mergeRecentExerciseIds(
      localPicks: ['local_a', 'local_b'],
      usages: [
        ExerciseUsage(exerciseId: 'old', usedAt: DateTime(2026, 1, 1)),
        ExerciseUsage(exerciseId: 'fresh', usedAt: DateTime(2026, 3, 1)),
        ExerciseUsage(exerciseId: 'local_a', usedAt: DateTime(2026, 4, 1)),
      ],
    );

    expect(merged, ['local_a', 'local_b', 'fresh', 'old']);
  });

  test('sortPickerExercises puts recents first within the filtered list', () {
    final bench = _ex('bench', 'Bench press');
    final fly = _ex('fly', 'Cable fly');
    final dip = _ex('dip', 'Dip');

    final sorted = sortPickerExercises(
      exercises: [bench, fly, dip],
      recentIds: ['dip', 'bench'],
    );

    expect(sorted.map((e) => e.id), ['dip', 'bench', 'fly']);
  });

  test('sortPickerExercises keeps search relevance ahead of recency', () {
    final bench = _ex('bench', 'Bench press');
    final fly = _ex('fly', 'Cable fly');

    final sorted = sortPickerExercises(
      exercises: [bench, fly],
      recentIds: ['fly'],
      search: 'bench',
    );

    expect(sorted.first.id, 'bench');
  });
}
