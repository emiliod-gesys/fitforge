import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/tutorials/tutorial_catalog.dart';

class TutorialState {
  final String? activeTourId;
  final int stepIndex;
  final Set<String> completedIds;
  final bool hydrated;

  const TutorialState({
    this.activeTourId,
    this.stepIndex = 0,
    this.completedIds = const {},
    this.hydrated = false,
  });

  TutorialTour? get activeTour => TutorialCatalog.byId(activeTourId);

  TutorialStep? get activeStep {
    final tour = activeTour;
    if (tour == null) return null;
    if (stepIndex < 0 || stepIndex >= tour.steps.length) return null;
    return tour.steps[stepIndex];
  }

  bool isCompleted(String tourId) => completedIds.contains(tourId);

  TutorialState copyWith({
    String? activeTourId,
    int? stepIndex,
    Set<String>? completedIds,
    bool? hydrated,
    bool clearActive = false,
  }) {
    return TutorialState(
      activeTourId: clearActive ? null : (activeTourId ?? this.activeTourId),
      stepIndex: stepIndex ?? this.stepIndex,
      completedIds: completedIds ?? this.completedIds,
      hydrated: hydrated ?? this.hydrated,
    );
  }
}

class TutorialController extends Notifier<TutorialState> {
  static const prefix = 'tutorial_done_';

  @override
  TutorialState build() {
    Future<void>.microtask(_hydrate);
    return const TutorialState();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final done = <String>{};
    for (final tour in TutorialCatalog.all) {
      if (prefs.getBool('$prefix${tour.id}') ?? false) {
        done.add(tour.id);
      }
    }
    if (!ref.exists(tutorialControllerProvider)) return;
    state = state.copyWith(completedIds: done, hydrated: true);
  }

  void start(String tourId) {
    if (TutorialCatalog.byId(tourId) == null) return;
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
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$prefix$id', true);
    state = state.copyWith(
      clearActive: true,
      stepIndex: 0,
      completedIds: {...state.completedIds, id},
    );
  }
}

final tutorialControllerProvider =
    NotifierProvider<TutorialController, TutorialState>(TutorialController.new);
