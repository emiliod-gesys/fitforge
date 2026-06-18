import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/workout_summary.dart';
import 'unit_converter.dart';

abstract final class WorkoutSummaryShare {
  static String formatText(
    AppLocalizations l10n,
    WorkoutSummaryData summary,
    String unitSystem, {
    String? displayName,
  }) {
    final w = summary.workout;
    final name = displayName ?? l10n.workoutDisplayName(w.name);
    final buffer = StringBuffer()
      ..writeln(l10n.shareWorkoutTitle(name))
      ..writeln(l10n.shareDuration(summary.durationMinutes))
      ..writeln(l10n.shareExerciseCount(summary.exercises.length))
      ..writeln(l10n.shareTotalReps(summary.totalReps));

    if (summary.maxWeightKg != null) {
      buffer.writeln(
        l10n.shareMaxWeight(UnitConverter.formatMass(summary.maxWeightKg, unitSystem)),
      );
    }
    buffer.writeln(
      l10n.shareVolume(UnitConverter.formatVolume(summary.totalVolumeKg, unitSystem)),
    );
    if (summary.hasCalorieEstimate) {
      buffer.writeln(
        l10n.shareCalories(l10n.caloriesKcal(summary.calorieEstimate.caloriesKcal!)),
      );
    }

    final records = l10n.brokenRecordLabels(
      isVolumeRecord: summary.isVolumeRecord,
      isRepsRecord: summary.isRepsRecord,
      isMaxWeightRecord: summary.isMaxWeightRecord,
    );
    if (records.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(l10n.shareNewRecords)
        ..writeln(records.map((r) => '• $r').join('\n'));
    }

    buffer
      ..writeln()
      ..writeln(l10n.shareExercisesHeader);
    for (final ex in summary.exercises) {
      final weight = ex.bestWeightKg != null
          ? ' · ${UnitConverter.formatMass(ex.bestWeightKg, unitSystem)}'
          : '';
      buffer.writeln(
        l10n.shareExerciseLine(ex.exerciseName, ex.completedSets, ex.totalReps, weight),
      );
    }

    buffer
      ..writeln()
      ..writeln(l10n.shareHashtags);
    return buffer.toString().trim();
  }
}
