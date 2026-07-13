import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/workout.dart';
import '../../models/workout_summary.dart';
import '../../widgets/milestones_section.dart';
import '../../widgets/runner_surface_picker.dart';
import 'cardio_format.dart';
import 'unit_converter.dart';

abstract final class WorkoutSummaryShare {
  static String formatText(
    AppLocalizations l10n,
    WorkoutSummaryData summary,
    String unitSystem, {
    String? displayName,
  }) {
    final name = displayName ?? l10n.workoutDisplayName(summary.workout.name);

    if (summary.hasHyroxSplits) {
      return _formatHyrox(l10n, summary, name);
    }
    if (summary.isRunner) {
      return _formatRunner(l10n, summary, unitSystem, name);
    }
    return _formatGym(l10n, summary, unitSystem, name);
  }

  static String _formatHyrox(AppLocalizations l10n, WorkoutSummaryData summary, String name) {
    final buffer = StringBuffer()
      ..writeln(l10n.shareHyroxTitle(name))
      ..writeln(l10n.shareHyroxTotalTime(CardioFormat.duration(summary.hyroxTotalSeconds)))
      ..writeln()
      ..writeln(l10n.hyroxSplitsSummaryTitle);

    for (final entry in summary.hyroxSplits.asMap().entries) {
      buffer.writeln(
        l10n.shareHyroxStationLine(
          entry.key + 1,
          entry.value.exerciseName,
          CardioFormat.duration(entry.value.seconds),
        ),
      );
    }

    if (summary.xpAward != null && summary.xpAward!.xpEarned > 0) {
      buffer
        ..writeln()
        ..writeln(l10n.shareXpEarned(summary.xpAward!.xpEarned));
    }

    buffer
      ..writeln()
      ..writeln(l10n.shareHashtags);
    return buffer.toString().trim();
  }

  static String _formatRunner(
    AppLocalizations l10n,
    WorkoutSummaryData summary,
    String unitSystem,
    String name,
  ) {
    final workout = summary.workout;
    WorkoutSet? cardioSet;
    for (final ex in workout.exercises) {
      for (final s in ex.sets) {
        if (s.completed && s.isCardio) {
          cardioSet = s;
          break;
        }
      }
      if (cardioSet != null) break;
    }

    final buffer = StringBuffer()..writeln(l10n.shareRunnerTitle(name));

    if (workout.runnerSurface != null) {
      buffer.writeln(runnerSurfaceLabel(l10n, workout.runnerSurface!));
    }

    buffer.writeln(
      l10n.shareRunnerStats(
        CardioFormat.distance(cardioSet?.distanceMeters, unitSystem),
        CardioFormat.pace(workout.runnerAvgPaceSecPerKm, unitSystem),
        CardioFormat.duration(cardioSet?.durationSeconds),
      ),
    );

    if (cardioSet?.inclinePercent != null) {
      buffer.writeln('${l10n.runnerInclineLabel}: ${CardioFormat.incline(cardioSet!.inclinePercent)}');
    }

    if (workout.runnerSplits.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(l10n.runnerSplitsTitle);
      for (final split in workout.runnerSplits) {
        buffer.writeln(
          l10n.shareRunnerSplitLine(split.km, CardioFormat.duration(split.seconds)),
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
      ..writeln(l10n.shareHashtags);
    return buffer.toString().trim();
  }

  static String _formatGym(
    AppLocalizations l10n,
    WorkoutSummaryData summary,
    String unitSystem,
    String name,
  ) {
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
      if (summary.rankTierIncreased && summary.xpAward != null) {
        final level = summary.xpAward!.after.level;
        buffer.writeln(
          l10n.shareRankUp(l10n.playerLevelBadgeName(level), level),
        );
      }
      for (final unlock in summary.newMilestoneUnlocks) {
        buffer.writeln(
          l10n.shareMilestoneUnlocked(
            MilestonesSection.categoryLabel(l10n, unlock.category),
            l10n.milestoneTierName(unlock.tier),
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
