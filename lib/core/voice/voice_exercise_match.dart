import '../../models/exercise.dart';
import '../utils/exercise_text_search.dart';

class RankedExercise {
  const RankedExercise(this.exercise, this.score, this.spokenName);
  final Exercise exercise;
  final int score;
  final String spokenName;
}

/// Elige un ejercicio del catálogo a partir de una frase hablada.
abstract final class VoiceExerciseMatch {
  static RankedExercise? best(List<Exercise> catalog, String query) {
    final ranked = rank(catalog, query);
    if (ranked.isEmpty) return null;
    return ranked.first;
  }

  /// El ejercicio que mejor cumple músculo, equipo y lo demás que se dijo.
  static RankedExercise? bestMatch(
    List<Exercise> catalog,
    String query, {
    bool Function(Exercise exercise)? inMuscle,
  }) {
    final pool = specificMatches(catalog, query, inMuscle: inMuscle);
    if (pool.isEmpty) return null;
    final ranked = rank(pool, query);
    final candidates = ranked.isEmpty
        ? [
            for (final exercise in pool)
              RankedExercise(exercise, 1, exercise.name),
          ]
        : ranked;
    candidates.sort((a, b) {
      final byFit = _fitScore(b, query).compareTo(_fitScore(a, query));
      if (byFit != 0) return byFit;
      final byWords = _wordCount(a.exercise.name).compareTo(_wordCount(b.exercise.name));
      if (byWords != 0) return byWords;
      return a.exercise.name.compareTo(b.exercise.name);
    });
    return candidates.first;
  }

  /// Ejercicios que cumplen músculo y equipo dichos.
  static List<Exercise> specificMatches(
    List<Exercise> catalog,
    String query, {
    bool Function(Exercise exercise)? inMuscle,
  }) {
    final normalized = ExerciseTextSearch.normalize(query);
    if (normalized.isEmpty) return const [];
    final pool = catalog.where((exercise) {
      if (!matchesRequestedGear(exercise, normalized)) return false;
      if (inMuscle != null && !inMuscle(exercise)) return false;
      return true;
    }).toList();
    if (pool.isEmpty) return const [];
    final strict = pool
        .where((exercise) => ExerciseTextSearch.matchesExercise(exercise, normalized))
        .toList();
    final chosen = strict.isNotEmpty ? strict : pool;
    chosen.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return chosen;
  }

  /// Búsquedas para el catálogo cloud: equipo y músculo en inglés, y la frase dicha.
  static List<String> cloudQueries(String query, {String? muscleGroup}) {
    final normalized = ExerciseTextSearch.normalize(query);
    final gear = _englishGear(normalized);
    final muscle = _englishMuscle(muscleGroup);
    final queries = <String>[];
    void add(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.length >= 2 && !queries.contains(trimmed)) queries.add(trimmed);
    }

    if (gear != null && muscle != null) add('$gear $muscle');
    add(gear);
    add(normalized);
    return queries;
  }

  static bool matchesRequestedGear(Exercise exercise, String query) {
    final normalized = ExerciseTextSearch.normalize(query);
    final words = normalized.split(' ');
    bool word(String value) => words.contains(value);
    final wantsDumbbell = normalized.contains('mancuerna') || normalized.contains('dumbbell');
    final wantsKettle = normalized.contains('kettlebell') || normalized.contains('pesa rusa');
    final wantsCable = word('polea') || word('poleas') || word('cable') || word('cables');
    final wantsMachine = word('maquina') ||
        word('maquinas') ||
        word('machine') ||
        word('machines') ||
        word('palanca') ||
        word('lever');
    final wantsBand = word('banda') ||
        word('bandas') ||
        word('band') ||
        word('bands') ||
        word('liga') ||
        word('ligas');
    final wantsBarbell = word('barra') ||
        word('barras') ||
        word('barbell') ||
        word('barbells') ||
        word('smith');
    if (!wantsDumbbell &&
        !wantsKettle &&
        !wantsCable &&
        !wantsMachine &&
        !wantsBand &&
        !wantsBarbell) {
      return true;
    }
    final blob = ExerciseTextSearch.normalize(
      [
        exercise.name,
        ...exercise.aliases,
        ...exercise.equipment,
      ].join(' '),
    );
    if (wantsDumbbell && !_blobHas(blob, const ['dumbbell', 'mancuerna'])) return false;
    if (wantsKettle && !_blobHas(blob, const ['kettle', 'pesa rusa'])) return false;
    if (wantsCable && !_blobHas(blob, const ['cable', 'polea'])) return false;
    if (wantsMachine && !_blobHas(blob, const ['machine', 'maquina', 'lever', 'palanca'])) {
      return false;
    }
    if (wantsBand && !_blobHas(blob, const ['band', 'banda', 'liga'])) return false;
    if (wantsBarbell && !_blobHas(blob, const ['barbell', 'barra', 'smith'])) return false;
    return true;
  }

  static bool _blobHas(String blob, List<String> needles) {
    return needles.any(blob.contains);
  }

  static String? _englishGear(String normalized) {
    final words = normalized.split(' ');
    bool word(String value) => words.contains(value);
    if (normalized.contains('mancuerna') || normalized.contains('dumbbell')) return 'dumbbell';
    if (normalized.contains('kettlebell') || normalized.contains('pesa rusa')) return 'kettlebell';
    if (word('polea') || word('poleas') || word('cable') || word('cables')) return 'cable';
    if (word('maquina') ||
        word('maquinas') ||
        word('machine') ||
        word('machines') ||
        word('palanca') ||
        word('lever')) {
      return 'machine';
    }
    if (word('banda') || word('bandas') || word('band') || word('bands') || word('liga') || word('ligas')) {
      return 'band';
    }
    if (word('barra') || word('barras') || word('barbell') || word('barbells') || word('smith')) {
      return 'barbell';
    }
    return null;
  }

  static String? _englishMuscle(String? muscleGroup) {
    switch (muscleGroup) {
      case 'Pecho':
        return 'chest';
      case 'Espalda':
        return 'back';
      case 'Hombros':
        return 'shoulder';
      case 'Bíceps':
        return 'biceps';
      case 'Tríceps':
        return 'triceps';
      case 'Piernas':
        return 'leg';
      case 'Glúteos':
        return 'glute';
      case 'Abdominales':
        return 'abdominal';
      case 'Antebrazos':
        return 'forearm';
      case 'Cardio':
        return 'cardio';
      default:
        return null;
    }
  }

  static List<RankedExercise> rank(List<Exercise> catalog, String query) {
    final normalized = ExerciseTextSearch.normalize(query);
    if (normalized.isEmpty) return const [];

    final wantsUpper = normalized.contains('superior') ||
        normalized.contains('alto') ||
        normalized.contains('inclin') ||
        normalized.contains('upper');
    final wantsLower = normalized.contains('inferior') ||
        normalized.contains('bajo') ||
        normalized.contains('declin') ||
        normalized.contains('lower');
    final wantsDumbbell = normalized.contains('mancuerna') ||
        normalized.contains('dumbbell');
    final wantsBarbell =
        normalized.contains('barra') || normalized.contains('barbell');
    final tokens = ExerciseTextSearch.tokenize(normalized)
        .where((token) => !_hintWords.contains(token))
        .toList();

    final ranked = <RankedExercise>[];
    for (final exercise in catalog) {
      final haystack = ExerciseTextSearch.expandPhrases(
        ExerciseTextSearch.normalize(
          [
            exercise.name,
            ...exercise.aliases,
            ...exercise.muscles,
            ...exercise.equipment,
          ].join(' '),
        ),
      );
      var score = 0;
      for (final token in tokens) {
        final variants = ExerciseTextSearch.variantsFor(token);
        if (variants.any(haystack.contains)) score += 3;
      }
      if (wantsUpper &&
          (haystack.contains('inclin') || haystack.contains('upper'))) {
        score += 6;
      }
      if (wantsLower &&
          (haystack.contains('declin') || haystack.contains('lower'))) {
        score += 6;
      }
      final dumbbell = exercise.equipment.any(_isDumbbell);
      final barbell = exercise.equipment.any(_isBarbell);
      if (wantsDumbbell && dumbbell) score += 4;
      if (wantsDumbbell && !dumbbell) score -= 4;
      if (wantsBarbell && barbell) score += 4;
      if (wantsBarbell && !barbell && dumbbell) score -= 2;
      if (score <= 0) continue;
      ranked.add(
        RankedExercise(exercise, score, _spokenName(exercise, tokens)),
      );
    }

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.exercise.name.compareTo(b.exercise.name);
    });
    return ranked;
  }

  static String _spokenName(Exercise exercise, List<String> tokens) {
    String best = exercise.name;
    var bestScore = _overlap(exercise.name, tokens);
    var bestLiteral = _literal(exercise.name, tokens);
    for (final alias in exercise.aliases) {
      final score = _overlap(alias, tokens);
      final literal = _literal(alias, tokens);
      final betterScore = score > bestScore;
      final sameScoreButSpoken = score == bestScore && literal && !bestLiteral;
      if (betterScore || sameScoreButSpoken) {
        best = alias;
        bestScore = score;
        bestLiteral = literal;
      }
    }
    return best;
  }

  static bool _literal(String value, List<String> tokens) {
    final haystack = ExerciseTextSearch.normalize(value);
    return tokens.any(haystack.contains);
  }

  static int _overlap(String value, List<String> tokens) {
    final haystack = ExerciseTextSearch.normalize(value);
    var score = 0;
    for (final token in tokens) {
      if (ExerciseTextSearch.variantsFor(token).any(haystack.contains)) {
        score++;
      }
    }
    return score;
  }

  static int _fitScore(RankedExercise ranked, String query) {
    return ranked.score - _extraModifierPenalty(ranked.exercise, query);
  }

  /// Resta puntos por variaciones (martillo, inclinado, concentrado) que no se pidieron.
  static int _extraModifierPenalty(Exercise exercise, String query) {
    final name = ExerciseTextSearch.normalize(
      [exercise.name, ...exercise.aliases].join(' '),
    );
    final normalizedQuery = ExerciseTextSearch.normalize(query);
    var penalty = 0;
    for (final group in _modifierGroups) {
      final inName = group.any(name.contains);
      if (inName && !_modifierRequested(group, normalizedQuery)) penalty += 5;
    }
    return penalty;
  }

  static bool _modifierRequested(List<String> group, String normalizedQuery) {
    final named = group.any((word) {
      return normalizedQuery.contains(word) ||
          ExerciseTextSearch.variantsFor(word).any(normalizedQuery.contains);
    });
    if (named) return true;
    final incline = group.any((word) => word.startsWith('inclin'));
    final decline = group.any((word) => word.startsWith('declin'));
    if (incline &&
        (normalizedQuery.contains('superior') ||
            normalizedQuery.contains('upper') ||
            normalizedQuery.contains('alto'))) {
      return true;
    }
    if (decline &&
        (normalizedQuery.contains('inferior') ||
            normalizedQuery.contains('lower') ||
            normalizedQuery.contains('bajo'))) {
      return true;
    }
    return false;
  }

  static int _wordCount(String name) {
    final normalized = ExerciseTextSearch.normalize(name);
    if (normalized.isEmpty) return 0;
    return normalized.split(' ').length;
  }

  static const _modifierGroups = [
    ['hammer', 'martillo'],
    ['inclin', 'inclinado', 'incline'],
    ['declin', 'declinado', 'decline'],
    ['concentration', 'concentrado'],
    ['preacher', 'predicador'],
    ['spider'],
    ['reverse', 'inverso', 'invertido'],
    ['seated', 'sentado'],
    ['alternat', 'alterno', 'alternado'],
    ['unilateral'],
    ['lying', 'acostado'],
    ['overhead'],
    ['zottman'],
    ['kneeling', 'arrodillado'],
  ];

  static bool _isDumbbell(String equipment) {
    final name = ExerciseTextSearch.normalize(equipment);
    return name.contains('dumbbell') || name.contains('mancuerna');
  }

  static bool _isBarbell(String equipment) {
    final name = ExerciseTextSearch.normalize(equipment);
    return name.contains('barbell') || name.contains('barra');
  }

  static const _hintWords = {
    'superior',
    'alto',
    'inferior',
    'bajo',
    'upper',
    'lower',
    'con',
    'with',
  };
}
