import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                final catalog = await ref.read(exercisesProvider.future);
                final bodyMetrics = await ref.read(bodyMetricSnapshotsProvider.future);
                final weeklyStats = await ref.read(workoutWeeklyStatsProvider.future);
                final personalRecords = await ref.read(personalRecordsProvider.future);
                final routines = await ref.read(routinesProvider.future);

                if (!context.mounted) return;

                try {
                  final routine = await FitForgeLoadingOverlay.run(
                    context,
                    message: l10n.generatingRoutine,
                    task: () => ref.read(aiCoachServiceProvider).generateRoutine(
                          targetMuscles: muscles.isEmpty ? ['Pecho', 'Espalda'] : muscles,
                          durationMinutes: duration,
                          profile: profile,
                          recentWorkouts: workouts,
                          catalog: catalog,
                          bodyMetrics: bodyMetrics,
                          weeklyStats: weeklyStats,
                          personalRecords: personalRecords,
                          routines: routines,
                        ),
                  );

                  if (routine != null && context.mounted) {
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
                      setDialogState(() => isSaving = true);
                      try {
                        await ref.read(routineServiceProvider).createRoutine(preview);
                        ref.invalidate(routinesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.routineSavedNamed(preview.name))),
                          );
                        }
                        setDialogState(() => isSaved = true);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.saveFailed('$e'))),
                          );
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

    return routinesAsync.when(
      data: (routines) {
        if (routines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.list_alt, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(l10n.noRoutines),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/routines/new'),
                  child: Text(l10n.createRoutine),
                ),
              ],
            ),
          );
        }
        final sorted = [...routines]..sort((a, b) {
            if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });
        final favoriteCount = sorted.where((r) => r.isFavorite).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            OutlinedButton.icon(
              onPressed: () => context.push('/routines/new'),
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

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: routine.isAiGenerated
              ? context.accentColor.withValues(alpha: 0.15)
              : AppColors.slate.withValues(alpha: 0.4),
          child: Icon(
            routine.isAiGenerated ? Icons.auto_awesome_outlined : Icons.list_alt,
            color: context.accentColor,
          ),
        ),
        title: Text(routine.name),
        subtitle: Text(
          '${l10n.exercisesInRoutine(routine.exercises.length)} · ${routine.targetMuscles.join(', ')}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            ),
          ],
        ),
        onTap: () => context.push('/routines/${routine.id}/edit'),
      ),
    );
  }
}
