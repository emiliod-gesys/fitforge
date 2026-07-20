import '../../models/profile.dart';
import 'unit_converter.dart';

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

Series de aproximación / calentamiento (fuerza) — OBLIGATORIO cuando warmup_sets_allowed es true:
- DEBES crear 1-3 series de aproximación progresivas ANTES de las series de trabajo (peso ascendente, más reps en las más ligeras).
- Ejemplo compuesto: 40 kg×10, 55 kg×6, 70 kg×5, 75 kg×5, 75 kg×5 (las dos primeras son aproximación).
- El peso de la PRIMERA serie de aproximación suele estar ~50-60% del peso de trabajo; la última aproximación ~75-85%.
- Las aproximaciones cuentan dentro del límite de 10 series totales del ejercicio.
- Si warmup_sets_allowed es false: NO añadas aproximaciones; ve directo a series de trabajo.

Cuándo crear aproximaciones (warmup_sets_allowed):
- Compuestos pesados (press, sentadilla, peso muerto, remo) en Fuerza o Hipertrofia con historial y recovery_pct ≥ 60.
- Aislamiento (curl, extensiones, elevaciones): warmup_sets_allowed será false — sin aproximaciones.
- Si recovery_pct < 60 o sin historial: warmup_sets_allowed será false; usa 0-1 serie ligera o ninguna.
- Pérdida de grasa / Resistencia: sin aproximaciones.

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

${weightIncrementBlock(profile.unitSystem)}
''';
  }

  /// Reglas de incrementos de peso según lo que ve el usuario en entrenos.
  static String weightIncrementBlock(String unitSystem) {
    if (UnitConverter.isLb(unitSystem)) {
      return '''
Incrementos de peso en entrenos (OBLIGATORIO — unit_system=lb):
- Responde siempre en weight_kg, pero elige valores que al mostrarse en lb sean ENTEROS (5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55 lb…).
- NUNCA sugieras pesos que el usuario vería con decimales en lb (ej. 55.3 lb, 22.7 lb).
- Redondea mentalmente a la libra entera más cercana antes de escribir weight_kg.
- Ejemplos válidos: 55 lb ≈ weight_kg 24.9; 135 lb ≈ weight_kg 61.2; 225 lb ≈ weight_kg 102.1.''';
    }
    return '''
Incrementos de peso en entrenos (OBLIGATORIO — unit_system=kg):
- weight_kg debe ser múltiplo de 0.5 kg (10, 10.5, 20, 20.5, 77.5…).
- NUNCA uses decimales raros (20.3, 77.2 kg); solo .0 o .5 en pantalla.
- Mancuernas/discus: incrementos típicos de 0.5 kg; barras a veces 2.5 kg.''';
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

  /// Indica si la IA debe poder añadir series de aproximación para este ejercicio.
  static bool warmupSetsAllowed({
    required bool isCompound,
    required bool isCardio,
    required double recoveryPercent,
    required bool hasWorkingHistory,
    String? fitnessGoal,
  }) {
    if (isCardio || !isCompound) return false;
    if (!hasWorkingHistory || recoveryPercent < 60) return false;

    final goal = (fitnessGoal ?? '').toLowerCase();
    if (goal.contains('grasa') ||
        goal.contains('fat') ||
        goal.contains('resistencia') ||
        goal.contains('endurance')) {
      return false;
    }
    return true;
  }
}
