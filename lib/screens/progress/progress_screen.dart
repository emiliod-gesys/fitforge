import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/muscle_inference.dart';
import '../../core/utils/player_level.dart';
import '../../core/utils/progress_stats.dart';
import '../../core/utils/progress_weekly_volume.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/exercise.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/progress/personal_record_card.dart';
import '../../widgets/progress/progress_body_snapshot.dart';
import '../../widgets/progress/progress_hero_card.dart';
import '../../widgets/progress/progress_milestones_carousel.dart';
import '../../widgets/progress/progress_muscle_filter_bar.dart';
import '../../widgets/progress/progress_stats_grid.dart';
import '../../widgets/progress/progress_trainer_card.dart';
import '../../widgets/progress/progress_volume_chart.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String? _muscleFilter;

  /// Categorías de filtro a las que pertenece un record (Cardio o grupos musculares).
  List<String> _categoriesFor(PersonalRecord pr, List<Exercise> catalog) {
    if (pr.isCardio) return const ['Cardio'];
    return MuscleInference.resolve(
      exerciseName: pr.exerciseName,
      exerciseId: pr.exerciseId,
      catalog: catalog,
    );
  }

  /// Grupos musculares con records, en el orden canónico.
  List<String> _availableMuscles(List<PersonalRecord> prs, List<Exercise> catalog) {
    final present = <String>{};
    for (final pr in prs) {
      present.addAll(_categoriesFor(pr, catalog));
    }
    return AppConstants.muscleGroups.where(present.contains).toList();
  }

  List<String> _muscleGroupsFor(PersonalRecord pr, List<Exercise> catalog) {
    return MuscleInference.resolve(
      exerciseName: pr.exerciseName,
      exerciseId: pr.exerciseId,
      catalog: catalog,
    );
  }

  int _monthlyPrCount(List<PersonalRecord> prs) {
    return ProgressStatsCalculator.prsThisMonth(prs);
  }

  bool _isRecentPr(PersonalRecord pr) {
    return pr.achievedAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prsAsync = ref.watch(personalRecordsProvider);
    final milestoneTotalsAsync = ref.watch(milestoneTotalsProvider);
    final profileAsync = ref.watch(profileProvider);
    final weeklyStatsAsync = ref.watch(workoutWeeklyStatsProvider);
    final workoutsAsync = ref.watch(workoutHistoryProvider);
    final bodyAsync = ref.watch(bodyMeasurementsProvider);
    final myTrainerAsync = ref.watch(myTrainerProvider);
    final unitSystem = ref.watch(unitSystemProvider);
    final catalog = ref.watch(exercisesProvider).valueOrNull ?? [];

    Future<void> onRefresh() async {
      HapticFeedback.lightImpact();
      ref.invalidate(personalRecordsProvider);
      ref.invalidate(milestoneTotalsProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(workoutWeeklyStatsProvider);
      ref.invalidate(workoutHistoryProvider);
      ref.invalidate(bodyMeasurementsProvider);
      ref.invalidate(myTrainerProvider);
    }

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.progressTitle),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            profileAsync.when(
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                final progress = PlayerLevelCalculator.fromTotalXp(profile.totalXp);
                return Column(
                  children: [
                    ProgressHeroCard(progress: progress, l10n: l10n),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const _HeroSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            myTrainerAsync.when(
              data: (trainerView) {
                if (trainerView == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    ProgressTrainerCard(trainerView: trainerView, l10n: l10n),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            weeklyStatsAsync.when(
              data: (stats) {
                final workouts = workoutsAsync.valueOrNull ?? const [];
                final prs = prsAsync.valueOrNull ?? const [];
                return ProgressStatsGrid(
                  l10n: l10n,
                  unitSystem: unitSystem,
                  monthlyWorkouts: ProgressStatsCalculator.workoutsThisMonth(workouts),
                  monthlyVolumeKg: ProgressStatsCalculator.volumeThisMonth(workouts),
                  monthlyPrCount: _monthlyPrCount(prs),
                  streakWeeks: stats.streakWeeks,
                );
              },
              loading: () => const _StatsSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            workoutsAsync.when(
              data: (workouts) => Column(
                children: [
                  ProgressVolumeChart(
                    buckets: ProgressWeeklyVolume.buckets(workouts),
                    l10n: l10n,
                    unitSystem: unitSystem,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              loading: () => const _ChartSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            bodyAsync.when(
              data: (measurements) {
                if (measurements.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    ProgressBodySnapshot(
                      measurements: measurements,
                      l10n: l10n,
                      unitSystem: unitSystem,
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            milestoneTotalsAsync.when(
              data: (totals) => Column(
                children: [
                  ProgressMilestonesCarousel(
                    totals: totals,
                    l10n: l10n,
                    unitSystem: unitSystem,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              loading: () => const _MilestonesSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            prsAsync.when(
              data: (prs) {
                if (prs.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.personalRecords, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Text(l10n.noRecordsYet),
                    ],
                  );
                }

                final available = _availableMuscles(prs, catalog);
                if (available.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.personalRecords, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Text(l10n.noRecordsYet),
                    ],
                  );
                }

                // Por defecto, el músculo del record más reciente.
                final mostRecent = [...prs]
                  ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
                final recentCats =
                    _categoriesFor(mostRecent.first, catalog).where(available.contains);
                final defaultMuscle =
                    recentCats.isNotEmpty ? recentCats.first : available.first;
                final selected = (_muscleFilter != null && available.contains(_muscleFilter))
                    ? _muscleFilter!
                    : defaultMuscle;

                final filtered = prs
                    .where((pr) => _categoriesFor(pr, catalog).contains(selected))
                    .toList()
                  ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.personalRecords, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ProgressMuscleFilterBar(
                      selectedMuscle: selected,
                      muscles: available,
                      onChanged: (value) => setState(() => _muscleFilter = value),
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      Text(l10n.noRecordsForMuscle(l10n.muscleLabel(selected)))
                    else
                      ...filtered.map(
                        (pr) => PersonalRecordCard(
                          record: pr,
                          unitSystem: unitSystem,
                          muscleGroups: _muscleGroupsFor(pr, catalog),
                          isRecent: _isRecentPr(pr),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const _PrListSkeleton(),
              error: (e, _) => Text(l10n.errorGeneric('$e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: AppColors.cardElevated,
        highlightColor: AppColors.card,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardElevated,
      highlightColor: AppColors.card,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: List.generate(
          4,
          (_) => Container(
            decoration: BoxDecoration(
              color: AppColors.cardElevated,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardElevated,
      highlightColor: AppColors.card,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _MilestonesSkeleton extends StatelessWidget {
  const _MilestonesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardElevated,
      highlightColor: AppColors.card,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _PrListSkeleton extends StatelessWidget {
  const _PrListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Shimmer.fromColors(
            baseColor: AppColors.cardElevated,
            highlightColor: AppColors.card,
            child: Container(
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
