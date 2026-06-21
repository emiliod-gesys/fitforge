import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/workout_summary.dart';
import '../../widgets/milestones_section.dart';
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

    final volumePercent = summary.volumeImprovementPercent;
    if (volumePercent != null) {
      buffer.writeln(l10n.shareVolumeUp(volumePercent.toStringAsFixed(0)));
    }

    if (summary.hasTrainedMuscles) {
      final muscles = summary.trainedMuscleGroups.map(l10n.muscleLabel).join(', ');
      buffer.writeln(l10n.shareMusclesTrained(muscles));
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

    if (summary.hasNewPersonalRecords) {
      buffer
        ..writeln()
        ..writeln(l10n.sharePersonalRecords);
      for (final pr in summary.newPersonalRecords) {
        buffer.writeln('• ${pr.exerciseName}');
      }
    }

    if (summary.hasAchievements) {
      buffer
        ..writeln()
        ..writeln(l10n.shareAchievementsHeader);
      if (summary.leveledUp && summary.xpAward != null) {
        buffer.writeln(
          l10n.shareLevelUp(summary.xpAward!.after.level),
        );
      }
      for (final unlock in summary.newMilestoneUnlocks) {
        buffer.writeln(
          l10n.shareMilestoneUnlocked(
            MilestonesSection.categoryLabel(l10n, unlock.category),
            unlock.tier,
          ),
        );
      }
    }

    if (summary.xpAward != null && summary.xpAward!.xpEarned > 0) {
      buffer
        ..writeln()
        ..writeln(l10n.shareXpEarned(summary.xpAward!.xpEarned));
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
