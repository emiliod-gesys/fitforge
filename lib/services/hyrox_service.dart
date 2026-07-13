import '../core/hyrox/hyrox_routine_builder.dart';
import '../core/hyrox/hyrox_standards.dart';
import '../models/profile.dart';
import '../models/routine.dart';
import 'routine_service.dart';
import 'supabase_service.dart';

/// Activa/desactiva modo Hyrox y sincroniza las 3 rutinas sistema.
class HyroxService {
  HyroxService(this._routines);

  final RoutineService _routines;

  Future<void> setHyroxMode({
    required bool enabled,
    required UserProfile profile,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    await SupabaseService.client.from('profiles').update({
      'hyrox_mode': enabled,
    }).eq('id', userId);

    if (enabled) {
      await syncHyroxRoutines(profile);
    } else {
      await _deleteHyroxRoutines(userId);
    }
  }

  /// Recrea/actualiza las 3 rutinas según género y métricas actuales.
  Future<void> syncHyroxRoutines(UserProfile profile) async {
    final userId = profile.id;
    final existing = await _routines.getHyroxSystemRoutines(userId);
    final byLevel = <HyroxLevel, Routine>{
      for (final r in existing)
        if (r.hyroxLevel != null) r.hyroxLevel!: r,
    };

    for (final level in HyroxLevel.values) {
      final built = HyroxRoutineBuilder.build(profile: profile, level: level);
      final current = byLevel[level];
      if (current == null) {
        await _routines.createHyroxSystemRoutine(built);
      } else {
        await _routines.updateRoutine(built.copyWith(id: current.id));
      }
    }
  }

  Future<void> _deleteHyroxRoutines(String userId) async {
    final existing = await _routines.getHyroxSystemRoutines(userId);
    for (final r in existing) {
      await _routines.deleteRoutine(r.id);
    }
  }
}
