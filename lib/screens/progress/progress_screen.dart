import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/muscle_inference.dart';
import '../../core/utils/player_level.dart';
import '../../core/utils/progress_stats.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/localized_exercise_name.dart';
import '../../widgets/player_level_card.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String? _muscleFilter;

  List<Workout> _workoutsLast30Days(List<Workout> workouts) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return workouts
        .where((w) => w.completedAt != null && w.completedAt!.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
  }

  bool _matchesMuscleFilter(PersonalRecord pr) {
    if (_muscleFilter == null) return true;
    return MuscleInference.resolve(exerciseName: pr.exerciseName).contains(_muscleFilter);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prsAsync = ref.watch(personalRecordsProvider);
    final workoutsAsync = ref.watch(progressWorkoutsProvider);
    final profileAsync = ref.watch(profileProvider);
    final bodyMetricsAsync = ref.watch(bodyMetricSnapshotsProvider);
    final unitSystem = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.progressTitle),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(personalRecordsProvider);
          ref.invalidate(progressWorkoutsProvider);
          ref.invalidate(profileProvider);
          ref.invalidate(bodyMetricSnapshotsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            profileAsync.when(
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                final progress = PlayerLevelCalculator.fromTotalXp(profile.totalXp);
                return Column(
                  children: [
                    PlayerLevelCard(progress: progress, l10n: l10n),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: FitForgeLoadingIndicator(size: 48),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            workoutsAsync.when(
              data: (workouts) {
                final profile = profileAsync.valueOrNull;
                final bodyMetrics = bodyMetricsAsync.valueOrNull;
                final stats = ProgressStatsCalculator.compute(
                  workouts,
                  profile: profile,
                  bodyMetrics: bodyMetrics,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.progressLast7Days,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(l10n.progressWorkoutsLabel, '${stats.workouts7d}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            l10n.progressVolumeLabel,
                            UnitConverter.formatVolume(stats.volume7dKg, unitSystem),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            l10n.progressCaloriesLabel,
                            l10n.caloriesKcal(stats.calories7d),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.progressAllTime,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(l10n.progressWorkoutsLabel, '${stats.workoutsTotal}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            l10n.progressVolumeLabel,
                            UnitConverter.formatVolume(stats.volumeTotalKg, unitSystem),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            l10n.progressCaloriesLabel,
                            l10n.caloriesKcal(stats.caloriesTotal),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: FitForgeLoadingIndicator(size: 48),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text(l10n.volumePerWorkout, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.last30Days,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            workoutsAsync.when(
              data: (workouts) {
                final last30 = _workoutsLast30Days(workouts);
                if (last30.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(l10n.completeWorkoutsForVolume),
                      ),
                    ),
                  );
                }
                return _VolumeChart(workouts: last30, unitSystem: unitSystem);
              },
              loading: () => const FitForgeLoadingIndicator(size: 80),
              error: (e, _) => Text(l10n.errorGeneric(e.toString())),
            ),
            const SizedBox(height: 24),
            Text(l10n.personalRecords, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.all),
                      selected: _muscleFilter == null,
                      onSelected: (_) => setState(() => _muscleFilter = null),
                    ),
                  ),
                  ...AppConstants.muscleGroups
                      .where((m) => m != 'Cardio')
                      .map(
                        (muscle) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(l10n.muscleLabel(muscle)),
                            selected: _muscleFilter == muscle,
                            onSelected: (_) => setState(() => _muscleFilter = muscle),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            prsAsync.when(
              data: (prs) {
                final filtered = prs.where(_matchesMuscleFilter).toList();
                if (filtered.isEmpty) {
                  return Text(
                    _muscleFilter == null
                        ? l10n.noRecordsYet
                        : l10n.noRecordsForMuscle(l10n.muscleLabel(_muscleFilter!)),
                  );
                }
                return Column(
                  children: filtered.map((pr) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.emoji_events, color: Colors.amber),
                        title: LocalizedExerciseName(
                          pr.exerciseName,
                          exerciseId: pr.exerciseId,
                        ),
                        subtitle: Text(UnitConverter.formatSetLine(pr.weight, pr.reps, unitSystem)),
                        trailing: Text(
                          '${l10n.oneRm}: ${UnitConverter.formatMass(pr.oneRepMax, unitSystem)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const FitForgeLoadingIndicator(size: 80),
              error: (e, _) => Text(l10n.errorGeneric(e.toString())),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeChart extends StatelessWidget {
  final List<Workout> workouts;
  final String unitSystem;

  const _VolumeChart({required this.workouts, required this.unitSystem});

  @override
  Widget build(BuildContext context) {
    final volumes = workouts
        .map((w) => UnitConverter.kgToDisplay(w.totalVolume, unitSystem))
        .toList();
    final maxVolume = volumes.reduce((a, b) => a > b ? a : b);
    final chartMax = maxVolume <= 0 ? 1.0 : maxVolume * 1.15;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: chartMax / 4,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: chartMax / 4,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > chartMax) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= workouts.length) return const SizedBox.shrink();
                      if (workouts.length > 8 && i.isOdd) return const SizedBox.shrink();
                      final date = workouts[i].completedAt!.toLocal();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('d/M').format(date),
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(workouts.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: volumes[i],
                      width: workouts.length > 15 ? 8 : 14,
                      color: AppColors.orange,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
