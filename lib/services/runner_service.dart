import '../core/runner/runner_routine_builder.dart';
import '../core/runner/runner_standards.dart';
import '../models/profile.dart';
import '../models/routine.dart';
import 'routine_service.dart';
import 'supabase_service.dart';

/// Activa/desactiva modo Runner y sincroniza las rutinas sistema.
class RunnerService {
  RunnerService(this._routines);

  final RoutineService _routines;

  Future<void> setRunnerMode({
    required bool enabled,
    required UserProfile profile,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    await SupabaseService.client.from('profiles').update({
      'runner_mode': enabled,
    }).eq('id', userId);

    if (enabled) {
      await syncRunnerRoutines(profile);
    } else {
      await _deleteRunnerRoutines(userId);
    }
  }

  /// Crea tipos runner faltantes (p. ej. caminata para quien ya tenía el modo on).
  Future<void> ensureRunnerRoutines(UserProfile profile) async {
    if (!profile.runnerMode) return;
    final userId = profile.id;
    final existing = await _routines.getRunnerSystemRoutines(userId);
    final byType = <RunnerType, Routine>{
      for (final r in existing)
        if (r.runnerType != null) r.runnerType!: r,
    };

    for (final type in RunnerType.values) {
      if (byType.containsKey(type)) continue;
      await _routines.createRunnerSystemRoutine(
        RunnerRoutineBuilder.build(userId: userId, type: type),
      );
    }
  }

  Future<void> syncRunnerRoutines(UserProfile profile) async {
    final userId = profile.id;
    final existing = await _routines.getRunnerSystemRoutines(userId);
    final byType = <RunnerType, Routine>{
      for (final r in existing)
        if (r.runnerType != null) r.runnerType!: r,
    };

    for (final type in RunnerType.values) {
      final built = RunnerRoutineBuilder.build(userId: userId, type: type);
      final current = byType[type];
      if (current == null) {
        await _routines.createRunnerSystemRoutine(built);
      } else {
        await _routines.updateRoutine(built.copyWith(id: current.id));
      }
    }
  }

  Future<void> _deleteRunnerRoutines(String userId) async {
    final existing = await _routines.getRunnerSystemRoutines(userId);
    for (final r in existing) {
      await _routines.deleteRoutine(r.id);
    }
  }
}
