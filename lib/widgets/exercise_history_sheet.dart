import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/unit_converter.dart';
import '../core/utils/cardio_format.dart';
import '../core/utils/exercise_logging_resolver.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise_history.dart';
import '../providers/app_providers.dart';
import 'fitforge_loading_indicator.dart';

class ExerciseHistorySheet extends ConsumerWidget {
  final String exerciseId;
  final String exerciseName;
  final String? excludeWorkoutId;

  const ExerciseHistorySheet({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    this.excludeWorkoutId,
  });

  static void show(
    BuildContext context, {
    required String exerciseId,
    required String exerciseName,
    String? excludeWorkoutId,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.55,
            child: ExerciseHistorySheet(
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              excludeWorkoutId: excludeWorkoutId,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unitSystem = ref.watch(unitSystemProvider);
    final locale = Localizations.localeOf(context).toString();
    final historyAsync = ref.watch(
      exerciseHistoryProvider(
        ExerciseHistoryQuery(exerciseId: exerciseId, excludeWorkoutId: excludeWorkoutId),
      ),
    );

    return Material(
      color: AppColors.card,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.historyTitle, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        exerciseName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: historyAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.noExerciseHistory,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final session = sessions[i];
                    final date = DateFormat('dd MMM yyyy', locale).format(session.date.toLocal());

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(date, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              session.workoutName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 10),
                            ...session.sets.map(
                              (set) {
                                final catalog = ref.watch(exercisesProvider).valueOrNull ?? [];
                                final isCardio = set.isCardio ||
                                    ExerciseLoggingResolver.isCardioExercise(
                                      exerciseId: exerciseId,
                                      exerciseName: exerciseName,
                                      catalog: catalog,
                                      sets: [set],
                                    );
                                final line = isCardio
                                    ? CardioFormat.setSummary(
                                        config: ExerciseLoggingResolver.cardioConfigFor(
                                          exerciseId: exerciseId,
                                          exerciseName: exerciseName,
                                          catalog: catalog,
                                        ),
                                        unitSystem: unitSystem,
                                        durationSeconds: set.durationSeconds,
                                        distanceMeters: set.distanceMeters,
                                        inclinePercent: set.inclinePercent,
                                        stepCount: set.steps,
                                      )
                                    : (set.weight != null
                                        ? UnitConverter.formatSetLine(set.weight!, set.reps, unitSystem)
                                        : l10n.repsOnly(set.reps));
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    l10n.setLine(set.setNumber, line),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => FitForgeLoadingScreen(message: l10n.loadingHistory),
              error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
            ),
          ),
        ],
      ),
    );
  }
}
