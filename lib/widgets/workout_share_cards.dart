import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_accent.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/cardio_format.dart';
import '../core/utils/milestone_badge.dart';
import '../core/utils/player_level.dart';
import '../core/utils/player_level_badge.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise_logging.dart';
import '../models/profile.dart';
import '../models/workout.dart';
import '../models/workout_summary.dart';
import '../widgets/fitforge_logo.dart';
import '../widgets/localized_exercise_name.dart';
import '../widgets/milestones_section.dart';
import '../widgets/runner_surface_picker.dart';
import '../widgets/tappable_badge.dart';

const _hyroxAccent = Color(0xFFFF6B00);
const _runnerAccent = Color(0xFF00A884);

class WorkoutShareCard extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;
  final AppLocalizations l10n;

  const WorkoutShareCard({
    super.key,
    required this.summary,
    required this.unitSystem,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.hasHyroxSplits) {
      return _HyroxShareCard(summary: summary, l10n: l10n);
    }
    if (summary.isRunner) {
      return _RunnerShareCard(summary: summary, unitSystem: unitSystem, l10n: l10n);
    }
    return _GymShareCard(summary: summary, unitSystem: unitSystem, l10n: l10n);
  }
}

class _ShareCardShell extends StatelessWidget {
  final List<Color> gradientColors;
  final Color borderColor;
  final Color badgeColor;
  final String badgeLabel;
  final Widget child;

  const _ShareCardShell({
    required this.gradientColors,
    required this.borderColor,
    required this.badgeColor,
    required this.badgeLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FitForgeLogo.icon(height: 28),
              const SizedBox(width: 8),
              const Text('FitForge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.55)),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _HyroxShareCard extends StatelessWidget {
  final WorkoutSummaryData summary;
  final AppLocalizations l10n;

  const _HyroxShareCard({required this.summary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _ShareCardShell(
      gradientColors: [
        _hyroxAccent.withValues(alpha: 0.14),
        AppColors.card,
      ],
      borderColor: _hyroxAccent.withValues(alpha: 0.35),
      badgeColor: _hyroxAccent,
      badgeLabel: l10n.hyroxSystemBadge.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.workoutDisplayName(summary.workout.name),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer_outlined, color: _hyroxAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.shareHyroxTotalTime(CardioFormat.duration(summary.hyroxTotalSeconds)),
                style: TextStyle(
                  color: _hyroxAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.hyroxSplitsSummaryTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...summary.hyroxSplits.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: LocalizedExerciseName(
                      entry.value.exerciseName,
                      exerciseId: entry.value.exerciseId,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    CardioFormat.duration(entry.value.seconds),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (summary.xpAward != null) ...[
            const SizedBox(height: 16),
            _ShareXpBanner(xpAward: summary.xpAward!, l10n: l10n, accent: _hyroxAccent),
          ],
        ],
      ),
    );
  }
}

class _RunnerShareCard extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;
  final AppLocalizations l10n;

  const _RunnerShareCard({
    required this.summary,
    required this.unitSystem,
    required this.l10n,
  });

  WorkoutSet? _cardioSet() {
    for (final ex in summary.workout.exercises) {
      for (final s in ex.sets) {
        if (s.completed && s.isCardio) return s;
      }
    }
    return null;
  }

  bool get _isOutdoor => summary.workout.runnerRoute.length >= 2;

  @override
  Widget build(BuildContext context) {
    final workout = summary.workout;
    final cardio = _cardioSet();
    final points = workout.runnerRoute.map((p) => LatLng(p.lat, p.lng)).toList();

    return _ShareCardShell(
      gradientColors: [
        _runnerAccent.withValues(alpha: 0.14),
        AppColors.card,
      ],
      borderColor: _runnerAccent.withValues(alpha: 0.35),
      badgeColor: _runnerAccent,
      badgeLabel: l10n.runnerSystemBadge.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.workoutDisplayName(summary.workout.name),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (workout.runnerSurface != null) ...[
            const SizedBox(height: 4),
            Text(
              runnerSurfaceLabel(l10n, workout.runnerSurface!),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
          if (cardio?.inclinePercent != null) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.runnerInclineLabel}: ${CardioFormat.incline(cardio!.inclinePercent)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ShareStatTile(
                  label: l10n.runnerDistance,
                  value: CardioFormat.distance(cardio?.distanceMeters, unitSystem),
                  accent: _runnerAccent,
                ),
              ),
              Expanded(
                child: _ShareStatTile(
                  label: l10n.runnerAvgPace,
                  value: CardioFormat.pace(workout.runnerAvgPaceSecPerKm, unitSystem),
                  accent: _runnerAccent,
                ),
              ),
              Expanded(
                child: _ShareStatTile(
                  label: l10n.runnerTime,
                  value: CardioFormat.duration(cardio?.durationSeconds),
                  accent: _runnerAccent,
                ),
              ),
            ],
          ),
          if (_isOutdoor) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _RouteMiniMap(points: points, accent: _runnerAccent),
            ),
          ],
          if (workout.runnerSplits.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(l10n.runnerSplitsTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            ...workout.runnerSplits.take(8).map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.runnerSplitKm(s.km), style: const TextStyle(fontSize: 13))),
                    Text(
                      CardioFormat.duration(s.seconds),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFeatures: [ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (summary.xpAward != null) ...[
            const SizedBox(height: 16),
            _ShareXpBanner(xpAward: summary.xpAward!, l10n: l10n, accent: _runnerAccent),
          ],
        ],
      ),
    );
  }
}

class _RouteMiniMap extends StatelessWidget {
  final List<LatLng> points;
  final Color accent;

  const _RouteMiniMap({required this.points, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();

    final bounds = LatLngBounds.fromPoints(points);

    return SizedBox(
      height: 120,
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(16),
          ),
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.fitforge.app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(points: points, strokeWidth: 3, color: accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _GymShareCard extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;
  final AppLocalizations l10n;

  const _GymShareCard({
    required this.summary,
    required this.unitSystem,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final records = l10n.brokenRecordLabels(
      isVolumeRecord: summary.isVolumeRecord,
      isRepsRecord: summary.isRepsRecord,
      isMaxWeightRecord: summary.isMaxWeightRecord,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardElevated, AppColors.card],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FitForgeLogo.icon(height: 28),
              const SizedBox(width: 8),
              const Text('FitForge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _GymHeroBanner(summary: summary, l10n: l10n),
          const SizedBox(height: 16),
          Text(
            l10n.workoutDisplayName(summary.workout.name),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.durationMinutesExercises(summary.durationMinutes, summary.exercises.length),
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ShareStatTile(
                  label: l10n.reps,
                  value: '${summary.totalReps}',
                  highlight: summary.isRepsRecord,
                ),
              ),
              Expanded(
                child: _ShareStatTile(
                  label: l10n.maxWeight,
                  value: summary.maxWeightKg != null
                      ? UnitConverter.formatMass(summary.maxWeightKg, unitSystem, decimals: 0)
                      : '—',
                  highlight: summary.isMaxWeightRecord,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ShareStatTile(
                  label: l10n.volume,
                  value: UnitConverter.formatVolume(summary.totalVolumeKg, unitSystem),
                  highlight: summary.isVolumeRecord,
                ),
              ),
              Expanded(
                child: _ShareStatTile(
                  label: l10n.caloriesBurned,
                  value: summary.hasCalorieEstimate
                      ? l10n.caloriesKcal(summary.calorieEstimate.caloriesKcal!)
                      : '—',
                ),
              ),
            ],
          ),
          if (summary.hasCalorieEstimate) ...[
            const SizedBox(height: 8),
            Text(
              summary.calorieEstimate.usedDefaultWeight
                  ? l10n.caloriesEstimateDefaultWeight
                  : l10n.caloriesEstimateNote,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
            ),
          ],
          if (records.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: records
                  .map(
                    (r) => Chip(
                      avatar: Icon(Icons.emoji_events, size: 16, color: context.accentColor),
                      label: Text(l10n.recordLabel(r)),
                      backgroundColor: context.accentColor.withValues(alpha: 0.15),
                      side: BorderSide(color: context.accentColor.withValues(alpha: 0.4)),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (summary.hasTrainedMuscles) ...[
            const SizedBox(height: 16),
            Text(l10n.summaryMusclesTrained, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: summary.trainedMuscleGroups
                  .map(
                    (muscle) => Chip(
                      label: Text(l10n.muscleLabel(muscle), style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.cardElevated,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (summary.hasNewPersonalRecords) ...[
            const SizedBox(height: 16),
            _SharePersonalRecordsSection(
              records: summary.newPersonalRecords,
              unitSystem: unitSystem,
              l10n: l10n,
            ),
          ],
          if (summary.hasAchievements) ...[
            const SizedBox(height: 16),
            _ShareAchievementsSection(summary: summary, l10n: l10n),
          ],
          if (summary.xpAward != null) ...[
            const SizedBox(height: 16),
            _ShareXpBanner(xpAward: summary.xpAward!, l10n: l10n, accent: context.accentColor),
          ],
        ],
      ),
    );
  }
}

class _ShareStatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? accent;

  const _ShareStatTile({
    required this.label,
    required this.value,
    this.highlight = false,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? (highlight ? context.accentColor : AppColors.textPrimary);
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        if (highlight && accent == null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.arrow_upward, size: 14, color: context.accentColor),
          ),
      ],
    );
  }
}

class _GymHeroBanner extends StatelessWidget {
  final WorkoutSummaryData summary;
  final AppLocalizations l10n;

  const _GymHeroBanner({required this.summary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final percent = summary.volumeImprovementPercent;
    final showCelebration =
        summary.hasNewPersonalRecords || summary.brokenRecords.isNotEmpty || summary.hasAchievements;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.accentColor.withValues(alpha: showCelebration ? 0.22 : 0.12),
            context.accentColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.accentColor.withValues(alpha: showCelebration ? 0.5 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Text(showCelebration ? '🎉' : '💪', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.summaryWorkoutComplete,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (percent != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.summaryVolumeUp(percent.toStringAsFixed(0)),
                    style: TextStyle(color: context.accentColor, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareXpBanner extends StatelessWidget {
  final XpAwardResult xpAward;
  final AppLocalizations l10n;
  final Color accent;

  const _ShareXpBanner({required this.xpAward, required this.l10n, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, color: accent, size: 22),
          const SizedBox(width: 8),
          Text(
            l10n.xpEarned(xpAward.xpEarned),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent),
          ),
        ],
      ),
    );
  }
}

class _ShareAchievementsSection extends StatelessWidget {
  final WorkoutSummaryData summary;
  final AppLocalizations l10n;

  const _ShareAchievementsSection({required this.summary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.accentColor.withValues(alpha: 0.18),
            context.accentColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.accentColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.celebration, color: context.accentColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.summaryAchievementsTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (summary.rankTierIncreased && summary.xpAward != null)
            _ShareAchievementRow(
              image: TappableBadge(
                label: l10n.playerLevelBadgeName(summary.xpAward!.after.level),
                child: _ShareLevelBadgeImage(level: summary.xpAward!.after.level),
              ),
              title: l10n.rankUp,
              subtitle: l10n.playerLevelRankSummary(summary.xpAward!.after.level),
            ),
          ...summary.newMilestoneUnlocks.map(
            (unlock) => _ShareAchievementRow(
              image: TappableBadge(
                label: l10n.milestoneTierName(unlock.tier),
                child: Image.asset(
                  MilestoneBadge.assetPathForTier(unlock.tier),
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.emoji_events, color: context.accentColor, size: 36),
                ),
              ),
              title: l10n.summaryMilestoneUnlocked,
              subtitle: l10n.summaryMilestoneDetail(
                MilestonesSection.categoryLabel(l10n, unlock.category),
                l10n.milestoneTierName(unlock.tier),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareAchievementRow extends StatelessWidget {
  final Widget image;
  final String title;
  final String subtitle;

  const _ShareAchievementRow({
    required this.image,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 48, height: 48, child: image),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareLevelBadgeImage extends StatelessWidget {
  final int level;

  const _ShareLevelBadgeImage({required this.level});

  @override
  Widget build(BuildContext context) {
    final asset = PlayerLevelBadge.assetForLevel(level);
    if (asset == null) {
      return Icon(Icons.military_tech, color: context.accentColor, size: 36);
    }
    return Image.asset(
      asset,
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.military_tech, color: context.accentColor, size: 36),
    );
  }
}

class _SharePersonalRecordsSection extends StatelessWidget {
  final List<PersonalRecord> records;
  final String unitSystem;
  final AppLocalizations l10n;

  const _SharePersonalRecordsSection({
    required this.records,
    required this.unitSystem,
    required this.l10n,
  });

  String _value(PersonalRecord pr) {
    switch (pr.recordType) {
      case PersonalRecordType.strength:
        return UnitConverter.formatSetLine(pr.weight ?? 0, pr.reps, unitSystem);
      case PersonalRecordType.cardioDistance:
        return CardioFormat.distance(pr.distanceMeters, unitSystem);
      case PersonalRecordType.cardioDuration:
        return CardioFormat.duration(pr.durationSeconds);
      case PersonalRecordType.cardioSteps:
        return CardioFormat.steps(pr.steps);
      case PersonalRecordType.cardioIncline:
        return CardioFormat.incline(pr.inclinePercent);
      case PersonalRecordType.cardioDifficulty:
        return CardioFormat.difficulty(pr.inclinePercent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, color: context.accentColor, size: 18),
            const SizedBox(width: 6),
            Text(l10n.summaryPersonalRecords, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        ...records.map(
          (pr) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: LocalizedExerciseName(
                    pr.exerciseName,
                    exerciseId: pr.exerciseId,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  _value(pr),
                  style: TextStyle(
                    color: context.accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
