import '../../models/workout.dart';

/// Navegación entre ejercicios por id (no por identidad de objeto).
///
/// Durante el entreno activo la UI usa un workout fusionado con sets optimistas;
/// comparar instancias con [List.indexOf] falla y deja el botón "Siguiente" atascado.
abstract final class WorkoutExerciseNavigation {
  static int indexInWorkout(List<WorkoutExercise> exercises, String exerciseId) {
    return exercises.indexWhere((e) => e.id == exerciseId);
  }

  static int visibleIndex(List<WorkoutExercise> visible, String exerciseId) {
    return visible.indexWhere((e) => e.id == exerciseId);
  }

  static bool hasPrevious(List<WorkoutExercise> visible, String exerciseId) {
    final vi = visibleIndex(visible, exerciseId);
    return vi > 0;
  }

  static bool hasNext(List<WorkoutExercise> visible, String exerciseId) {
    final vi = visibleIndex(visible, exerciseId);
    return vi >= 0 && vi < visible.length - 1;
  }

  static int? resolvePreviousWorkoutIndex({
    required List<WorkoutExercise> workoutExercises,
    required List<WorkoutExercise> visibleExercises,
    required String currentExerciseId,
  }) {
    final vi = visibleIndex(visibleExercises, currentExerciseId);
    if (vi <= 0) return null;
    final previousId = visibleExercises[vi - 1].id;
    final index = indexInWorkout(workoutExercises, previousId);
    return index >= 0 ? index : null;
  }

  static int? resolveNextWorkoutIndex({
    required List<WorkoutExercise> workoutExercises,
    required List<WorkoutExercise> visibleExercises,
    required String currentExerciseId,
  }) {
    final vi = visibleIndex(visibleExercises, currentExerciseId);
    if (vi < 0 || vi >= visibleExercises.length - 1) return null;
    final nextId = visibleExercises[vi + 1].id;
    final index = indexInWorkout(workoutExercises, nextId);
    return index >= 0 ? index : null;
  }
}
