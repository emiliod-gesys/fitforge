import '../../models/exercise.dart';
import '../../models/exercise_logging.dart';
import '../../models/routine.dart';
import 'ai_routine_sanitizer.dart';

abstract final class ExerciseMatcher {
  static Routine enrich(Routine routine, List<Exercise> catalog) {
    return AiRoutineSanitizer.enrichAndSanitize(
      routine,
      catalog,
      targetMuscles: routine.targetMuscles,
    );
  }

  static Exercise? findBest(String name, List<Exercise> catalog) {
    final query = _normalize(name);
    if (query.isEmpty ||
        AiRoutineSanitizer.isLowQualityExerciseName(name) ||
        AiRoutineSanitizer.isVagueExerciseName(name)) {
      return null;
    }

    Exercise? best;
    var bestScore = 0;

    for (final exercise in catalog) {
      if (!AiRoutineSanitizer.isEligibleForAi(exercise)) continue;
      var score = _score(query, _normalize(exercise.name));
      for (final alias in exercise.aliases) {
        final aliasScore = _score(query, _normalize(alias));
        if (aliasScore > score) score = aliasScore;
      }
      if (score > bestScore) {
        bestScore = score;
        best = exercise;
      }
    }

    return bestScore >= 55 ? best : null;
  }

  static int _score(String a, String b) {
    if (a == b) return 100;
    if (b.contains(a) || a.contains(b)) return 85;

    final aWords = a.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    final bWords = b.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    if (aWords.isEmpty || bWords.isEmpty) return 0;

    final overlap = aWords.intersection(bWords).length;
    final union = aWords.union(bWords).length;
    return ((overlap / union) * 100).round();
  }

  static String _normalize(String input) {
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
}
