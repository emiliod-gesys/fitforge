import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/tutorials/tutorial_catalog.dart';
import '../core/tutorials/tutorial_workout_session.dart';
import 'app_providers.dart';

DateTime tutorialNudgeSnoozeUntil(DateTime now) {
  return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
}

bool tutorialNudgeIsSnoozed(DateTime now, DateTime? until) {
  return until != null && now.isBefore(until);
}

const tutorialLegacyDonePrefix = 'tutorial_done_';
const tutorialLegacySnoozeKey = 'tutorial_nudge_snooze_until';

String tutorialDonePrefKey(String userId, String tourId) =>
    'tutorial_done_${userId}_$tourId';

String tutorialSnoozePrefKey(String userId) =>
    'tutorial_nudge_snooze_until_$userId';

String tutorialLegacyDonePrefKey(String tourId) =>
    '$tutorialLegacyDonePrefix$tourId';

Set<String> tutorialCompletedIdsForUser(
  SharedPreferences prefs,
  String userId,
) {
  final done = <String>{};
  for (final tour in TutorialCatalog.all) {
    if (prefs.getBool(tutorialDonePrefKey(userId, tour.id)) ?? false) {
      done.add(tour.id);
    }
  }
  return done;
}

Future<void> tutorialPurgeLegacyUnscopedKeys(SharedPreferences prefs) async {
  for (final tour in TutorialCatalog.all) {
    await prefs.remove(tutorialLegacyDonePrefKey(tour.id));
  }
  await prefs.remove(tutorialLegacySnoozeKey);
}

class TutorialState {
  final String? userId;
  final String? activeTourId;
  final int stepIndex;
  final Set<String> completedIds;
  final bool hydrated;
  final DateTime? snoozedUntil;

  const TutorialState({
    this.userId,
    this.activeTourId,
    this.stepIndex = 0,
    this.completedIds = const {},
    this.hydrated = false,
    this.snoozedUntil,
  });

  TutorialTour? get activeTour => TutorialCatalog.byId(activeTourId);

  TutorialStep? get activeStep {
    final tour = activeTour;
    if (tour == null) return null;
    if (stepIndex < 0 || stepIndex >= tour.steps.length) return null;
    return tour.steps[stepIndex];
  }

  bool isCompleted(String tourId) => completedIds.contains(tourId);

  int get pendingCount {
    var count = 0;
    for (final tour in TutorialCatalog.all) {
      if (!completedIds.contains(tour.id)) count++;
    }
    return count;
  }

  bool get showPendingNudge {
    if (userId == null || userId!.isEmpty) return false;
    if (!hydrated || pendingCount <= 0) return false;
    return !tutorialNudgeIsSnoozed(DateTime.now(), snoozedUntil);
  }

  TutorialState copyWith({
    String? userId,
    String? activeTourId,
    int? stepIndex,
    Set<String>? completedIds,
    bool? hydrated,
    DateTime? snoozedUntil,
    bool clearActive = false,
    bool clearSnooze = false,
    bool clearUserId = false,
  }) {
    return TutorialState(
      userId: clearUserId ? null : (userId ?? this.userId),
      activeTourId: clearActive ? null : (activeTourId ?? this.activeTourId),
      stepIndex: stepIndex ?? this.stepIndex,
      completedIds: completedIds ?? this.completedIds,
      hydrated: hydrated ?? this.hydrated,
      snoozedUntil: clearSnooze ? null : (snoozedUntil ?? this.snoozedUntil),
    );
  }
}

class TutorialController extends Notifier<TutorialState> {
  @override
  TutorialState build() {
    final userId = ref.watch(authUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return const TutorialState(hydrated: true);
    }
    Future<void>.microtask(() => _hydrate(userId));
    return TutorialState(userId: userId);
  }

  Future<void> _hydrate(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await tutorialPurgeLegacyUnscopedKeys(prefs);
    final done = tutorialCompletedIdsForUser(prefs, userId);
    final snoozeRaw = prefs.getString(tutorialSnoozePrefKey(userId));
    final snoozedUntil =
        snoozeRaw == null ? null : DateTime.tryParse(snoozeRaw);
    if (!_isCurrentUser(userId)) return;
    state = TutorialState(
      userId: userId,
      completedIds: done,
      hydrated: true,
      snoozedUntil: snoozedUntil,
    );
  }

  bool _isCurrentUser(String userId) {
    return ref.exists(tutorialControllerProvider) &&
        ref.read(authUserIdProvider) == userId;
  }

  void start(String tourId) {
    if (TutorialCatalog.byId(tourId) == null) return;
    if (tourId != TutorialCatalog.workoutSession) {
      unawaited(ref.read(tutorialWorkoutSessionProvider.notifier).discard());
    }
    state = state.copyWith(activeTourId: tourId, stepIndex: 0);
  }

  void next() {
    final tour = state.activeTour;
    if (tour == null) return;
    if (state.stepIndex >= tour.steps.length - 1) {
      complete();
      return;
    }
    state = state.copyWith(stepIndex: state.stepIndex + 1);
  }

  void skip() => complete();

  Future<void> complete() async {
    final id = state.activeTourId;
    final userId = ref.read(authUserIdProvider);
    if (id == null || userId == null || userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tutorialDonePrefKey(userId, id), true);
    if (!_isCurrentUser(userId)) return;
    state = state.copyWith(
      clearActive: true,
      stepIndex: 0,
      completedIds: {...state.completedIds, id},
    );
    if (ref.exists(tutorialWorkoutSessionProvider)) {
      await ref.read(tutorialWorkoutSessionProvider.notifier).discard();
    }
  }

  Future<void> completeAll() async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null || userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = {for (final tour in TutorialCatalog.all) tour.id};
    for (final id in ids) {
      await prefs.setBool(tutorialDonePrefKey(userId, id), true);
    }
    await prefs.remove(tutorialSnoozePrefKey(userId));
    if (!_isCurrentUser(userId)) return;
    state = state.copyWith(
      clearActive: true,
      stepIndex: 0,
      completedIds: ids,
      clearSnooze: true,
    );
    if (ref.exists(tutorialWorkoutSessionProvider)) {
      await ref.read(tutorialWorkoutSessionProvider.notifier).discard();
    }
  }

  Future<void> snoozeNudgeUntilTomorrow() async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null || userId.isEmpty) return;
    final until = tutorialNudgeSnoozeUntil(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      tutorialSnoozePrefKey(userId),
      until.toIso8601String(),
    );
    if (!_isCurrentUser(userId)) return;
    state = state.copyWith(snoozedUntil: until);
  }
}

final tutorialControllerProvider =
    NotifierProvider<TutorialController, TutorialState>(TutorialController.new);
