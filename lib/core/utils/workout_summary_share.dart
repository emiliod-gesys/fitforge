import '../core/utils/unit_converter.dart';
import '../models/workout_summary.dart';

abstract final class WorkoutSummaryShare {
  static String formatText(WorkoutSummaryData summary, String unitSystem) {
    final w = summary.workout;
    final buffer = StringBuffer()
      ..writeln('💪 ${w.name} — FitForge')
      ..writeln('⏱ ${summary.durationMinutes} min')
      ..writeln('🏋️ ${summary.exercises.length} ejercicios')
      ..writeln('🔁 ${summary.totalReps} reps totales');

    if (summary.maxWeightKg != null) {
      buffer.writeln('📈 Peso máx: ${UnitConverter.formatMass(summary.maxWeightKg, unitSystem)}');
    }
    buffer.writeln('📊 Volumen: ${UnitConverter.formatVolume(summary.totalVolumeKg, unitSystem)}');

    if (summary.brokenRecords.isNotEmpty) {
      buffer.writeln()
        ..writeln('🏆 ¡Nuevos récords vs última vez!')
        ..writeln(summary.brokenRecords.map((r) => '• $r').join('\n'));
    }

    buffer.writeln().writeln('Ejercicios:');
    for (final ex in summary.exercises) {
      final weight = ex.bestWeightKg != null
          ? ' · ${UnitConverter.formatMass(ex.bestWeightKg, unitSystem)}'
          : '';
      buffer.writeln('• ${ex.exerciseName}: ${ex.completedSets}× · ${ex.totalReps} reps$weight');
    }

    buffer.writeln().writeln('#FitForge #Entrenamiento');
    return buffer.toString().trim();
  }
}
