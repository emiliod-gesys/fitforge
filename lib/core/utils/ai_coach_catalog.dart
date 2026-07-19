import '../../models/exercise.dart';
import '../constants/app_constants.dart';
import 'exercise_picker_merge.dart';
import 'muscle_inference.dart';

/// Ensambla el catálogo que usa el AI Coach (embebido + cloud filtrado por músculo).
abstract final class AiCoachCatalog {
  static const maxCloudExercises = 240;
  static const cloudPageSize = 80;

  static List<String> musclesToQuery(List<String> targetMuscles) {
    if (targetMuscles.isNotEmpty) return targetMuscles;
    return AppConstants.muscleGroups.where((group) => group != 'Cardio').toList();
  }

  static List<Exercise> mergeBundledAndCloud({
    required List<Exercise> bundled,
    required List<Exercise> cloud,
    List<String> targetMuscles = const [],
  }) {
    final muscles = musclesToQuery(targetMuscles);
    final filteredCloud = cloud.where((exercise) {
      return muscles.any(
        (muscle) => MuscleInference.matchesMuscleGroup(
          exercise: exercise,
          muscleGroup: muscle,
        ),
      );
    }).toList();

    return mergeBundledAndCloudExercises(
      bundled: bundled,
      cloud: filteredCloud,
    );
  }
}
