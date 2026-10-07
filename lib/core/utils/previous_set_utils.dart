import '../../models/exercise_logging.dart';
import '../../models/workout.dart';

abstract final class PreviousSetUtils {
  static List<WorkoutSet> sortedBySetNumber(List<WorkoutSet> sets) {
    final sorted = [...sets]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return sorted;
  }

  static int resolveSetCount({
    required int templateCount,
    List<WorkoutSet>? previous,
  }) {
    if (previous == null || previous.isEmpty) return templateCount;
    return sortedBySetNumber(previous).length;
  }

  /// La rutina manda solo si es más reciente que el último entreno registrado.
  /// Si el usuario ya cambió series, reps o pesos, el último entreno manda.
  static bool useLastPerformance({
    required DateTime? routineUpdatedAt,
    required DateTime? lastPerformedAt,
  }) {
    if (lastPerformedAt == null) return false;
    if (routineUpdatedAt == null) return true;
    return lastPerformedAt.isAfter(routineUpdatedAt);
  }

  /// Combina la plantilla (rutina) con el último entreno.
  ///
  /// Con [preserveTemplate], la cantidad de series y los pesos/reps de la
  /// rutina mandan. El historial solo rellena pesos que la rutina dejó vacíos.
  /// Sin [preserveTemplate], series, reps y pesos del último entreno mandan.
  static List<WorkoutSet> mergeTemplateWithHistory({
    required List<WorkoutSet> template,
    required List<WorkoutSet> previous,
    required bool isCardio,
    required bool isLoadedDistance,
    bool preserveTemplate = false,
  }) {
    final templates = sortedBySetNumber(template);
    final setCount = preserveTemplate && templates.isNotEmpty
        ? templates.length
        : resolveSetCount(templateCount: templates.length, previous: previous);

    return List.generate(setCount, (i) {
      final setNumber = i + 1;
      final planned = forSetNumber(templates, setNumber) ??
          (templates.isNotEmpty ? templates.last : null);
      final prev = forSetNumber(previous, setNumber);
      return WorkoutSet(
        id: '',
        setNumber: setNumber,
        weight: isCardio
            ? null
            : (preserveTemplate
                ? (planned?.weight ?? prev?.weight)
                : (prev?.weight ?? planned?.weight)),
        reps: isCardio || isLoadedDistance
            ? 0
            : (preserveTemplate
                ? ((planned?.reps ?? 0) > 0
                    ? planned!.reps
                    : ((prev?.reps ?? 0) > 0 ? prev!.reps : 10))
                : ((prev?.reps ?? 0) > 0 ? prev!.reps : (planned?.reps ?? 10))),
        durationSeconds: isCardio
            ? (preserveTemplate
                ? (planned?.durationSeconds ?? prev?.durationSeconds)
                : (prev?.durationSeconds ?? planned?.durationSeconds))
            : null,
        distanceMeters: isCardio || isLoadedDistance
            ? (preserveTemplate
                ? (planned?.distanceMeters ?? prev?.distanceMeters)
                : (prev?.distanceMeters ?? planned?.distanceMeters))
            : null,
        inclinePercent: isCardio
            ? (preserveTemplate
                ? (planned?.inclinePercent ?? prev?.inclinePercent)
                : (prev?.inclinePercent ?? planned?.inclinePercent))
            : null,
        steps: isCardio
            ? (preserveTemplate
                ? (planned?.steps ?? prev?.steps)
                : (prev?.steps ?? planned?.steps))
            : null,
        loggingType: isCardio
            ? ExerciseLoggingType.cardio
            : (preserveTemplate
                ? (planned?.loggingType ?? ExerciseLoggingType.strength)
                : (prev != null &&
                        prev.loggingType != ExerciseLoggingType.strength
                    ? prev.loggingType
                    : planned?.loggingType ?? ExerciseLoggingType.strength)),
      );
    });
  }

  static List<WorkoutSet> sortedMeaningfulSets(List<WorkoutSet> sets) {
    final completed = sets.where((s) => s.completed).toList();
    // Sin series completadas, solo cuentan las que tienen datos reales
    // (las series pre-rellenadas de plantilla llevan reps pero nada más).
    final source =
        completed.isNotEmpty ? completed : sets.where(hasLoggedData).toList();
    final meaningful = source
        .where(
            (s) => s.weight != null || s.reps > 0 || s.durationSeconds != null)
        .toList();
    meaningful.sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return meaningful;
  }

  static bool hasLoggedData(WorkoutSet s) =>
      (s.weight ?? 0) > 0 ||
      (s.durationSeconds ?? 0) > 0 ||
      (s.distanceMeters ?? 0) > 0 ||
      (s.steps ?? 0) > 0;

  static WorkoutSet? forSetNumber(List<WorkoutSet> previous, int setNumber) {
    if (previous.isEmpty || setNumber < 1) return null;

    for (final set in previous) {
      if (set.setNumber == setNumber) return set;
    }

    final sorted = [...previous]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    if (setNumber <= sorted.length) return sorted[setNumber - 1];
    return sorted.last;
  }
}
