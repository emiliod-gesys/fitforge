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

  test('mergeBundledAndCloudExercises deduplicates by id', () {
    final bundled = [_ex('ff_1', 'Bench Press')];
    final cloud = [_ex('ext_1', 'Incline Fly'), _ex('ff_1', 'Bench Press duplicate')];

    final merged = mergeBundledAndCloudExercises(bundled: bundled, cloud: cloud);

    expect(merged.map((e) => e.id), ['ff_1', 'ext_1']);
  });
}
