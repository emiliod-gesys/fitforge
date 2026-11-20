import '../../models/exercise.dart';
import '../workout/smart_routine_catalog.dart';

/// Una descripción corta («hombro frontal con mancuernas») contra el banco.
class ExerciseSmartIntent {
  final List<ExerciseSmartFocus> focuses;
  final List<ExerciseSmartGear> gear;
  final List<String> leftover;

  const ExerciseSmartIntent({
    this.focuses = const [],
    this.gear = const [],
    this.leftover = const [],
  });

  static const empty = ExerciseSmartIntent();

  bool get isEmpty => focuses.isEmpty && gear.isEmpty && leftover.isEmpty;

  /// Consulta corta para el catálogo extendido (nombres en inglés).
  String get cloudQuery {
    final terms = <String>[
      ...gear.expand((item) => item.cloudTerms),
      ...focuses.expand((item) => item.cloudTerms),
      ...leftover,
    ];
    final unique = <String>[];
    for (final term in terms) {
      if (term.length < 2 || unique.contains(term)) continue;
      unique.add(term);
    }
    return unique.take(4).join(' ');
  }
}

class ExerciseSmartFocus {
  final String cloudTermsJoined;

  /// Músculo principal que hay que acertar. Vacío si [targetId] ya lo define.
  final List<String> primaryKeys;
  final String? targetId;

  /// Grupo padre. Solo abre la puerta si el movimiento también coincide.
  final List<String> familyKeys;
  final List<String> movementFamilies;

  /// Desempate: el nombre que describe el gesto pedido sube, no mete otro músculo.
  final List<String> nameNeedles;
  final bool broad;

  const ExerciseSmartFocus({
    required this.cloudTermsJoined,
    this.primaryKeys = const [],
    this.targetId,
    this.familyKeys = const [],
    this.movementFamilies = const [],
    this.nameNeedles = const [],
    this.broad = false,
  });

  List<String> get cloudTerms => cloudTermsJoined.split(' ');

  List<String> get resolvedPrimaryKeys {
    final target = _target;
    return [
      ...primaryKeys,
      if (target != null) ...target.primaryKeys,
    ];
  }

  List<String> get stapleIds => _target?.stapleIds ?? const [];

  SmartMuscleTarget? get _target {
    final id = targetId;
    if (id == null) return null;
    for (final target in SmartRoutineCatalog.targets) {
      if (target.id == id) return target;
    }
    return null;
  }
}

class ExerciseSmartGear {
  final List<String> needles;
  final String cloudTerm;

  const ExerciseSmartGear({
    required this.needles,
    required this.cloudTerm,
  });

  List<String> get cloudTerms => [cloudTerm];
}

/// Recomienda ejercicios del catálogo a partir de una frase en español o inglés.
abstract final class ExerciseSmartSearch {
  static const resultLimit = 20;

  static ExerciseSmartIntent interpret(String raw) {
    final query = normalize(raw);
    if (query.isEmpty) return ExerciseSmartIntent.empty;

    final focusHits = _hits(query, _focusPhrases);
    final gearHits = _hits(query, _gearPhrases);
    final consumed = <_Span>[...focusHits, ...gearHits];
    final leftover = _leftoverTokens(query, consumed);

    return ExerciseSmartIntent(
      focuses: focusHits.map((hit) => hit.value).toList(),
      gear: gearHits.map((hit) => hit.value).toList(),
      leftover: leftover,
    );
  }

  static List<Exercise> rank(
    Iterable<Exercise> exercises,
    ExerciseSmartIntent intent, {
    int limit = resultLimit,
  }) {
    if (intent.isEmpty) return const [];

    final scored = <({Exercise exercise, int score, String name})>[];
    for (final exercise in exercises) {
      final score = _score(exercise, intent);
      if (score <= 0) continue;
      scored.add((
        exercise: exercise,
        score: score,
        name: normalize(exercise.name),
      ));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      if (a.exercise.isBundled != b.exercise.isBundled) {
        return a.exercise.isBundled ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    final seen = <String>{};
    final out = <Exercise>[];
    for (final row in scored) {
      if (!seen.add(row.name)) continue;
      out.add(row.exercise);
      if (out.length >= limit) break;
    }
    return out;
  }

  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static int _score(Exercise exercise, ExerciseSmartIntent intent) {
    final name = normalize(
      [exercise.name, ...exercise.aliases].join(' '),
    );
    final muscles = normalize(exercise.muscles.join(' '));
    final primary = exercise.muscles.isEmpty
        ? ''
        : normalize(exercise.muscles.first);
    final equipment = normalize(exercise.equipment.join(' '));
    final category = normalize(exercise.category);

    var score = 0;

    if (intent.gear.isNotEmpty) {
      final gearHit = intent.gear.any(
        (gear) => gear.needles.any(
          (needle) => equipment.contains(needle) || name.contains(needle),
        ),
      );
      if (!gearHit) return 0;
      score += 50;
    }

    if (intent.focuses.isNotEmpty) {
      var best = 0;
      for (final focus in intent.focuses) {
        final focusScore = _focusScore(
          exercise: exercise,
          focus: focus,
          name: name,
          muscles: muscles,
          primary: primary,
          category: category,
        );
        if (focusScore > best) best = focusScore;
      }
      if (best == 0) return 0;
      score += best;
    } else if (intent.leftover.isNotEmpty) {
      final haystack = '$name $muscles $equipment $category';
      if (!intent.leftover.every(haystack.contains)) return 0;
      score += 30;
    }

    if (exercise.isBundled) score += 5;
    return score;
  }

  /// Más puntos = más acertado. El músculo principal manda sobre el equipo
  /// y sobre una palabra suelta como «inclinado».
  static int _focusScore({
    required Exercise exercise,
    required ExerciseSmartFocus focus,
    required String name,
    required String muscles,
    required String primary,
    required String category,
  }) {
    final keys = focus.resolvedPrimaryKeys.map(normalize).toList();
    final family = focus.familyKeys.map(normalize).toList();
    final nameHit = focus.nameNeedles.any((needle) => name.contains(normalize(needle)));
    final stapleIndex = focus.stapleIds.indexOf(exercise.id);
    final stapleBonus = stapleIndex >= 0 ? 5000 - stapleIndex * 10 : 0;

    if (focus.broad) {
      final hit = _hasKey(primary, keys) ||
          _hasKey(category, keys) ||
          _hasKey(muscles, keys);
      if (!hit) return 0;
      return 60000 + (nameHit ? 10000 : 0) + stapleBonus + (_hasKey(primary, keys) ? 2000 : 0);
    }

    final primaryHit = _hasKey(primary, keys);
    if (primaryHit) {
      return 100000 + (nameHit ? 10000 : 0) + stapleBonus;
    }

    if (focus.movementFamilies.isEmpty || family.isEmpty) return 0;
    final movement = SmartRoutineCatalog.movementKey(exercise.id, exercise.name);
    if (!focus.movementFamilies.contains(movement)) return 0;
    final familyHit = _hasKey(primary, family) || _hasKey(category, family);
    if (!familyHit) return 0;
    return 40000 + (nameHit ? 10000 : 0) + stapleBonus;
  }

  static bool _hasKey(String haystack, List<String> keys) {
    if (haystack.isEmpty) return false;
    for (final key in keys) {
      if (key.isNotEmpty && haystack.contains(key)) return true;
    }
    return false;
  }

  static List<_Hit<T>> _hits<T>(String query, List<_Phrase<T>> phrases) {
    final found = <_Hit<T>>[];
    for (final phrase in phrases) {
      final start = query.indexOf(phrase.text);
      if (start < 0) continue;
      found.add(_Hit(
        start: start,
        end: start + phrase.text.length,
        value: phrase.value,
      ));
    }
    found.sort((a, b) => (b.end - b.start).compareTo(a.end - a.start));
    final kept = <_Hit<T>>[];
    for (final hit in found) {
      final insideLonger = kept.any(
        (other) => hit.start >= other.start && hit.end <= other.end,
      );
      if (!insideLonger) kept.add(hit);
    }
    return kept;
  }

  static List<String> _leftoverTokens(String query, List<_Span> consumed) {
    final chars = query.split('');
    for (final span in consumed) {
      for (var i = span.start; i < span.end && i < chars.length; i++) {
        chars[i] = ' ';
      }
    }
    return normalize(chars.join(' '))
        .split(' ')
        .where((token) => token.length >= 3 && !_stopwords.contains(token))
        .toList();
  }
}

class _Span {
  final int start;
  final int end;
  const _Span({required this.start, required this.end});
}

class _Hit<T> extends _Span {
  final T value;
  const _Hit({required super.start, required super.end, required this.value});
}

class _Phrase<T> {
  final String text;
  final T value;
  const _Phrase(this.text, this.value);
}

const _stopwords = {
  'para', 'con', 'del', 'las', 'los', 'una', 'uno', 'unos', 'unas',
  'por', 'en', 'al', 'el', 'la', 'de',
  'que', 'mis', 'algo', 'ejercicio', 'ejercicios', 'trabajar',
  'quiero', 'busco', 'enfocado', 'enfocada', 'zona', 'musculo', 'musculos',
  'usando', 'usar', 'hacer', 'tipo', 'variante', 'durante', 'entre',
};

const _focusPhrases = <_Phrase<ExerciseSmartFocus>>[
  _Phrase(
    'hombro frontal',
    ExerciseSmartFocus(
      cloudTermsJoined: 'front raise',
      targetId: 'deltoides_anterior',
      nameNeedles: ['elevacion frontal', 'front raise', 'frontal'],
    ),
  ),
  _Phrase(
    'deltoides frontal',
    ExerciseSmartFocus(
      cloudTermsJoined: 'front raise',
      targetId: 'deltoides_anterior',
      nameNeedles: ['elevacion frontal', 'front raise', 'frontal'],
    ),
  ),
  _Phrase(
    'front delt',
    ExerciseSmartFocus(
      cloudTermsJoined: 'front raise',
      targetId: 'deltoides_anterior',
      nameNeedles: ['front raise', 'elevacion frontal', 'frontal'],
    ),
  ),
  _Phrase(
    'elevacion frontal',
    ExerciseSmartFocus(
      cloudTermsJoined: 'front raise',
      targetId: 'deltoides_anterior',
      nameNeedles: ['elevacion frontal', 'front raise', 'frontal'],
    ),
  ),
  _Phrase(
    'hombro lateral',
    ExerciseSmartFocus(
      cloudTermsJoined: 'lateral raise',
      targetId: 'deltoides_lateral',
      nameNeedles: ['elevacion lateral', 'lateral raise'],
    ),
  ),
  _Phrase(
    'deltoides lateral',
    ExerciseSmartFocus(
      cloudTermsJoined: 'lateral raise',
      targetId: 'deltoides_lateral',
      nameNeedles: ['elevacion lateral', 'lateral raise'],
    ),
  ),
  _Phrase(
    'hombro posterior',
    ExerciseSmartFocus(
      cloudTermsJoined: 'rear delt',
      targetId: 'deltoides_posterior',
      nameNeedles: ['posterior', 'rear delt', 'face pull', 'pajaro'],
    ),
  ),
  _Phrase(
    'deltoides posterior',
    ExerciseSmartFocus(
      cloudTermsJoined: 'rear delt',
      targetId: 'deltoides_posterior',
      nameNeedles: ['posterior', 'rear delt', 'face pull'],
    ),
  ),
  _Phrase(
    'pecho superior',
    ExerciseSmartFocus(
      cloudTermsJoined: 'incline chest',
      targetId: 'pecho_superior',
      familyKeys: ['pecho', 'chest'],
      movementFamilies: ['incline_press', 'incline_fly'],
      nameNeedles: ['inclinado', 'incline', 'superior'],
    ),
  ),
  _Phrase(
    'upper chest',
    ExerciseSmartFocus(
      cloudTermsJoined: 'incline chest',
      targetId: 'pecho_superior',
      familyKeys: ['pecho', 'chest'],
      movementFamilies: ['incline_press', 'incline_fly'],
      nameNeedles: ['incline', 'inclinado', 'upper'],
    ),
  ),
  _Phrase(
    'pecho inferior',
    ExerciseSmartFocus(
      cloudTermsJoined: 'decline chest',
      targetId: 'pecho_inferior',
      familyKeys: ['pecho', 'chest'],
      movementFamilies: ['decline_press', 'decline_fly'],
      nameNeedles: ['declinado', 'decline', 'inferior'],
    ),
  ),
  _Phrase(
    'peso muerto rumano',
    ExerciseSmartFocus(
      cloudTermsJoined: 'romanian deadlift',
      targetId: 'isquios',
      primaryKeys: ['femoral', 'isquio'],
      movementFamilies: ['rdl'],
      familyKeys: ['isquio', 'femoral', 'hamstring', 'pierna', 'leg'],
      nameNeedles: ['rumano', 'romanian', 'rdl'],
    ),
  ),
  _Phrase(
    'curl femoral',
    ExerciseSmartFocus(
      cloudTermsJoined: 'leg curl',
      targetId: 'isquios',
      primaryKeys: ['femoral', 'isquio'],
      movementFamilies: ['leg_curl'],
      familyKeys: ['isquio', 'femoral', 'hamstring', 'pierna', 'leg'],
      nameNeedles: ['femoral', 'leg curl'],
    ),
  ),
  _Phrase(
    'hombro',
    ExerciseSmartFocus(
      cloudTermsJoined: 'shoulder',
      primaryKeys: ['hombro', 'shoulder', 'delto'],
      nameNeedles: ['hombro', 'shoulder', 'delto'],
      broad: true,
    ),
  ),
  _Phrase(
    'shoulder',
    ExerciseSmartFocus(
      cloudTermsJoined: 'shoulder',
      primaryKeys: ['shoulder', 'hombro', 'delto'],
      nameNeedles: ['shoulder', 'hombro', 'delto'],
      broad: true,
    ),
  ),
  _Phrase(
    'pecho',
    ExerciseSmartFocus(
      cloudTermsJoined: 'chest',
      targetId: 'pecho',
      primaryKeys: ['pecho', 'chest'],
      nameNeedles: ['pecho', 'chest'],
      broad: true,
    ),
  ),
  _Phrase(
    'chest',
    ExerciseSmartFocus(
      cloudTermsJoined: 'chest',
      targetId: 'pecho',
      primaryKeys: ['chest', 'pecho'],
      nameNeedles: ['chest', 'pecho'],
      broad: true,
    ),
  ),
  _Phrase(
    'espalda',
    ExerciseSmartFocus(
      cloudTermsJoined: 'back',
      primaryKeys: ['espalda', 'dorsal', 'back', 'lats'],
      nameNeedles: ['espalda', 'remo', 'jalon'],
      broad: true,
    ),
  ),
  _Phrase(
    'dorsal',
    ExerciseSmartFocus(
      cloudTermsJoined: 'lat pulldown',
      targetId: 'dorsales',
      nameNeedles: ['jalon', 'pulldown', 'dominada'],
    ),
  ),
  _Phrase(
    'bicep',
    ExerciseSmartFocus(
      cloudTermsJoined: 'biceps curl',
      targetId: 'biceps',
      primaryKeys: ['bicep'],
      nameNeedles: ['bicep', 'curl de bicep', 'biceps curl'],
      broad: true,
    ),
  ),
  _Phrase(
    'tricep',
    ExerciseSmartFocus(
      cloudTermsJoined: 'triceps',
      targetId: 'triceps',
      primaryKeys: ['tricep'],
      nameNeedles: ['tricep', 'pushdown', 'fondos'],
      broad: true,
    ),
  ),
  _Phrase(
    'cuadricep',
    ExerciseSmartFocus(
      cloudTermsJoined: 'squat',
      targetId: 'cuadriceps',
      primaryKeys: ['cuadricep', 'quad'],
      nameNeedles: ['sentadilla', 'squat', 'extension de piernas'],
    ),
  ),
  _Phrase(
    'sentadilla',
    ExerciseSmartFocus(
      cloudTermsJoined: 'squat',
      targetId: 'cuadriceps',
      primaryKeys: ['cuadricep', 'quad'],
      movementFamilies: ['squat'],
      familyKeys: ['cuadricep', 'quad', 'pierna', 'leg'],
      nameNeedles: ['sentadilla', 'squat'],
    ),
  ),
  _Phrase(
    'femoral',
    ExerciseSmartFocus(
      cloudTermsJoined: 'leg curl',
      targetId: 'isquios',
      primaryKeys: ['femoral', 'isquio'],
      nameNeedles: ['femoral', 'leg curl'],
    ),
  ),
  _Phrase(
    'isquio',
    ExerciseSmartFocus(
      cloudTermsJoined: 'hamstring',
      targetId: 'isquios',
      primaryKeys: ['isquio', 'femoral'],
      nameNeedles: ['isquio', 'femoral', 'rumano'],
    ),
  ),
  _Phrase(
    'gluteo',
    ExerciseSmartFocus(
      cloudTermsJoined: 'glute',
      targetId: 'gluteos',
      primaryKeys: ['glute'],
      nameNeedles: ['gluteo', 'hip thrust', 'puente'],
      broad: true,
    ),
  ),
  _Phrase(
    'pantorrilla',
    ExerciseSmartFocus(
      cloudTermsJoined: 'calf raise',
      targetId: 'pantorrillas',
      primaryKeys: ['pantorrilla', 'gemelo', 'calf'],
      nameNeedles: ['pantorrilla', 'gemelo', 'calf'],
    ),
  ),
  _Phrase(
    'gemelo',
    ExerciseSmartFocus(
      cloudTermsJoined: 'calf raise',
      targetId: 'pantorrillas',
      primaryKeys: ['gemelo', 'pantorrilla', 'calf'],
      nameNeedles: ['gemelo', 'pantorrilla', 'calf'],
    ),
  ),
  _Phrase(
    'abdomen',
    ExerciseSmartFocus(
      cloudTermsJoined: 'crunch',
      targetId: 'abdominales',
      primaryKeys: ['abdomen', 'abs'],
      nameNeedles: ['abdomen', 'crunch', 'plancha'],
      broad: true,
    ),
  ),
  _Phrase(
    'abdominal',
    ExerciseSmartFocus(
      cloudTermsJoined: 'crunch',
      targetId: 'abdominales',
      primaryKeys: ['abdominal', 'abdomen', 'abs'],
      nameNeedles: ['abdominal', 'crunch', 'plancha'],
      broad: true,
    ),
  ),
  _Phrase(
    'antebrazo',
    ExerciseSmartFocus(
      cloudTermsJoined: 'wrist curl',
      targetId: 'antebrazos',
      primaryKeys: ['antebrazo', 'forearm', 'muneca'],
      nameNeedles: ['antebrazo', 'muneca', 'wrist'],
    ),
  ),
  _Phrase(
    'trapecio',
    ExerciseSmartFocus(
      cloudTermsJoined: 'shrug',
      primaryKeys: ['trapecio', 'trap'],
      nameNeedles: ['trapecio', 'encogimiento', 'shrug'],
    ),
  ),
];

const _gearPhrases = <_Phrase<ExerciseSmartGear>>[
  _Phrase(
    'mancuerna',
    ExerciseSmartGear(needles: ['mancuerna', 'dumbbell'], cloudTerm: 'dumbbell'),
  ),
  _Phrase(
    'dumbbell',
    ExerciseSmartGear(needles: ['dumbbell', 'mancuerna'], cloudTerm: 'dumbbell'),
  ),
  _Phrase(
    'barra',
    ExerciseSmartGear(needles: ['barra', 'barbell'], cloudTerm: 'barbell'),
  ),
  _Phrase(
    'barbell',
    ExerciseSmartGear(needles: ['barbell', 'barra'], cloudTerm: 'barbell'),
  ),
  _Phrase(
    'polea',
    ExerciseSmartGear(needles: ['polea', 'cable'], cloudTerm: 'cable'),
  ),
  _Phrase(
    'cable',
    ExerciseSmartGear(needles: ['cable', 'polea'], cloudTerm: 'cable'),
  ),
  _Phrase(
    'maquina',
    ExerciseSmartGear(needles: ['maquina', 'machine', 'palanca'], cloudTerm: 'machine'),
  ),
  _Phrase(
    'machine',
    ExerciseSmartGear(needles: ['machine', 'maquina'], cloudTerm: 'machine'),
  ),
  _Phrase(
    'banda',
    ExerciseSmartGear(needles: ['banda', 'band'], cloudTerm: 'band'),
  ),
  _Phrase(
    'peso corporal',
    ExerciseSmartGear(
      needles: ['peso corporal', 'bodyweight'],
      cloudTerm: 'bodyweight',
    ),
  ),
  _Phrase(
    'kettlebell',
    ExerciseSmartGear(needles: ['kettlebell', 'pesa rusa'], cloudTerm: 'kettlebell'),
  ),
  _Phrase(
    'pesa rusa',
    ExerciseSmartGear(needles: ['pesa rusa', 'kettlebell'], cloudTerm: 'kettlebell'),
  ),
  _Phrase(
    'smith',
    ExerciseSmartGear(needles: ['smith'], cloudTerm: 'smith'),
  ),
];
