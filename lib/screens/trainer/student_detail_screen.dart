import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/workout_muscle_groups.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/exercise.dart';
import '../../models/profile.dart';
import '../../models/workout.dart';
import '../../models/workout_summary.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/muscle_recovery_map.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/social/social_section_header.dart';
import '../../widgets/food/food_week_strip.dart';
import '../../widgets/trainer/student_nutrition_summary_card.dart';
import '../../widgets/trainer/student_routines_section.dart';
import '../../widgets/workout_tile.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  static const previewWorkoutCount = 5;

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> {
  bool _showAllWorkouts = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileAsync = ref.watch(studentProfileProvider(widget.studentId));
    final workoutsAsync = ref.watch(studentWorkoutHistoryProvider(widget.studentId));
    final recoveryAsync = ref.watch(studentRecoveryProvider(widget.studentId));
    final nutritionAsync = ref.watch(studentDailyNutritionProvider(widget.studentId));
    final nutritionDay = ref.watch(studentNutritionDayProvider(widget.studentId));
    final catalogAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.studentDetailTitle),
      body: profileAsync.when(
        loading: () => const Center(child: FitForgeLoadingIndicator(size: 48)),
        error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
        data: (view) {
          if (view == null) {
            return Center(child: Text(l10n.studentNotFound));
          }

          final unitSystem = view.profile.unitSystem;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _showAllWorkouts = false);
              ref.invalidate(studentProfileProvider(widget.studentId));
              ref.invalidate(studentWorkoutHistoryProvider(widget.studentId));
              ref.invalidate(studentRecoveryProvider(widget.studentId));
              ref.invalidate(studentRoutinesProvider(widget.studentId));
              ref.invalidate(studentDailyNutritionProvider(widget.studentId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      ProfileAvatar(
                        avatarUrl: view.user.avatarUrl,
                        radius: 40,
                        fallbackLetter: view.user.label,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        view.user.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        l10n.playerLevelRankSummary(view.user.level),
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SocialSectionHeader(title: l10n.studentRecoveryTitle),
                recoveryAsync.when(
                  loading: () => MuscleRecoveryMap(
                    recovery: fullMuscleRecoveryMap(),
                    compact: true,
                    isLoading: true,
                    gender: view.profile.gender,
                  ),
                  error: (_, __) => MuscleRecoveryMap(
                    recovery: fullMuscleRecoveryMap(),
                    compact: true,
                    gender: view.profile.gender,
                  ),
                  data: (recovery) => MuscleRecoveryMap(
                    recovery: recovery,
                    compact: true,
                    gender: view.profile.gender,
                  ),
                ),
                const SizedBox(height: 20),
                FoodWeekStrip(
                  selectedDay: nutritionDay,
                  onChanged: (day) =>
                      ref.read(studentNutritionDayProvider(widget.studentId).notifier).state = day,
                ),
                const SizedBox(height: 12),
                nutritionAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: FitForgeLoadingIndicator(size: 28)),
                  ),
                  error: (e, _) => Text(l10n.errorGeneric('$e')),
                  data: (summary) => StudentNutritionSummaryCard(
                    summary: summary,
                    day: nutritionDay,
                    l10n: l10n,
                  ),
                ),
                const SizedBox(height: 20),
                SocialSectionHeader(title: l10n.studentRoutinesTitle),
                StudentRoutinesSection(studentId: widget.studentId, l10n: l10n),
                const SizedBox(height: 20),
                SocialSectionHeader(title: l10n.studentWorkoutsTitle),
                workoutsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: FitForgeLoadingIndicator(size: 36)),
                  ),
                  error: (e, _) => Text(l10n.errorGeneric('$e')),
                  data: (workouts) => _StudentWorkoutsSection(
                    workouts: workouts,
                    showAll: _showAllWorkouts,
                    unitSystem: unitSystem,
                    catalog: catalogAsync.valueOrNull ?? const [],
                    l10n: l10n,
                    onShowMore: () => setState(() => _showAllWorkouts = true),
                    onWorkoutTap: (workoutId) =>
                        _openWorkoutSummary(context, ref, workoutId, view.profile),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openWorkoutSummary(
    BuildContext context,
    WidgetRef ref,
    String workoutId,
    UserProfile profile,
  ) async {
    final workout = await ref.read(workoutServiceProvider).getCompletedWorkoutById(workoutId);
    if (workout == null || !context.mounted) return;

    final catalog = await ref.read(exercisesProvider.future);
    final summary = WorkoutSummaryBuilder.build(
      workout: workout,
      durationMinutes: workout.durationMinutes,
      exerciseCatalog: catalog,
      profile: profile,
    );

    if (!context.mounted) return;
    ref.read(pendingWorkoutSummaryProvider.notifier).state = summary;
    context.push('/workout/summary', extra: summary);
  }
}

class _StudentWorkoutsSection extends StatelessWidget {
  final List<Workout> workouts;
  final bool showAll;
  final String unitSystem;
  final List<Exercise> catalog;
  final AppLocalizations l10n;
  final VoidCallback onShowMore;
  final void Function(String workoutId) onWorkoutTap;

  const _StudentWorkoutsSection({
    required this.workouts,
    required this.showAll,
    required this.unitSystem,
    required this.catalog,
    required this.l10n,
    required this.onShowMore,
    required this.onWorkoutTap,
  });

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return Text(
        l10n.studentWorkoutsEmpty,
        style: const TextStyle(color: AppColors.textMuted),
      );
    }

    const previewCount = StudentDetailScreen.previewWorkoutCount;
    final visible = showAll ? workouts : workouts.take(previewCount).toList();
    final hasMore = !showAll && workouts.length > previewCount;

    return Column(
      children: [
        ...visible.map((workout) {
          final muscles = trainedMuscleGroupsForWorkout(workout, catalog);
          return WorkoutTile(
            workout: workout,
            unitSystem: unitSystem,
            muscleGroups: muscles,
            onTap: () => onWorkoutTap(workout.id),
          );
        }),
        if (hasMore)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: onShowMore,
              child: Text(l10n.leaderboardLoadMore),
            ),
          ),
      ],
    );
  }
}
