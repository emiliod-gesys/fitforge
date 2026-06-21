import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cardio_format.dart';
import '../../core/utils/player_level.dart';
import '../../core/utils/player_level_badge.dart';
import '../../core/utils/milestone_badge.dart';
import '../../core/utils/unit_converter.dart';
import '../../core/utils/workout_summary_share.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/exercise_logging.dart';
import '../../models/profile.dart';
import '../../models/workout_summary.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_logo.dart';
import '../../widgets/localized_exercise_name.dart';
import '../../widgets/milestones_section.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final WorkoutSummaryData summary;

  const WorkoutSummaryScreen({super.key, required this.summary});

  @override
  ConsumerState<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  final _shareCardKey = GlobalKey();
  bool _sharing = false;

  WorkoutSummaryData get summary => widget.summary;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      final unit = ref.read(unitSystemProvider);
      final l10n = context.l10n;
      final displayName = l10n.workoutDisplayName(summary.workout.name);
      final text = WorkoutSummaryShare.formatText(l10n, summary, unit, displayName: displayName);

      final boundary =
          _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data != null && mounted) {
          final bytes = data.buffer.asUint8List();
          await Share.shareXFiles(
            [
              XFile.fromData(
                bytes,
                mimeType: 'image/png',
                name: 'fitforge-${summary.workout.name.replaceAll(' ', '-').toLowerCase()}.png',
              ),
            ],
            text: text,
            subject: displayName,
          );
          return;
        }
      }

      await Share.share(text, subject: displayName);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unit = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: FitForgeAppBar(
        title: l10n.summaryTitle,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _close,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                RepaintBoundary(
                  key: _shareCardKey,
                  child: _ShareCard(summary: summary, unitSystem: unit, l10n: l10n),
                ),
                const SizedBox(height: 20),
                if (summary.hasPreviousComparison) ...[
                  Text(
                    l10n.vsLastTime(l10n.workoutDisplayName(summary.previousSameRoutine!.name)),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _ComparisonSection(summary: summary, unitSystem: unit, l10n: l10n),
                  const SizedBox(height: 20),
                ],
                Text(
                  l10n.exercisesCompleted,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...summary.exercises.map(
                  (ex) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: LocalizedExerciseName(
                              ex.exerciseName,
                              exerciseId: ex.exerciseId,
                            ),
                          ),
                          if (ex.isNewPersonalRecord)
                            _PrBadge(label: l10n.summaryPersonalRecordBadge),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.bestWeightKg != null
                                ? l10n.setsRepsBest(
                                    ex.completedSets,
                                    ex.totalReps,
                                    UnitConverter.formatMass(ex.bestWeightKg, unit),
                                  )
                                : l10n.setsReps(ex.completedSets, ex.totalReps),
                          ),
                          if (ex.improvedBestWeight || ex.improvedVolume)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.summaryExerciseImproved,
                                style: const TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _close,
                      child: Text(l10n.close),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _sharing ? null : _share,
                      icon: _sharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.share_outlined),
                      label: Text(l10n.share),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;
  final AppLocalizations l10n;

  const _ShareCard({required this.summary, required this.unitSystem, required this.l10n});

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
              SizedBox(width: 8),
              Text('FitForge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _HeroBanner(summary: summary, l10n: l10n),
          const SizedBox(height: 16),
          Text(
            l10n.workoutDisplayName(summary.workout.name),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                child: _StatTile(
                  label: l10n.reps,
                  value: '${summary.totalReps}',
                  highlight: summary.isRepsRecord,
                ),
              ),
              Expanded(
                child: _StatTile(
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
                child: _StatTile(
                  label: l10n.volume,
                  value: UnitConverter.formatVolume(summary.totalVolumeKg, unitSystem),
                  highlight: summary.isVolumeRecord,
                ),
              ),
              Expanded(
                child: _StatTile(
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
                      avatar: Icon(Icons.emoji_events, size: 16, color: AppColors.orange),
                      label: Text(l10n.recordLabel(r)),
                      backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                      side: BorderSide(color: AppColors.orange.withValues(alpha: 0.4)),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (summary.hasTrainedMuscles) ...[
            const SizedBox(height: 16),
            Text(
              l10n.summaryMusclesTrained,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: summary.trainedMuscleGroups
                  .map(
                    (muscle) => Chip(
                      label: Text(
                        l10n.muscleLabel(muscle),
                        style: const TextStyle(fontSize: 12),
                      ),
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
            _PersonalRecordsSection(
              records: summary.newPersonalRecords,
              unitSystem: unitSystem,
              l10n: l10n,
            ),
          ],
          if (summary.hasAchievements) ...[
            const SizedBox(height: 16),
            _AchievementsSection(summary: summary, l10n: l10n),
          ],
          if (summary.xpAward != null) ...[
            const SizedBox(height: 16),
            _XpAwardBanner(xpAward: summary.xpAward!, l10n: l10n),
          ],
        ],
      ),
    );
  }
}

class _XpAwardBanner extends StatelessWidget {
  final XpAwardResult xpAward;
  final AppLocalizations l10n;

  const _XpAwardBanner({required this.xpAward, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.orange, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.xpEarned(xpAward.xpEarned),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          if (xpAward.streakWeeks > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.streakXpBonus(xpAward.streakMultiplier.toStringAsFixed(2)),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final WorkoutSummaryData summary;
  final AppLocalizations l10n;

  const _AchievementsSection({required this.summary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.18),
            AppColors.orange.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration, color: AppColors.orange, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.summaryAchievementsTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (summary.leveledUp && summary.xpAward != null)
            _AchievementRow(
              image: _LevelBadgeImage(level: summary.xpAward!.after.level),
              title: l10n.levelUp,
              subtitle: l10n.playerLevelTitle(summary.xpAward!.after.level),
            ),
          ...summary.newMilestoneUnlocks.map(
            (unlock) => _AchievementRow(
              image: Image.asset(
                MilestoneBadge.assetPathForTier(unlock.tier),
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.emoji_events,
                  color: AppColors.orange,
                  size: 36,
                ),
              ),
              title: l10n.summaryMilestoneUnlocked,
              subtitle: l10n.summaryMilestoneDetail(
                MilestonesSection.categoryLabel(l10n, unlock.category),
                unlock.tier,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final Widget image;
  final String title;
  final String subtitle;

  const _AchievementRow({
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
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadgeImage extends StatelessWidget {
  final int level;

  const _LevelBadgeImage({required this.level});

  @override
  Widget build(BuildContext context) {
    final asset = PlayerLevelBadge.assetForLevel(level);
    if (asset == null) {
      return const Icon(Icons.military_tech, color: AppColors.orange, size: 36);
    }
    return Image.asset(
      asset,
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.military_tech, color: AppColors.orange, size: 36),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.orange : AppColors.textPrimary,
          ),
        ),
        if (highlight)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.arrow_upward, size: 14, color: AppColors.orange),
          ),
      ],
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  final WorkoutSummaryData summary;
  final String unitSystem;
  final AppLocalizations l10n;

  const _ComparisonSection({required this.summary, required this.unitSystem, required this.l10n});

  Widget _row(String label, String current, String? previous, String? delta, bool isRecord) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(
            flex: 2,
            child: Text(current, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (previous != null)
            Expanded(
              flex: 2,
              child: Text(previous, style: TextStyle(color: AppColors.textMuted)),
            ),
          if (delta != null)
            Text(
              delta,
              style: TextStyle(
                color: isRecord ? AppColors.orange : AppColors.textMuted,
                fontWeight: isRecord ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  String? _delta(num? current, num? previous, {bool isWeight = false}) {
    if (current == null || previous == null) return null;
    final diff = current - previous;
    if (diff == 0) return '=';
    if (isWeight) {
      return UnitConverter.formatDelta(diff.toDouble(), unitSystem, decimals: 0);
    }
    final sign = diff > 0 ? '+' : '';
    return '$sign$diff';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(flex: 2, child: SizedBox()),
                Expanded(flex: 2, child: Text(l10n.today, style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                  flex: 2,
                  child: Text(l10n.before, style: TextStyle(color: AppColors.textMuted)),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const Divider(height: 16),
            _row(
              l10n.reps,
              '${summary.totalReps}',
              summary.previousTotalReps?.toString(),
              _delta(summary.totalReps, summary.previousTotalReps),
              summary.isRepsRecord,
            ),
            _row(
              l10n.maxWeight,
              summary.maxWeightKg != null
                  ? UnitConverter.formatMass(summary.maxWeightKg, unitSystem, decimals: 0)
                  : '—',
              summary.previousMaxWeightKg != null
                  ? UnitConverter.formatMass(summary.previousMaxWeightKg, unitSystem, decimals: 0)
                  : null,
              _delta(summary.maxWeightKg, summary.previousMaxWeightKg, isWeight: true),
              summary.isMaxWeightRecord,
            ),
            _row(
              l10n.volume,
              UnitConverter.formatVolume(summary.totalVolumeKg, unitSystem),
              summary.previousTotalVolumeKg != null
                  ? UnitConverter.formatVolume(summary.previousTotalVolumeKg!, unitSystem)
                  : null,
              _delta(summary.totalVolumeKg, summary.previousTotalVolumeKg, isWeight: true),
              summary.isVolumeRecord,
            ),
            _row(
              l10n.durationMin,
              '${summary.durationMinutes}',
              summary.previousDurationMinutes?.toString(),
              _delta(summary.durationMinutes, summary.previousDurationMinutes),
              false,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final WorkoutSummaryData summary;
  final AppLocalizations l10n;

  const _HeroBanner({required this.summary, required this.l10n});

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
            AppColors.orange.withValues(alpha: showCelebration ? 0.22 : 0.12),
            AppColors.orange.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: showCelebration ? 0.5 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Text(
            showCelebration ? '🎉' : '💪',
            style: const TextStyle(fontSize: 28),
          ),
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
                    style: const TextStyle(color: AppColors.orange, fontSize: 13),
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

class _PersonalRecordsSection extends StatelessWidget {
  final List<PersonalRecord> records;
  final String unitSystem;
  final AppLocalizations l10n;

  const _PersonalRecordsSection({
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
            const Icon(Icons.emoji_events, color: AppColors.orange, size: 18),
            const SizedBox(width: 6),
            Text(
              l10n.summaryPersonalRecords,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
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
                  style: const TextStyle(
                    color: AppColors.orange,
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

class _PrBadge extends StatelessWidget {
  final String label;

  const _PrBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.orange,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
