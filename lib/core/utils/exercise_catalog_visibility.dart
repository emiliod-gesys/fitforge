import '../../models/exercise.dart';
import '../constants/app_constants.dart';
import '../constants/exercise_catalog_source.dart';

/// Visibilidad de ejercicios en biblioteca y selectores (no afecta entrenos ya guardados).
abstract final class ExerciseCatalogVisibility {
  /// Foto wger o imagen local del usuario (no maniquí genérico).
  static bool hasIllustration(Exercise exercise) {
    final url = exercise.imageUrl;
    if (url == null || url.trim().isEmpty) return false;

    if (exercise.isUserCustom) {
      return !url.startsWith('http://') && !url.startsWith('https://');
    }

    return url.startsWith('http://') || url.startsWith('https://');
  }

  static bool isBrowsable(Exercise exercise) {
    if (exercise.isUserCustom) return true;
    if (!AppConstants.catalogRequireVisualMedia) return true;
    return hasIllustration(exercise);
  }

  static List<Exercise> filterBrowsable(List<Exercise> exercises) {
    if (AppConstants.exerciseCatalogSource == ExerciseCatalogSource.bundled) {
      return exercises;
    }
    if (!AppConstants.catalogRequireVisualMedia) return exercises;
    return exercises.where(isBrowsable).toList();
  }
}
