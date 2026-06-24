import 'exercise_catalog_source.dart';

class AppConstants {
  static const appName = 'FitForge';
  static const wgerApiBase = 'https://wger.de/api/v2';

  static const exerciseCatalogSource = ExerciseCatalogSource.bundled;

  /// Solo aplica al catálogo wger legacy.
  static const catalogRequireVisualMedia = true;
  static const defaultRestSeconds = 90;
  static const defaultSets = 3;
  static const defaultReps = 10;

  static const muscleGroups = [
    'Pecho',
    'Espalda',
    'Hombros',
    'Bíceps',
    'Tríceps',
    'Piernas',
    'Glúteos',
    'Abdominales',
    'Antebrazos',
    'Cardio',
  ];

  static const muscleRecoveryHours = <String, int>{
    'Pecho': 48,
    'Espalda': 48,
    'Hombros': 48,
    'Bíceps': 48,
    'Tríceps': 48,
    'Piernas': 48,
    'Glúteos': 48,
    'Abdominales': 48,
    'Antebrazos': 48,
    'Cardio': 48,
  };
}
