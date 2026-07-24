enum ExerciseLoggingType {
  strength,
  cardio;

  static ExerciseLoggingType fromJson(String? value) {
    if (value == 'cardio') return ExerciseLoggingType.cardio;
    return ExerciseLoggingType.strength;
  }

  String toJson() => name;
}

/// Cómo registrar carga en series de fuerza (catálogo FitForge).
enum ExerciseLoadMode {
  singleLoad,
  dualLoad,
  machineStack,
  bodyweight,
  assistedBodyweight,
  loadedDistance,
  cardioMachine,
  cardioOutdoor;

  static ExerciseLoadMode fromJson(String? value) {
    switch (value) {
      case 'dual_load':
        return ExerciseLoadMode.dualLoad;
      case 'machine_stack':
        return ExerciseLoadMode.machineStack;
      case 'bodyweight':
        return ExerciseLoadMode.bodyweight;
      case 'assisted_bodyweight':
        return ExerciseLoadMode.assistedBodyweight;
      case 'loaded_distance':
        return ExerciseLoadMode.loadedDistance;
      case 'cardio_machine':
        return ExerciseLoadMode.cardioMachine;
      case 'cardio_outdoor':
        return ExerciseLoadMode.cardioOutdoor;
      default:
        return ExerciseLoadMode.singleLoad;
    }
  }

  String toJson() => switch (this) {
        ExerciseLoadMode.dualLoad => 'dual_load',
        ExerciseLoadMode.machineStack => 'machine_stack',
        ExerciseLoadMode.bodyweight => 'bodyweight',
        ExerciseLoadMode.assistedBodyweight => 'assisted_bodyweight',
        ExerciseLoadMode.loadedDistance => 'loaded_distance',
        ExerciseLoadMode.cardioMachine => 'cardio_machine',
        ExerciseLoadMode.cardioOutdoor => 'cardio_outdoor',
        ExerciseLoadMode.singleLoad => 'single_load',
      };

  bool get weightOptional =>
      this == ExerciseLoadMode.bodyweight ||
      this == ExerciseLoadMode.assistedBodyweight ||
      this == ExerciseLoadMode.cardioMachine ||
      this == ExerciseLoadMode.cardioOutdoor;
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
    'remo en polea',
    'remo en la polea',
    'remo sentado',
    'remo inclinado',
    'remo con barra',
    'remo con mancuerna',
    'remo unilateral',
    'remo a una mano',
    'remo al pecho',
    'remo en banco',
    'row with',
    'seated row',
    'bent over row',
    'barbell row',
    'dumbbell row',
    'cable row',
    't-bar row',
    't bar row',
    'landmine row',
    'one arm row',
    'one-arm row',
    'single arm row',
    'chest supported row',
    'deadlift',
    'peso muerto',
  ];

  static const _strengthRowPatterns = [
    'remo con',
    'remo en polea',
    'remo en la polea',
    'remo en polea baja',
    'remo en polea alta',
    'remo sentado',
    'remo inclinado',
    'remo con barra',
    'remo con mancuerna',
    'remo con mancuernas',
    'remo unilateral',
    'remo a un brazo',
    'remo a una mano',
    'remo al pecho',
    'remo en banco',
    'remo pendlay',
    'remo invertido',
    'remo en t',
    'remo en plancha',
    'remo planche',
    'row with',
    'seated row',
    'bent over row',
    'barbell row',
    'dumbbell row',
    'cable row',
    'inverted row',
    'australian pull',
    't-bar row',
    't bar row',
    'landmine row',
    'one arm row',
    'one-arm row',
    'single arm row',
    'chest supported row',
    'face pull',
    'low row',
    'high row',
  ];

  static const _strengthPullPatterns = [
    'dominada',
    'pull-up',
    'pull up',
    'pullup',
    'chin-up',
    'chin up',
    'chinup',
    'muscle-up',
    'muscle up',
    'jalon al pecho',
    'lat pulldown',
    'lat pull-down',
    'pull-down',
    'pulldown',
  ];

  static const _strengthPushPatterns = [
    'flexion',
    'flexiones',
    'push-up',
    'push up',
    'pushup',
    'lagartija',
    'fondos en paralelas',
    'fondos en barras',
    'parallel bar dip',
    'bench dip',
  ];

  static const _cardioRowingMachinePatterns = [
    'maquina de remo',
    'rowing machine',
    'concept2',
    'concept 2',
    'ergometro',
    'row erg',
    'ski erg',
    'remo erg',
    'air rower',
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

    if (isClearlyStrength(name)) return false;

    if (_pureCardioNames.contains(name)) return true;

    if (_isCardioRowingName(name)) return true;

    final hasStrengthModifier =
        _strengthModifiers.any((modifier) => name.contains(modifier));

    for (final keyword in _keywords) {
      if (keyword == 'remo' || keyword == 'rowing' || keyword == 'rower') {
        continue;
      }
      if (name.contains(keyword)) {
        if (hasStrengthModifier) continue;
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

  /// Fuerza evidente: anula categoría Cardio de wger y series mal etiquetadas.
  static bool isClearlyStrength(String exerciseName) {
    if (exerciseName.trim().isEmpty) return false;
    final name = normalize(exerciseName);
    if (_isStrengthRow(name)) return true;
    if (_strengthPullPatterns.any(name.contains)) return true;
    if (_strengthPushPatterns.any(name.contains)) return true;
    if (_strengthModifiers.any(name.contains)) return true;
    return false;
  }

  static bool _isCardioRowingName(String name) {
    if (name == 'remo' || name == 'rowing' || name == 'rower') return true;
    return _cardioRowingMachinePatterns.any(name.contains);
  }

  static bool _isStrengthRow(String name) {
    if (name.contains('remo') && !_isCardioRowingName(name)) return true;
    return _strengthRowPatterns.any(name.contains);
  }

  /// Remo de fuerza (polea, barra, etc.), no ergómetro/máquina de cardio.
  static bool isStrengthRow(String exerciseName) {
    return _isStrengthRow(normalize(exerciseName));
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
      if (CardioNameMatcher.isClearlyStrength(exerciseName)) {
        return CardioPreset.treadmill;
      }
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
  strengthMaxWeight,
  cardioDistance,
  cardioDuration,
  cardioSteps,
  cardioIncline,
  cardioDifficulty;

  static PersonalRecordType fromJson(String? value) {
    switch (value) {
      case 'strength_max_weight':
        return PersonalRecordType.strengthMaxWeight;
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
      case PersonalRecordType.strengthMaxWeight:
        return 'strength_max_weight';
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
