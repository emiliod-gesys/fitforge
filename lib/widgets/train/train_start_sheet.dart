import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/routine.dart';
import '../../screens/workouts/workout_start_helper.dart';

Future<void> showTrainStartSheet(
  BuildContext context,
  WidgetRef ref, {
  required AsyncValue<List<Routine>> routinesAsync,
}) {
  final l10n = context.l10n;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.85;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.flash_on, color: AppColors.orange),
                  title: Text(l10n.freeWorkout),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await startWorkoutAndNavigate(
                      context,
                      ref,
                      name: l10n.freeWorkout,
                    );
                  },
                ),
                const Divider(height: 1),
                Flexible(
                  child: routinesAsync.when(
                    data: (routines) {
                      if (routines.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.noRoutines,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: routines.length,
                        itemBuilder: (context, index) {
                          final routine = routines[index];
                          return ListTile(
                            leading: const Icon(Icons.list_alt),
                            title: Text(routine.name),
                            subtitle: Text(l10n.exercisesInRoutine(routine.exercises.length)),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await startWorkoutFromRoutine(context, ref, routine);
                            },
                          );
                        },
                      );
                    },
                    loading: () => ListTile(title: Text(l10n.loadingRoutines)),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
