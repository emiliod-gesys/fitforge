import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/routine.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';

class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final routinesAsync = ref.watch(routinesProvider);

    return Scaffold(
      appBar: FitForgeAppBar(
        title: l10n.routinesTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.newRoutine,
            onPressed: () => context.push('/routines/new'),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: l10n.generateWithAi,
            onPressed: () => _showAiGenerator(context, ref),
          ),
        ],
      ),
      body: routinesAsync.when(
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/routines/new'),
                icon: const Icon(Icons.add),
                label: Text(l10n.newRoutine),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.orange,
                  side: const BorderSide(color: AppColors.orange),
                ),
              ),
              const SizedBox(height: 16),
              ...routines.map((routine) => _RoutineCard(routine: routine)),
            ],
          );
        },
        loading: () => const FitForgeLoadingScreen(),
        error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
      ),
    );
  }

  void _showAiGenerator(BuildContext context, WidgetRef ref) {
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
                final muscles = musclesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
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

                  if (routine != null) {
                    await ref.read(routineServiceProvider).createRoutine(routine);
                    ref.invalidate(routinesProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.routineGenerated)),
                      );
                    }
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
}

class _RoutineCard extends ConsumerWidget {
  final Routine routine;

  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: routine.isAiGenerated
              ? AppColors.orange.withValues(alpha: 0.15)
              : AppColors.slate.withValues(alpha: 0.4),
          child: Icon(routine.isAiGenerated ? Icons.auto_awesome_outlined : Icons.list_alt, color: AppColors.orange),
        ),
        title: Text(routine.name),
        subtitle: Text(
          '${l10n.exercisesInRoutine(routine.exercises.length)} · ${routine.targetMuscles.join(', ')}',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
            PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              context.push('/routines/${routine.id}/edit');
            } else if (value == 'delete') {
              await ref.read(routineServiceProvider).deleteRoutine(routine.id);
              ref.invalidate(routinesProvider);
            }
          },
        ),
        onTap: () => context.push('/routines/${routine.id}/edit'),
      ),
    );
  }
}
