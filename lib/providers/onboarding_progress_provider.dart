import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingProgress {
  final int stepIndex;
  final bool routineCompleted;
  final String? practiceFoodEntryId;
  final bool foodTutorialCompleted;

  const OnboardingProgress({
    this.stepIndex = 0,
    this.routineCompleted = false,
    this.practiceFoodEntryId,
    this.foodTutorialCompleted = false,
  });

  bool get foodLogged => practiceFoodEntryId != null;

  OnboardingProgress copyWith({
    int? stepIndex,
    bool? routineCompleted,
    String? practiceFoodEntryId,
    bool? foodTutorialCompleted,
    bool clearPracticeFoodEntryId = false,
  }) {
    return OnboardingProgress(
      stepIndex: stepIndex ?? this.stepIndex,
      routineCompleted: routineCompleted ?? this.routineCompleted,
      practiceFoodEntryId:
          clearPracticeFoodEntryId ? null : (practiceFoodEntryId ?? this.practiceFoodEntryId),
      foodTutorialCompleted: foodTutorialCompleted ?? this.foodTutorialCompleted,
    );
  }
}

class OnboardingProgressNotifier extends Notifier<OnboardingProgress> {
  @override
  OnboardingProgress build() => const OnboardingProgress();

  void setStepIndex(int index) {
    if (state.stepIndex == index) return;
    state = state.copyWith(stepIndex: index);
  }

  void markRoutineCompleted() {
    state = state.copyWith(routineCompleted: true);
  }

  void markFoodLogged(String entryId) {
    state = state.copyWith(practiceFoodEntryId: entryId);
  }

  void markFoodDeleted() {
    state = state.copyWith(foodTutorialCompleted: true, clearPracticeFoodEntryId: true);
  }

  void reset() {
    state = const OnboardingProgress();
  }
}

final onboardingProgressProvider =
    NotifierProvider<OnboardingProgressNotifier, OnboardingProgress>(
  OnboardingProgressNotifier.new,
);
