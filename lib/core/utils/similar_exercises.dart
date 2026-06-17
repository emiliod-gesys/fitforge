import '../../models/exercise.dart';
import 'muscle_inference.dart';

abstract final class SimilarExercises {
  static List<Exercise> find({
    required String exerciseName,
    required String exerciseId,
    required List<Exercise> catalog,
    required Set<String> excludeIds,
    int limit = 20,
  }) {
    Exercise? match;
    for (final e in catalog) {
      if (e.id == exerciseId) {
        match = e;
        break;
      }
    }

    final muscles = match?.muscles.isNotEmpty == true
        ? match!.muscles
        : MuscleInference.resolve(exerciseName: exerciseName);
    final category = match?.category ?? '';

    final scored = <(Exercise exercise, int score)>[];

    for (final candidate in catalog) {
      if (candidate.id == exerciseId || excludeIds.contains(candidate.id)) continue;

      var score = 0;
      if (category.isNotEmpty && candidate.category == category) score += 12;

      final candidateMuscles = candidate.muscles.isNotEmpty
          ? candidate.muscles
          : MuscleInference.resolve(exerciseName: candidate.name);

      for (final muscle in muscles) {
        final m = muscle.toLowerCase();
        for (final cm in candidateMuscles) {
          final c = cm.toLowerCase();
          if (c == m || c.contains(m) || m.contains(c)) {
            score += 8;
            break;
          }
        }
      }

      if (score == 0 && muscles.isNotEmpty) {
        final inferred = MuscleInference.resolve(exerciseName: candidate.name);
        for (final muscle in muscles) {
          if (inferred.contains(muscle)) score += 5;
        }
      }

      if (score > 0) scored.add((candidate, score));
    }

    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      if (byScore != 0) return byScore;
      return a.$1.name.compareTo(b.$1.name);
    });

    return scored.take(limit).map((e) => e.$1).toList();
  }
}
