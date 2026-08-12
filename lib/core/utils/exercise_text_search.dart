import '../../models/exercise.dart';

/// Búsqueda de ejercicios por tokens (cualquier orden) y sinónimos ES/EN.
abstract final class ExerciseTextSearch {
  static const _stopwords = {
    'de', 'del', 'la', 'el', 'los', 'las', 'en', 'con', 'por', 'para',
    'un', 'una', 'the', 'of', 'and', 'to', 'on', 'with', 'al',
  };

  /// Frases largas primero. Se aplican en ambos sentidos.
  static const _phrases = [
    ('press de banca', 'bench press'),
    ('press banca', 'bench press'),
    ('peso muerto rumano', 'romanian deadlift'),
    ('peso muerto', 'deadlift'),
    ('curl martillo', 'hammer curl'),
    ('curl femoral', 'leg curl'),
    ('press militar', 'overhead press'),
    ('press de hombro', 'shoulder press'),
    ('jalon al pecho', 'lat pulldown'),
    ('jalón al pecho', 'lat pulldown'),
    ('remo sentado', 'seated row'),
    ('remo inclinado', 'bent over row'),
    ('aperturas en polea', 'cable fly'),
    ('aperturas con mancuernas', 'dumbbell fly'),
    ('elevacion lateral', 'lateral raise'),
    ('elevación lateral', 'lateral raise'),
    ('elevacion frontal', 'front raise'),
    ('elevación frontal', 'front raise'),
  ];

  static const _words = {
    'banca': 'bench',
    'banco': 'bench',
    'bench': 'banca',
    'mancuerna': 'dumbbell',
    'mancuernas': 'dumbbell',
    'dumbbell': 'mancuerna',
    'dumbbells': 'mancuernas',
    'barra': 'barbell',
    'barbell': 'barra',
    'polea': 'cable',
    'cable': 'polea',
    'sentadilla': 'squat',
    'squat': 'sentadilla',
    'zancada': 'lunge',
    'lunge': 'zancada',
    'dominada': 'pullup',
    'dominadas': 'pullup',
    'flexion': 'pushup',
    'flexiones': 'pushup',
    'remo': 'row',
    'row': 'remo',
    'apertura': 'fly',
    'aperturas': 'fly',
    'fly': 'apertura',
    'jalon': 'pulldown',
    'jalón': 'pulldown',
    'pulldown': 'jalon',
    'inclinado': 'incline',
    'incline': 'inclinado',
    'declinado': 'decline',
    'decline': 'declinado',
    'rumano': 'romanian',
    'romanian': 'rumano',
    'martillo': 'hammer',
    'hammer': 'martillo',
    'muerto': 'deadlift',
    'deadlift': 'muerto',
    'pecho': 'chest',
    'chest': 'pecho',
    'hombro': 'shoulder',
    'hombros': 'shoulders',
    'shoulder': 'hombro',
    'shoulders': 'hombros',
    'espalda': 'back',
    'back': 'espalda',
    'femoral': 'hamstring',
    'maquina': 'machine',
    'máquina': 'machine',
    'machine': 'maquina',
  };

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

  static String expandPhrases(String normalized) {
    var text = normalized;
    for (final pair in _phrases) {
      if (text.contains(pair.$1) && !text.contains(pair.$2)) {
        text = '$text ${pair.$2}';
      }
      if (text.contains(pair.$2) && !text.contains(pair.$1)) {
        text = '$text ${pair.$1}';
      }
    }
    return text;
  }

  static List<String> tokenize(String normalized) {
    return normalized
        .split(' ')
        .where((token) => token.length >= 2 && !_stopwords.contains(token))
        .toList();
  }

  static Set<String> variantsFor(String token) {
    final out = <String>{token};
    final mapped = _words[token];
    if (mapped != null) out.add(mapped);
    return out;
  }

  static bool matchesQuery({
    required String query,
    required Iterable<String> fields,
  }) {
    final rawQuery = normalize(query);
    if (rawQuery.isEmpty) return true;

    final haystack = expandPhrases(normalize(fields.join(' ')));
    final queryExpanded = expandPhrases(rawQuery);
    if (haystack.contains(rawQuery) || haystack.contains(queryExpanded)) {
      return true;
    }

    final tokens = tokenize(rawQuery);
    if (tokens.isEmpty) return haystack.contains(rawQuery);

    return tokens.every((token) {
      return variantsFor(token).any(haystack.contains);
    });
  }

  static bool matchesExercise(Exercise exercise, String query) {
    return matchesQuery(
      query: query,
      fields: [
        exercise.name,
        ...exercise.aliases,
        exercise.category,
        ...exercise.muscles,
        ...exercise.equipment,
      ],
    );
  }

  static int score(Exercise exercise, String query) {
    final rawQuery = normalize(query);
    if (rawQuery.isEmpty) return 0;
    final name = normalize(exercise.name);
    if (name == rawQuery) return 400;
    if (name.startsWith(rawQuery)) return 300;
    if (name.contains(rawQuery)) return 200;
    if (expandPhrases(name).contains(rawQuery)) return 160;
    return 100;
  }

  static List<Exercise> rank(List<Exercise> exercises, String query) {
    if (query.trim().isEmpty) return exercises;
    final ranked = List<Exercise>.from(exercises);
    ranked.sort((a, b) {
      final byScore = score(b, query).compareTo(score(a, query));
      if (byScore != 0) return byScore;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return ranked;
  }
}
