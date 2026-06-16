class AppConstants {
  static const appName = 'FitForge';
  static const wgerApiBase = 'https://wger.de/api/v2';
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
    'Hombros': 36,
    'Bíceps': 24,
    'Tríceps': 24,
    'Piernas': 72,
    'Glúteos': 48,
    'Abdominales': 24,
    'Antebrazos': 24,
    'Cardio': 12,
  };
}
