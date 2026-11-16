import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/exercise_load.dart';
import '../core/utils/exercise_logging_resolver.dart';
import '../core/utils/exercise_text_search.dart';
import '../core/utils/gym_weight.dart';
import '../core/utils/unit_converter.dart';
import '../core/voice/voice_command.dart';
import '../core/voice/voice_exercise_match.dart';
import '../core/voice/voice_lines.dart';
import 'rest_preferences.dart';
import '../models/exercise.dart';
import '../models/exercise_logging.dart';
import '../models/profile.dart';
import '../models/workout.dart';
import '../providers/app_providers.dart';

sealed class VoicePending {
  const VoicePending();
}

class VoicePendingAdd extends VoicePending {
  const VoicePendingAdd({required this.exercise, required this.spokenName});
  final Exercise exercise;
  final String spokenName;
}

class VoicePendingLog extends VoicePending {
  const VoicePendingLog({
    required this.workoutId,
    required this.workoutExerciseId,
    required this.set,
    required this.spoken,
  });

  final String workoutId;
  final String workoutExerciseId;
  final WorkoutSet set;
  final String spoken;
}

class VoicePendingDelete extends VoicePending {
  const VoicePendingDelete({
    required this.workoutId,
    required this.workoutExerciseId,
    required this.setId,
  });

  final String workoutId;
  final String workoutExerciseId;
  final String setId;
}

class VoiceProposal {
  const VoiceProposal(this.say, {this.pending});
  final String say;
  final VoicePending? pending;
}

/// Resuelve una orden con los datos reales de la cuenta.
class VoiceActionRunner {
  VoiceActionRunner(this._ref);

  final WidgetRef _ref;

  Future<VoiceProposal> propose(VoiceIntent intent, {required bool english}) async {
    switch (intent) {
      case VoiceAskDay():
        return VoiceProposal(await _day(english));
      case VoiceAskWorkout():
        return VoiceProposal(await _workoutStatus(english));
      case VoiceAskRecord(:final query):
        return VoiceProposal(await _record(english, query));
      case VoiceAddExercise(:final query):
        return _proposeAdd(english, query);
      case VoiceAddSets(:final count):
        return VoiceProposal(
          await adjustSets(english: english, add: true, count: count),
        );
      case VoiceLogSet(:final weight, :final reps, :final unit):
        return VoiceProposal(
          await logFocusedSet(
            english: english,
            weight: weight,
            reps: reps,
            unit: unit,
          ),
        );
      case VoiceSetRest(:final seconds):
        return VoiceProposal(await setRest(english: english, seconds: seconds));
      case VoiceRemoveLastSet(:final count):
        return VoiceProposal(
          await adjustSets(english: english, add: false, count: count),
        );
      case VoiceConfirmYes():
      case VoiceConfirmNo():
      case VoiceUnknown():
        return VoiceProposal(VoiceLines.didNotCatch(english));
    }
  }

  Future<String> confirm(VoicePending pending, {required bool english}) async {
    try {
      switch (pending) {
        case VoicePendingAdd(:final exercise, :final spokenName):
          final workout = await _activeWorkout();
          if (workout == null) return VoiceLines.noWorkout(english);
          await _ref.read(workoutServiceProvider).addExerciseToWorkout(
                workout.id,
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                imageUrl: exercise.imageUrl,
                loggingType: exercise.loggingType,
              );
          _ref.invalidate(activeWorkoutProvider);
          return VoiceLines.added(english, spokenName);
        case VoicePendingLog(
            :final workoutId,
            :final workoutExerciseId,
            :final set,
          ):
          await _ref.read(workoutServiceProvider).logSet(
                workoutExerciseId,
                set,
                workoutId: workoutId,
              );
          _ref.invalidate(activeWorkoutProvider);
          return VoiceLines.logged(english);
        case VoicePendingDelete(
            :final workoutId,
            :final workoutExerciseId,
            :final setId,
          ):
          await _ref.read(workoutServiceProvider).deleteSet(
                workoutExerciseId,
                setId,
                workoutId: workoutId,
              );
          _ref.invalidate(activeWorkoutProvider);
          return VoiceLines.deleted(english);
      }
    } catch (_) {
      return switch (pending) {
        VoicePendingAdd() => VoiceLines.couldNotAdd(english),
        VoicePendingLog() => VoiceLines.couldNotLog(english),
        VoicePendingDelete() => VoiceLines.couldNotDelete(english),
      };
    }
  }

  Future<String> adjustSets({
    required bool english,
    required bool add,
    required int count,
  }) async {
    final workout = await _activeWorkout();
    if (workout == null) return VoiceLines.noWorkout(english);
    final focusId = _ref.read(activeWorkoutFocusProvider);
    WorkoutExercise? exercise;
    if (focusId != null) {
      for (final item in workout.exercises) {
        if (item.id == focusId) {
          exercise = item;
          break;
        }
      }
    }
    if (exercise == null) return VoiceLines.needOpenExercise(english);

    final amount = count.clamp(1, 8);
    try {
      if (add) {
        await _insertSets(workout, exercise, amount);
        _ref.invalidate(activeWorkoutProvider);
        return VoiceLines.setsAdded(english, amount, exercise.exerciseName);
      }
      final sets = [...exercise.sets]
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
      if (sets.isEmpty) return VoiceLines.noSetToRemove(english);
      final removing = sets.reversed.take(amount).toList();
      final service = _ref.read(workoutServiceProvider);
      for (final set in removing) {
        await service.deleteSet(
          exercise.id,
          set.id,
          workoutId: workout.id,
        );
      }
      _ref.invalidate(activeWorkoutProvider);
      return VoiceLines.setsRemoved(
        english,
        removing.length,
        exercise.exerciseName,
      );
    } catch (_) {
      return add
          ? VoiceLines.couldNotLog(english)
          : VoiceLines.couldNotDelete(english);
    }
  }

  Future<void> _insertSets(
    Workout workout,
    WorkoutExercise exercise,
    int count,
  ) async {
    final service = _ref.read(workoutServiceProvider);
    final sorted = [...exercise.sets]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    final history = await service.getPreviousSetsForExercise(
      exercise.exerciseId,
      excludeWorkoutId: workout.id,
    );
    final catalog = await _catalog();
    final isCardio = ExerciseLoggingResolver.isCardioExercise(
      exerciseId: exercise.exerciseId,
      exerciseName: exercise.exerciseName,
      catalog: catalog,
      sets: sorted,
    );
    final isLoadedDistance = ExerciseLoad.isLoadedDistance(
      exercise.exerciseId,
      catalog,
      exerciseName: exercise.exerciseName,
    );
    WorkoutSet? last = sorted.isEmpty ? null : sorted.last;
    for (var i = 0; i < count; i++) {
      final setNumber = sorted.length + i + 1;
      final prevSet = last ??
          (history == null
              ? null
              : service.previousSetForNumber(history, setNumber));
      final created = WorkoutSet(
        id: '',
        setNumber: setNumber,
        weight: isCardio ? null : prevSet?.weight,
        reps: isCardio || isLoadedDistance ? 0 : (prevSet?.reps ?? 10),
        durationSeconds: isCardio ? prevSet?.durationSeconds : null,
        distanceMeters:
            isCardio || isLoadedDistance ? prevSet?.distanceMeters : null,
        inclinePercent: isCardio ? prevSet?.inclinePercent : null,
        steps: isCardio ? prevSet?.steps : null,
        loggingType: isCardio
            ? ExerciseLoggingType.cardio
            : ExerciseLoggingType.strength,
      );
      await service.logSet(
        exercise.id,
        created,
        workoutId: workout.id,
      );
      last = created;
    }
  }

  Future<VoiceProposal> _proposeAdd(bool english, String query) async {
    final workout = await _activeWorkout();
    if (workout == null) return VoiceProposal(VoiceLines.noWorkout(english));

    final catalog = await _catalog();
    final match = VoiceExerciseMatch.best(catalog, query);
    if (match == null) {
      return VoiceProposal(VoiceLines.noExerciseMatch(english));
    }
    final already = workout.exercises.any(
      (exercise) => exercise.exerciseId == match.exercise.id,
    );
    if (already) {
      return VoiceProposal(
        english
            ? '${match.spokenName} is already in this workout.'
            : '${match.spokenName} ya está en este entrenamiento.',
      );
    }
    return VoiceProposal(
      VoiceLines.confirmAdd(english, match.spokenName),
      pending: VoicePendingAdd(
        exercise: match.exercise,
        spokenName: match.spokenName,
      ),
    );
  }

  Future<String> setRest({required bool english, required int seconds}) async {
    final workout = await _activeWorkout();
    if (workout == null) return VoiceLines.noWorkout(english);
    await RestPreferences.setDefaultRestSeconds(seconds);
    _ref.read(activeWorkoutRestRequestProvider.notifier).state = (
      seconds,
      DateTime.now().microsecondsSinceEpoch,
    );
    return VoiceLines.restUpdated(english, seconds);
  }

  Future<String> logFocusedSet({
    required bool english,
    required double weight,
    required int reps,
    required String? unit,
  }) async {
    final workout = await _activeWorkout();
    if (workout == null) return VoiceLines.noWorkout(english);
    final focusId = _ref.read(activeWorkoutFocusProvider);
    WorkoutExercise? exercise;
    if (focusId != null) {
      for (final item in workout.exercises) {
        if (item.id == focusId) {
          exercise = item;
          break;
        }
      }
    }
    if (exercise == null) return VoiceLines.needOpenExercise(english);

    final profileUnit = _ref.read(profileProvider).valueOrNull?.unitSystem ?? 'kg';
    final spokenUnit = unit ?? profileUnit;
    final kg = GymWeight.displayToSnappedKg(weight, spokenUnit);
    WorkoutSet? existing;
    for (final set in exercise.sets) {
      if (!set.completed && !set.isCardio) {
        existing = set;
        break;
      }
    }
    final set = WorkoutSet(
      id: existing?.id ?? '',
      setNumber: existing?.setNumber ??
          (exercise.sets.isEmpty ? 1 : exercise.sets.last.setNumber + 1),
      weight: kg,
      reps: reps,
      completed: true,
      loggingType: existing?.loggingType ?? ExerciseLoggingType.strength,
    );
    try {
      await _ref.read(workoutServiceProvider).logSet(
            exercise.id,
            set,
            workoutId: workout.id,
          );
      _ref.invalidate(activeWorkoutProvider);
      _ref.read(activeWorkoutVoiceLogTickProvider.notifier).state++;
      final label = UnitConverter.formatGymMass(kg, spokenUnit);
      return VoiceLines.loggedSet(
        english,
        weight: label,
        reps: reps,
        exercise: exercise.exerciseName,
      );
    } catch (_) {
      return VoiceLines.couldNotLog(english);
    }
  }

  Future<String> _day(bool english) async {
    try {
      final summary = await _ref.read(dailyNutritionProvider.future);
      return VoiceLines.day(
        english: english,
        eaten: summary.caloriesEaten,
        protein: summary.eaten.proteinG.round(),
        remaining: summary.caloriesRemaining,
      );
    } catch (_) {
      return VoiceLines.dayUnavailable(english);
    }
  }

  Future<String> _workoutStatus(bool english) async {
    final workout = await _activeWorkout();
    if (workout == null || workout.exercises.isEmpty) {
      return VoiceLines.noWorkout(english);
    }
    final exercise = _openExercise(workout) ?? workout.exercises.first;
    final done = exercise.sets.where((set) => set.completed).length;
    return VoiceLines.workout(
      english: english,
      exercise: exercise.exerciseName,
      done: done,
      total: exercise.sets.length,
    );
  }

  Future<String> _record(bool english, String query) async {
    final records = await _ref.read(personalRecordsProvider.future);
    final strength = records.where((record) => !record.isCardio).toList();
    if (strength.isEmpty) return VoiceLines.noRecord(english);

    final needle = ExerciseTextSearch.normalize(query);
    PersonalRecord? best;
    var bestScore = 0;
    for (final record in strength) {
      final name = ExerciseTextSearch.normalize(record.exerciseName);
      var score = 0;
      if (needle.isEmpty) {
        score = 1;
      } else if (name.contains(needle) || needle.contains(name)) {
        score = 10;
      } else {
        for (final token in ExerciseTextSearch.tokenize(needle)) {
          if (ExerciseTextSearch.variantsFor(token).any(name.contains)) {
            score += 3;
          }
        }
      }
      if (score > bestScore) {
        best = record;
        bestScore = score;
      } else if (score == bestScore &&
          score > 0 &&
          best != null &&
          record.achievedAt.isAfter(best.achievedAt)) {
        best = record;
      }
    }
    if (best == null || best.weight == null || bestScore == 0) {
      return VoiceLines.noRecord(english);
    }
    final unit = _ref.read(profileProvider).valueOrNull?.unitSystem ?? 'kg';
    return VoiceLines.record(
      english: english,
      exercise: best.exerciseName,
      weight: UnitConverter.formatGymMass(best.weight, unit),
      reps: best.reps,
    );
  }

  Future<List<Exercise>> _catalog() async {
    final loaded = _ref.read(exercisesProvider).valueOrNull;
    if (loaded != null) return loaded;
    final future = await _ref.read(exercisesProvider.future);
    return future;
  }

  Future<Workout?> _activeWorkout() async {
    final loaded = _ref.read(activeWorkoutProvider).valueOrNull;
    if (loaded != null) return loaded;
    return _ref.read(activeWorkoutProvider.future);
  }

  WorkoutExercise? _openExercise(Workout workout) {
    for (final exercise in workout.exercises) {
      if (exercise.sets.any((set) => !set.completed && !set.isCardio)) {
        return exercise;
      }
    }
    for (final exercise in workout.exercises.reversed) {
      if (!exercise.sets.every((set) => set.isCardio)) return exercise;
    }
    return workout.exercises.isEmpty ? null : workout.exercises.last;
  }
}
