import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/routine.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';

class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);

    return Scaffold(
      appBar: FitForgeAppBar(
        title: 'Rutinas',
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Generar con IA',
            onPressed: () => _showAiGenerator(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/routines/new'),
        child: const Icon(Icons.add),
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
                  const Text('Sin rutinas creadas'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/routines/new'),
                    child: const Text('Crear rutina'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routines.length,
            itemBuilder: (_, i) => _RoutineCard(routine: routines[i]),
          );
        },
        loading: () => const FitForgeLoadingScreen(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAiGenerator(BuildContext context, WidgetRef ref) {
    final musclesController = TextEditingController();
    var duration = 45;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Generar rutina con IA'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: musclesController,
                decoration: const InputDecoration(
                  labelText: 'Músculos (ej: Pecho, Tríceps)',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: duration,
                decoration: const InputDecoration(labelText: 'Duración (min)'),
                items: [30, 45, 60, 90]
                    .map((d) => DropdownMenuItem(value: d, child: Text('$d min')))
                    .toList(),
                onChanged: (v) => setState(() => duration = v ?? 45),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final muscles = musclesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                final profile = await ref.read(profileProvider.future);
                final workouts = await ref.read(workoutsProvider.future);

                if (!context.mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const FitForgeLoadingScreen(message: 'Generando rutina…'),
                );

                try {
                  final routine = await ref.read(aiCoachServiceProvider).generateRoutine(
                        targetMuscles: muscles.isEmpty ? ['Pecho', 'Espalda'] : muscles,
                        durationMinutes: duration,
                        profile: profile,
                        recentWorkouts: workouts,
                      );

                  if (context.mounted) Navigator.pop(context);

                  if (routine != null) {
                    await ref.read(routineServiceProvider).createRoutine(routine);
                    ref.invalidate(routinesProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rutina generada y guardada')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Generar'),
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
          '${routine.exercises.length} ejercicios · ${routine.targetMuscles.join(', ')}',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
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
