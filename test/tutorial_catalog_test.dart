import 'package:fitforge/core/tutorials/tutorial_catalog.dart';
import 'package:fitforge/core/tutorials/tutorial_navigation.dart';
import 'package:fitforge/core/tutorials/tutorial_targets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog tours have real targets and unique ids', () {
    expect(
      TutorialCatalog.all.map((t) => t.id),
      [
        'train',
        'food',
        'progress',
        'routines',
        'supersets',
        'foodLog',
      ],
    );
    expect(TutorialCatalog.byId('routines')?.route, '/?tab=routines');
    expect(TutorialCatalog.byId('supersets')?.advanced, isTrue);
    expect(TutorialCatalog.byId('foodLog')?.route, '/food');
    expect(TutorialCatalog.basics.map((t) => t.id), ['train', 'food', 'progress']);
    expect(
      TutorialCatalog.advancedTours.map((t) => t.id),
      ['routines', 'supersets', 'foodLog'],
    );

    for (final tour in TutorialCatalog.all) {
      expect(tour.steps, isNotEmpty);
      for (final step in tour.steps) {
        expect(TutorialTargets.keyFor(step.targetId), isNotNull);
      }
    }
  });

  test('advanced tours push editor and food add routes', () {
    final routines = TutorialCatalog.byId('routines')!;
    expect(
      routines.steps.any(
        (s) => s.route == '/routines/new' && s.nav == TutorialNav.push,
      ),
      isTrue,
    );

    final supersets = TutorialCatalog.byId('supersets')!;
    expect(
      supersets.steps.any((s) => s.targetId == TutorialTargets.routineJoin),
      isTrue,
    );

    final foodLog = TutorialCatalog.byId('foodLog')!;
    expect(
      foodLog.steps.any(
        (s) => s.route == '/food/add' && s.nav == TutorialNav.push,
      ),
      isTrue,
    );
  });

  test('tutorialRouteMatches compares path and required query', () {
    expect(
      tutorialRouteMatches(Uri.parse('/?tab=routines'), '/?tab=routines'),
      isTrue,
    );
    expect(tutorialRouteMatches(Uri.parse('/'), '/?tab=routines'), isFalse);
    expect(tutorialRouteMatches(Uri.parse('/food/add'), '/food/add'), isTrue);
    expect(tutorialRouteMatches(Uri.parse('/food/add'), '/food'), isFalse);
    expect(tutorialRouteMatches(Uri.parse('/food'), '/food'), isTrue);
  });
}
