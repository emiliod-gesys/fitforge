import '../../models/profile.dart';

/// Reglas de programación para IA proactiva según objetivo fitness del usuario.
abstract final class ProactiveWorkoutAiRules {
  static String goalProgrammingBlock(UserProfile profile) {
    final goal = profile.fitnessGoal ?? 'Mantenimiento';
    final experience = profile.experienceLevel ?? 'intermedio';

    return '''
OBJETIVO DEL USUARIO: $goal
EXPERIENCIA: $experience

Programación por objetivo (puedes cambiar peso, reps Y cantidad de series respecto a la plantilla):
${_rulesForGoal(goal)}

Series de aproximación / calentamiento (fuerza):
- Puedes AÑADIR o QUITAR series respecto a set_count de la rutina.
- Compuestos pesados (press, sentadilla, peso muerto, remo): en Fuerza e Hipertrofia con historial, incluye 1-3 series de aproximación progresivas (peso menor, más reps) ANTES de las series de trabajo si el peso de trabajo es significativo.
- Aislamiento (curl, extensiones, elevaciones): normalmente SIN series de aproximación; ve directo a series de trabajo.
- Si recovery_pct < 60 o sin historial: evita aproximaciones; usa 1 serie ligera o ninguna.
- Pérdida de grasa / Resistencia: sin aproximaciones; prioriza densidad y más reps.
- Mantenimiento: similar al historial; aproximaciones solo si el historial las mostraba (pesos ascendentes al inicio).

Pesos variados en la misma sesión o entre sesiones del mismo día:
- set_weights_kg en latest_session_summary muestra TODAS las series en orden (aproximación + trabajo).
- weight_pattern: warmup_then_work = series ligeras al inicio + trabajo pesado; pyramid/varied = cargas mixtas.
- Ancla el peso de TRABAJO en working_weight_kg (≥85% del máximo de la sesión), NO en el primer set ni en series ligeras.
- Si la sesión cronológica más reciente tiene peso mucho menor que recent_top_set o working_weight_kg de otra sesión reciente, ignora la sesión ligera (suele ser entreno abandonado) y usa la sesión con mayor carga.
- En aislamiento sin aproximaciones (weight_pattern constant), working_weight_kg ≈ heaviest_weight_kg.

Límites de series por ejercicio:
- Fuerza (strength): 1-10 series totales (aproximación + trabajo).
- Cardio: 1-3 series.
- Cada serie debe tener set_number consecutivo 1..N.
''';
  }

  static String _rulesForGoal(String goal) {
    final normalized = goal.toLowerCase();
    if (normalized.contains('fuerza') || normalized.contains('strength')) {
      return '''
- Fuerza: 3-6 series de TRABAJO, 3-6 reps, peso alto. Añade 1-3 aproximaciones en compuestos si hay historial con peso ≥ 60% del 1RM estimado.
- Aproximación típica: ~50% × 8-10, ~70% × 4-5, luego series de trabajo al 85-95%.
- Si el usuario es principiante, omite aproximaciones y usa 3 series moderadas.''';
    }
    if (normalized.contains('hipertrofia') || normalized.contains('hypertrophy')) {
      return '''
- Hipertrofia: 3-5 series de trabajo, 8-12 reps. En compuestos pesados puedes usar 1-2 aproximaciones ligeras.
- Progresión: mantén o sube ligeramente el peso si recovery_pct ≥ 70.
- Aislamiento: 2-4 series directas, 10-15 reps, sin aproximación.''';
    }
    if (normalized.contains('grasa') || normalized.contains('fat')) {
      return '''
- Pérdida de grasa: 2-4 series, 12-20 reps, descansos cortos. Sin series de aproximación.
- Peso moderado; prioriza volumen y reps sobre carga máxima.''';
    }
    if (normalized.contains('resistencia') || normalized.contains('endurance')) {
      return '''
- Resistencia: 2-3 series, 15+ reps o tiempo/distancia en cardio. Sin aproximaciones.
- Cardio: ajusta duration_seconds / distance_meters según historial.''';
    }
    return '''
- Mantenimiento: respeta el historial reciente. Micro-progresión solo si recovery_pct ≥ 80.
- Series: similar a history_avg_set_count o set_count. Aproximaciones opcionales en compuestos si el historial muestra pesos crecientes al inicio.''';
  }
}
