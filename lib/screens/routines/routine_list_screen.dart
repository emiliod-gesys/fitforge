import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/runner/runner_standards.dart';
import '../../core/subscription/routine_limit_gate.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/routine.dart';
import '../../providers/app_providers.dart';
import '../../services/routine_service.dart';
import '../../widgets/ai_routine_preview_card.dart';
import '../../widgets/edit_routine_dialog.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/routine_share_friend_sheet.dart';
import '../workouts/workout_start_helper.dart';
import '../../core/theme/app_accent.dart';

abstract final class RoutineListActions {
  static void showAiGenerator(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final musclesController = TextEditingController();
    var duration = 45;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.generateAiRoutineTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: musclesController,
                decoration: InputDecoration(labelText: l10n.targetMuscles),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: duration,
                decoration: InputDecoration(labelText: l10n.durationMin),
                items: [30, 45, 60, 90]
                    .map((d) => DropdownMenuItem(value: d, child: Text(l10n.minSuffix(d))))
                    .toList(),
                onChanged: (v) => setState(() => duration = v ?? 45),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final muscles = musclesController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                final profile = await ref.read(profileProvider.future);
                final workouts = await ref.read(workoutsProvider.future);
                final effectiveMuscles = muscles.isEmpty ? ['Pecho', 'Espalda'] : muscles;
                final lang = ref.read(preferredLanguageProvider);
                final exerciseService = ref.read(exerciseServiceProvider);
                exerciseService.configure(language: lang);
                final catalog = await exerciseService.fetchAiCoachCatalog(
                  targetMuscles: effectiveMuscles,
                );
                final bodyMetrics = await ref.read(bodyMetricSnapshotsProvider.future);
                final weeklyStats = await ref.read(workoutWeeklyStatsProvider.future);
                final personalRecords = await ref.read(personalRecordsProvider.future);
                final routines = await ref.read(routinesProvider.future);
                final nutrition = await ref.read(coachNutritionServiceProvider).load(
                      profile: profile,
                      bodyMetrics: bodyMetrics,
                    );

                if (!context.mounted) return;

                final usageService = ref.read(coachUsageServiceProvider);
                final profileService = ref.read(profileServiceProvider);
                final canSend = await usageService.canSendMessage(profile, profileService);
                if (!canSend) {
                  if (!context.mounted) return;
                  final status = await usageService.getStatus(profile, profileService);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.coachDailyLimitReached(status.limit ?? 0)),
                    ),
                  );
                  return;
                }

                try {
                  final routine = await FitForgeLoadingOverlay.run(
                    context,
                    message: l10n.generatingRoutine,
                    task: () => ref.read(aiCoachServiceProvider).generateRoutine(
                          targetMuscles: effectiveMuscles,
                          durationMinutes: duration,
                          profile: profile,
                          recentWorkouts: workouts,
                          catalog: catalog,
                          bodyMetrics: bodyMetrics,
                          weeklyStats: weeklyStats,
                          personalRecords: personalRecords,
                          routines: routines,
                          nutrition: nutrition,
                        ),
                  );

                  if (routine != null && context.mounted) {
                    await usageService.recordMessage();
                    ref.invalidate(coachUsageStatusProvider);
                    await showRoutinePreview(context, ref, routine);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.errorGeneric('$e'))),
                    );
                  }
                }
              },
              child: Text(l10n.generate),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showRoutinePreview(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) async {
    final l10n = context.l10n;
    var preview = routine;
    var isSaved = false;
    var isDiscarded = false;
    var isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (isSaved || isDiscarded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ctx.mounted) Navigator.pop(ctx);
            });
          }

          return AlertDialog(
            title: Text(l10n.generateAiRoutineTitle),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Consumer(
                  builder: (_, ref, __) => AiRoutinePreviewCard(
                    routine: preview,
                    isSaved: isSaved,
                    isDiscarded: isDiscarded,
                    isSaving: isSaving,
                    onSave: () async {
                      if (isSaving) return;
                      final canCreate = await ensureCanCreateRoutine(context, ref);
                      if (!canCreate) return;
                      setDialogState(() => isSaving = true);
                      try {
                        await ref.read(routineServiceProvider).createRoutine(preview);
                        ref.invalidate(routinesProvider);
                        ref.invalidate(routineLimitStatusProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.routineSavedNamed(preview.name))),
                          );
                        }
                        setDialogState(() => isSaved = true);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          showRoutineSaveErrorSnackBar(context, e);
                        }
                      }
                    },
                    onEdit: () async {
                      final updated = await EditRoutineDialog.show(context, preview);
                      if (updated != null) {
                        setDialogState(() => preview = updated);
                      }
                    },
                    onDiscard: () => setDialogState(() => isDiscarded = true),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RoutinesTab extends ConsumerWidget {
  const RoutinesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final routinesAsync = ref.watch(routinesProvider);
    final limitAsync = ref.watch(routineLimitStatusProvider);

    return routinesAsync.when(
      data: (routines) {
        final limitStatus = limitAsync.valueOrNull;
        final atLimit = limitStatus != null && !limitStatus.canCreate;

        if (routines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.list_alt, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(l10n.noRoutines),
                if (limitStatus != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.routineLimitUsage(limitStatus.used, limitStatus.limit),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: atLimit
                      ? null
                      : () async {
                          if (await ensureCanCreateRoutine(context, ref)) {
                            if (context.mounted) context.push('/routines/new');
                          }
                        },
                  child: Text(l10n.createRoutine),
                ),
              ],
            ),
          );
        }
        final sorted = [...routines]..sort((a, b) {
            final aSystem = a.isHyroxSystem || a.isRunnerSystem;
            final bSystem = b.isHyroxSystem || b.isRunnerSystem;
            if (aSystem != bSystem) return aSystem ? -1 : 1;
            if (a.isHyroxSystem && b.isHyroxSystem) {
              final ao = a.hyroxLevel?.index ?? 0;
              final bo = b.hyroxLevel?.index ?? 0;
              return ao.compareTo(bo);
            }
            if (a.isRunnerSystem && b.isRunnerSystem) {
              final ao = a.runnerType?.index ?? 0;
              final bo = b.runnerType?.index ?? 0;
              return ao.compareTo(bo);
            }
            if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });
        final favoriteCount = sorted.where((r) => r.isFavorite).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            if (limitStatus != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.routineLimitUsage(limitStatus.used, limitStatus.limit),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            OutlinedButton.icon(
              onPressed: atLimit
                  ? null
                  : () async {
                      if (await ensureCanCreateRoutine(context, ref)) {
                        if (context.mounted) context.push('/routines/new');
                      }
                    },
              icon: const Icon(Icons.add),
              label: Text(l10n.newRoutine),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(48),
                foregroundColor: context.accentColor,
                side: BorderSide(color: context.accentColor),
              ),
            ),
            const SizedBox(height: 16),
            ...sorted.map((routine) => _RoutineCard(
                  routine: routine,
                  favoriteCount: favoriteCount,
                )),
          ],
        );
      },
      loading: () => const FitForgeLoadingScreen(),
      error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  final Routine routine;
  final int favoriteCount;

  const _RoutineCard({
    required this.routine,
    required this.favoriteCount,
  });

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final next = !routine.isFavorite;
    if (next && favoriteCount >= RoutineService.maxFavoriteRoutines) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.routineFavoritesMax(RoutineService.maxFavoriteRoutines))),
      );
      return;
    }

    try {
      await ref.read(routineServiceProvider).setRoutineFavorite(routine.id, next);
      ref.invalidate(routinesProvider);
      ref.invalidate(friendFavoriteRoutinesProvider);
    } catch (e) {
      if (context.mounted) {
        final message = '$e'.contains('Maximum of 5')
            ? l10n.routineFavoritesMax(RoutineService.maxFavoriteRoutines)
            : l10n.saveFailed('$e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isHyrox = routine.isHyroxSystem;
    final isRunner = routine.isRunnerSystem;

    if (isHyrox || isRunner) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: context.accentColor.withValues(alpha: 0.2),
                    child: Icon(Icons.directions_run, color: context.accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                l10n.routineDisplayName(routine),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isHyrox ? l10n.hyroxSystemBadge : l10n.runnerSystemBadge,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.routineDisplaySubtitle(routine) ??
                              l10n.exercisesInRoutine(routine.exercises.length),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    tooltip: isHyrox ? l10n.hyroxSystemLocked : l10n.runnerSystemLocked,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isHyrox ? l10n.hyroxSystemLocked : l10n.runnerSystemLocked,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => isRunner
                      ? startRunnerWorkoutFromRoutine(context, ref, routine)
                      : startWorkoutFromRoutine(context, ref, routine),
                  icon: const Icon(Icons.play_arrow, size: 26),
                  label: Text(
                    isRunner
                        ? (routine.runnerType == RunnerType.outdoor
                            ? l10n.runnerStartOutdoor
                            : l10n.runnerStartTreadmill)
                        : l10n.hyroxStartRace,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: context.accentColor,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isHyrox
              ? context.accentColor.withValues(alpha: 0.2)
              : routine.isAiGenerated
                  ? context.accentColor.withValues(alpha: 0.15)
                  : AppColors.slate.withValues(alpha: 0.4),
          child: Icon(
            isHyrox
                ? Icons.directions_run
                : routine.isAiGenerated
                    ? Icons.auto_awesome_outlined
                    : Icons.list_alt,
            color: context.accentColor,
          ),
        ),
        title: Row(
          children: [
            Flexible(child: Text(l10n.routineDisplayName(routine))),
            if (isHyrox) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.hyroxSystemBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.accentColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          isHyrox
              ? (l10n.routineDisplaySubtitle(routine) ??
                  l10n.exercisesInRoutine(routine.exercises.length))
              : '${l10n.exercisesInRoutine(routine.exercises.length)} · ${routine.targetMuscles.join(', ')}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isHyrox)
              IconButton(
                icon: Icon(
                  routine.isFavorite ? Icons.star : Icons.star_border,
                  color: routine.isFavorite ? context.accentColor : AppColors.textMuted,
                ),
                tooltip: routine.isFavorite ? l10n.routineUnfavorite : l10n.routineFavorite,
                onPressed: () => _toggleFavorite(context, ref),
              ),
            IconButton(
              icon: Icon(Icons.play_arrow),
              tooltip: l10n.startWorkout,
              color: context.accentColor,
              onPressed: () => startWorkoutFromRoutine(context, ref, routine),
            ),
            if (!isHyrox)
              PopupMenuButton(
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  PopupMenuItem(value: 'share', child: Text(l10n.share)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
                onSelected: (value) async {
                  if (value == 'edit') {
                    context.push('/routines/${routine.id}/edit');
                  } else if (value == 'share') {
                    await RoutineShareFriendSheet.show(context, routine);
                  } else if (value == 'delete') {
                    await ref.read(routineServiceProvider).deleteRoutine(routine.id);
                    ref.invalidate(routinesProvider);
                    ref.invalidate(friendFavoriteRoutinesProvider);
                  }
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: l10n.hyroxSystemLocked,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.hyroxSystemLocked)),
                  );
                },
              ),
          ],
        ),
        onTap: isHyrox
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.hyroxSystemLocked)),
                );
              }
            : () => context.push('/routines/${routine.id}/edit'),
      ),
    );
  }
}
