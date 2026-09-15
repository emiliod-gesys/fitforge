import 'package:fitforge/core/tutorials/tutorial_catalog.dart';
import 'package:fitforge/core/tutorials/tutorial_navigation.dart';
import 'package:fitforge/core/tutorials/tutorial_targets.dart';
import 'package:fitforge/providers/tutorial_controller.dart';
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
        'workoutSession',
      ],
    );
    expect(TutorialCatalog.byId('routines')?.route, '/?tab=routines');
    expect(TutorialCatalog.byId('supersets')?.advanced, isTrue);
    expect(TutorialCatalog.byId('foodLog')?.route, '/food');
    expect(
        TutorialCatalog.basics.map((t) => t.id), ['train', 'food', 'progress']);
    expect(
      TutorialCatalog.advancedTours.map((t) => t.id),
      ['routines', 'supersets', 'foodLog', 'workoutSession'],
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

    final workoutSession = TutorialCatalog.byId('workoutSession')!;
    expect(workoutSession.advanced, isTrue);
    expect(workoutSession.route, '/');
    expect(
      workoutSession.steps.any(
        (s) => s.route == '/workout/active' && s.nav == TutorialNav.push,
      ),
      isTrue,
    );
    expect(
      workoutSession.steps.map((s) => s.targetId).toList(),
      [
        TutorialTargets.trainStart,
        TutorialTargets.workoutAddExercise,
        TutorialTargets.workoutSwap,
        TutorialTargets.workoutReorder,
        TutorialTargets.workoutRest,
        TutorialTargets.workoutAddSet,
        TutorialTargets.workoutRemoveSet,
      ],
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

  test('pending nudge snooze lasts until the next local day', () {
    final now = DateTime(2026, 9, 14, 20, 15);
    final until = tutorialNudgeSnoozeUntil(now);
    expect(until, DateTime(2026, 9, 15));
    expect(tutorialNudgeIsSnoozed(now, until), isTrue);
    expect(tutorialNudgeIsSnoozed(DateTime(2026, 9, 15), until), isFalse);
  });

  test('pending nudge hides when every tour is done or snoozed', () {
    final allIds = TutorialCatalog.all.map((tour) => tour.id).toSet();
    const empty = TutorialState(userId: 'user-a', hydrated: true);
    expect(empty.pendingCount, TutorialCatalog.all.length);
    expect(empty.showPendingNudge, isTrue);

    final done = TutorialState(
      userId: 'user-a',
      hydrated: true,
      completedIds: allIds,
    );
    expect(done.pendingCount, 0);
    expect(done.showPendingNudge, isFalse);

    final snoozed = TutorialState(
      userId: 'user-a',
      hydrated: true,
      snoozedUntil: DateTime.now().add(const Duration(hours: 12)),
    );
    expect(snoozed.showPendingNudge, isFalse);

    const loggedOut = TutorialState(hydrated: true);
    expect(loggedOut.showPendingNudge, isFalse);
  });
}
