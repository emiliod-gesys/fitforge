import 'dart:math' as math;

import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../constants/app_constants.dart';
import 'smart_routine_catalog.dart';

/// Ejercicio que el usuario ya hizo, del más reciente al más antiguo.
class RecentExerciseRef {
  final String id;
  final String name;

  const RecentExerciseRef({required this.id, required this.name});
}

/// Arma una rutina con los músculos elegidos.
///
/// Primero usa ejercicios recientes del usuario que pegan con ese músculo.
/// El resto sale de los ejercicios más habituales del gym y, si aún faltan,
/// del resto del catálogo de ese músculo principal.
///
/// El mismo movimiento con otro equipo no se repite: se queda una variante
/// y se le suman un par de series.
abstract final class SmartRoutineBuilder {
  static const maxExercises = 8;
  static const redundantExtraSets = 2;
  static const maxSetsPerExercise = 5;

  static Routine build({
    required List<SmartMuscleTarget> targets,
    required List<Exercise> catalog,
    required List<RecentExerciseRef> recent,
    required String languageCode,
    required String namePrefix,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final chosen = _pick(targets, catalog, recent);

    final labels = targets.map((target) => target.label(languageCode)).toList();
    final exercises = <RoutineExercise>[];
    for (var i = 0; i < chosen.length; i++) {
      final exercise = chosen[i].exercise;
      final details = List.generate(
        chosen[i].sets,
        (_) => const RoutineSetTarget(reps: AppConstants.defaultReps),
      );
      exercises.add(
        RoutineExercise(
          id: '',
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          orderIndex: i,
          imageUrl: exercise.imageUrl,
          loggingType: exercise.loggingType,
          targetSets: details.length,
          targetReps: AppConstants.defaultReps,
          restSeconds: AppConstants.defaultRestSeconds,
          targetSetDetails: details,
        ),
      );
    }

    return Routine(
      id: '',
      userId: '',
      name: labels.isEmpty ? namePrefix : '$namePrefix · ${labels.join(' · ')}',
      description: labels.join(', '),
      targetMuscles: labels,
      exercises: exercises,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  static List<int> _quotas(int muscleCount) {
    if (muscleCount <= 0) return const [];
    if (muscleCount == 1) return const [6];
    // Con pocos músculos se reparte un entreno de 8. Si elige más, entra
    // al menos un ejercicio de cada uno.
    final total = muscleCount > maxExercises ? muscleCount : maxExercises;
    final base = total ~/ muscleCount;
    var extra = total % muscleCount;
    return List.generate(muscleCount, (_) {
      final quota = base + (extra > 0 ? 1 : 0);
      if (extra > 0) extra--;
      return quota;
    });
  }

  static List<_ChosenExercise> _pick(
    List<SmartMuscleTarget> targets,
    List<Exercise> catalog,
    List<RecentExerciseRef> recent,
  ) {
    final usedIds = <String>{};
    final byFamily = <String, _ChosenExercise>{};
    final bumped = <String>{};
    final chosen = <_ChosenExercise>[];
    final quotas = _quotas(targets.length);

    for (var i = 0; i < targets.length; i++) {
      var filled = 0;
      final quota = i < quotas.length ? quotas[i] : 0;
      if (quota <= 0) continue;
      for (final exercise in _rank(targets[i], catalog, recent)) {
        if (filled >= quota) break;
        if (!usedIds.add(exercise.id)) continue;
        final family = SmartRoutineCatalog.movementKey(exercise.id, exercise.name);
        final existing = byFamily[family];
        if (existing != null) {
          if (existing.muscleIndex == i && bumped.add(family)) {
            existing.sets = math.min(maxSetsPerExercise, existing.sets + redundantExtraSets);
            filled++;
          }
          continue;
        }
        final pick = _ChosenExercise(exercise, i);
        byFamily[family] = pick;
        chosen.add(pick);
        filled++;
      }
    }
    return chosen;
  }

  static List<Exercise> _rank(
    SmartMuscleTarget target,
    List<Exercise> catalog,
    List<RecentExerciseRef> recent,
  ) {
    final matches = catalog.where((exercise) => _matches(exercise, target)).toList();
    final stapleIndex = {
      for (var i = 0; i < target.stapleIds.length; i++) target.stapleIds[i]: i,
    };

    int recentRank(Exercise exercise) {
      final name = _normalize(exercise.name);
      for (var i = 0; i < recent.length; i++) {
        final item = recent[i];
        if (item.id == exercise.id || _normalize(item.name) == name) return i;
      }
      return 1 << 20;
    }

    matches.sort((a, b) {
      final recentCompare = recentRank(a).compareTo(recentRank(b));
      if (recentCompare != 0) return recentCompare;
      final aStaple = stapleIndex[a.id] ?? 1 << 20;
      final bStaple = stapleIndex[b.id] ?? 1 << 20;
      final stapleCompare = aStaple.compareTo(bStaple);
      if (stapleCompare != 0) return stapleCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return matches;
  }

  static bool _matches(Exercise exercise, SmartMuscleTarget target) {
    if (exercise.isCardio || exercise.muscles.isEmpty) return false;
    return target.primaryKeys.contains(_normalize(exercise.muscles.first));
  }

  static String _normalize(String value) {
    return value
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

class _ChosenExercise {
  final Exercise exercise;
  final int muscleIndex;
  int sets;

  _ChosenExercise(this.exercise, this.muscleIndex) : sets = AppConstants.defaultSets;
}
