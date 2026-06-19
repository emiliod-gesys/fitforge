enum ExerciseLoggingType {
  strength,
  cardio;

  static ExerciseLoggingType fromJson(String? value) {
    if (value == 'cardio') return ExerciseLoggingType.cardio;
    return ExerciseLoggingType.strength;
  }

  String toJson() => name;
}

/// Detección de ejercicios cardio por nombre (p. ej. wger «Caminando» en categoría Piernas).
abstract final class CardioNameMatcher {
  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

  static const _keywords = [
    'cardio',
    'cinta',
    'treadmill',
    'caminadora',
    'eliptica',
    'elliptical',
    'bicicleta',
    'bici',
    'bike',
    'cycling',
    'spinning',
    'remo',
    'rowing',
    'rower',
    'stair',
    'escalera',
    'stepper',
    'correr',
    'running',
    'caminar',
    'caminando',
    'caminata',
    'walking',
    'corriendo',
    'jogging',
    'jog',
    'trote',
    'senderismo',
    'hiking',
    'nadar',
    'natacion',
    'swimming',
    'ski erg',
    'assault',
  ];

  static const _tokenStems = [
    'camin',
    'corri',
    'walk',
    'run',
    'jog',
    'nadar',
    'nata',
    'swim',
  ];

  static const _strengthModifiers = [
    'zancada',
    'lunge',
    'lunges',
    'sentadilla',
    'squat',
    'press',
    'curl',
    'extension',
    'flexion',
    'elevacion',
    'raise',
    'remo con',
    'row with',
    'deadlift',
    'peso muerto',
  ];

  static const _pureCardioNames = {
    'caminando',
    'caminar',
    'caminate',
    'walking',
    'walk',
    'corriendo',
    'correr',
    'running',
    'run',
    'jogging',
    'jog',
    'trote',
    'senderismo',
    'hiking',
    'nadar',
    'natacion',
    'swimming',
    'swim',
  };

  static bool matches(String exerciseName) {
    if (exerciseName.trim().isEmpty) return false;
    final name = CardioNameMatcher.normalize(exerciseName);

    if (_pureCardioNames.contains(name)) return true;

    final hasStrengthModifier =
        _strengthModifiers.any((modifier) => name.contains(modifier));

    for (final keyword in _keywords) {
      if (name.contains(keyword)) {
        if (hasStrengthModifier && !_isMachineKeyword(keyword)) continue;
        return true;
      }
    }

    if (hasStrengthModifier) return false;

    for (final token in name.split(RegExp(r'[\s\-_/]+'))) {
      if (token.length < 3) continue;
      if (_pureCardioNames.contains(token)) return true;
      for (final stem in _tokenStems) {
        if (token.startsWith(stem)) return true;
      }
    }
    return false;
  }

  static bool _isMachineKeyword(String keyword) {
    const machines = {
      'cardio',
      'cinta',
      'treadmill',
      'caminadora',
      'eliptica',
      'elliptical',
      'bicicleta',
      'bici',
      'bike',
      'cycling',
      'spinning',
      'remo',
      'rowing',
      'rower',
      'stair',
      'escalera',
      'stepper',
      'ski erg',
      'assault',
    };
    return machines.contains(keyword);
  }

  static bool matchesTreadmill(String exerciseName) {
    if (!matches(exerciseName)) return false;
    final name = normalize(exerciseName);
    const treadmillKeywords = [
      'cinta',
      'treadmill',
      'caminadora',
      'correr',
      'running',
      'caminar',
      'caminando',
      'caminata',
      'walking',
      'corriendo',
      'jogging',
      'jog',
      'trote',
      'senderismo',
      'hiking',
    ];
    for (final keyword in treadmillKeywords) {
      if (name.contains(keyword)) return true;
    }
    for (final token in name.split(RegExp(r'[\s\-_/]+'))) {
      if (token.length < 3) continue;
      for (final stem in ['camin', 'corri', 'walk', 'run', 'jog']) {
        if (token.startsWith(stem)) return true;
      }
    }
    return false;
  }
}

enum CardioMetric {
  duration,
  distance,
  incline,
  difficulty,
  steps;

  static CardioMetric? fromJson(String? value) {
    if (value == null) return null;
    for (final metric in CardioMetric.values) {
      if (metric.name == value) return metric;
    }
    return null;
  }

  String toJson() => name;
}

enum CardioPreset {
  treadmill,
  elliptical,
  bike,
  stairClimber,
  rowing,
  custom;

  static CardioPreset inferFromExerciseName(String exerciseName) {
    final name = CardioNameMatcher.normalize(exerciseName);

    bool containsAny(List<String> terms) {
      for (final term in terms) {
        if (name.contains(term)) return true;
      }
      return false;
    }

    if (CardioNameMatcher.matchesTreadmill(exerciseName)) {
      return CardioPreset.treadmill;
    }

    if (containsAny(['eliptica', 'elliptical'])) {
      return CardioPreset.elliptical;
    }

    if (containsAny([
      'bicicleta',
      'bici',
      'bike',
      'cycling',
      'spinning',
      'cicloergometro',
      'assault bike',
    ])) {
      return CardioPreset.bike;
    }

    if (containsAny(['stair', 'escalera', 'stepper'])) {
      return CardioPreset.stairClimber;
    }

    if (containsAny(['remo', 'rowing', 'rower', 'ski erg'])) {
      return CardioPreset.rowing;
    }

    if (containsAny(['nadar', 'natacion', 'swimming', 'swim'])) {
      return CardioPreset.custom;
    }

    return CardioPreset.treadmill;
  }
}

class CardioLoggingConfig {
  final Set<CardioMetric> enabledMetrics;

  const CardioLoggingConfig(this.enabledMetrics);

  factory CardioLoggingConfig.fromPreset(CardioPreset preset) {
    switch (preset) {
      case CardioPreset.treadmill:
        return const CardioLoggingConfig({
          CardioMetric.duration,
          CardioMetric.distance,
          CardioMetric.incline,
        });
      case CardioPreset.elliptical:
      case CardioPreset.bike:
        return const CardioLoggingConfig({
          CardioMetric.duration,
          CardioMetric.distance,
          CardioMetric.difficulty,
        });
      case CardioPreset.stairClimber:
        return const CardioLoggingConfig({
          CardioMetric.duration,
          CardioMetric.steps,
        });
      case CardioPreset.rowing:
        return const CardioLoggingConfig({
          CardioMetric.duration,
          CardioMetric.distance,
        });
      case CardioPreset.custom:
        return const CardioLoggingConfig({CardioMetric.duration});
    }
  }

  factory CardioLoggingConfig.fromJson(List<dynamic>? metrics) {
    if (metrics == null || metrics.isEmpty) {
      return CardioLoggingConfig.fromPreset(CardioPreset.treadmill);
    }
    final parsed = metrics
        .map((m) => CardioMetric.fromJson(m as String?))
        .whereType<CardioMetric>()
        .toSet();
    if (parsed.isEmpty) return CardioLoggingConfig.fromPreset(CardioPreset.treadmill);
    return CardioLoggingConfig(parsed);
  }

  List<String> toJsonList() => enabledMetrics.map((m) => m.name).toList()..sort();

  bool get tracksDuration => enabledMetrics.contains(CardioMetric.duration);
  bool get tracksDistance => enabledMetrics.contains(CardioMetric.distance);
  bool get tracksIncline => enabledMetrics.contains(CardioMetric.incline);
  bool get tracksDifficulty => enabledMetrics.contains(CardioMetric.difficulty);
  bool get tracksSteps => enabledMetrics.contains(CardioMetric.steps);

  bool isSetComplete({
    int? durationSeconds,
    double? distanceMeters,
    double? inclinePercent,
    int? steps,
  }) {
    var hasValue = false;
    if (tracksDuration && durationSeconds != null && durationSeconds > 0) {
      hasValue = true;
    }
    if (tracksDistance && distanceMeters != null && distanceMeters > 0) {
      hasValue = true;
    }
    if (tracksIncline && inclinePercent != null && inclinePercent > 0) {
      hasValue = true;
    }
    if (tracksDifficulty && inclinePercent != null && inclinePercent > 0) {
      hasValue = true;
    }
    if (tracksSteps && steps != null && steps > 0) {
      hasValue = true;
    }
    return hasValue;
  }
}

enum PersonalRecordType {
  strength,
  cardioDistance,
  cardioDuration,
  cardioSteps,
  cardioIncline,
  cardioDifficulty;

  static PersonalRecordType fromJson(String? value) {
    switch (value) {
      case 'cardio_distance':
        return PersonalRecordType.cardioDistance;
      case 'cardio_duration':
        return PersonalRecordType.cardioDuration;
      case 'cardio_steps':
        return PersonalRecordType.cardioSteps;
      case 'cardio_incline':
        return PersonalRecordType.cardioIncline;
      case 'cardio_difficulty':
        return PersonalRecordType.cardioDifficulty;
      default:
        return PersonalRecordType.strength;
    }
  }

  String toJson() {
    switch (this) {
      case PersonalRecordType.strength:
        return 'strength';
      case PersonalRecordType.cardioDistance:
        return 'cardio_distance';
      case PersonalRecordType.cardioDuration:
        return 'cardio_duration';
      case PersonalRecordType.cardioSteps:
        return 'cardio_steps';
      case PersonalRecordType.cardioIncline:
        return 'cardio_incline';
      case PersonalRecordType.cardioDifficulty:
        return 'cardio_difficulty';
    }
  }
}
