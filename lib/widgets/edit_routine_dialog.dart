import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_accent.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/exercise_load.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../providers/app_providers.dart';
import 'localized_exercise_name.dart';
import 'similar_exercise_picker_sheet.dart';

class EditRoutineDialog extends ConsumerStatefulWidget {
  final Routine routine;

  const EditRoutineDialog({super.key, required this.routine});

  static Future<Routine?> show(BuildContext context, Routine routine) {
    return showDialog<Routine>(
      context: context,
      builder: (_) => EditRoutineDialog(routine: routine),
    );
  }

  @override
  ConsumerState<EditRoutineDialog> createState() => _EditRoutineDialogState();
}

class _EditRoutineDialogState extends ConsumerState<EditRoutineDialog> {
  late final TextEditingController _nameController;
  late List<RoutineExercise> _exercises;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _exercises = List<RoutineExercise>.from(widget.routine.exercises);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _swapExercise(int index) async {
    final ex = _exercises[index];
    final excludeIds = _exercises
        .where((other) => other.id != ex.id)
        .map((other) => other.exerciseId)
        .toSet();
    final picked = await SimilarExercisePickerSheet.show(
      context,
      current: WorkoutExercise(
        id: ex.id,
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        imageUrl: ex.imageUrl,
        orderIndex: ex.orderIndex,
      ),
      excludeExerciseIds: excludeIds,
    );
    if (picked == null || !mounted) return;

    final catalog = ref.read(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final keepSets = !picked.isCardio && !ex.isCardio;
    final details = keepSets
        ? ex.resolvedSetDetails
        : picked.isCardio
            ? const <RoutineSetTarget>[]
            : List.generate(
                AppConstants.defaultSets,
                (_) => const RoutineSetTarget(reps: AppConstants.defaultReps),
              );

    setState(() {
      final next = List<RoutineExercise>.from(_exercises);
      next[index] = RoutineExercise(
        id: ex.id,
        exerciseId: picked.id,
        exerciseName: picked.name,
        orderIndex: ex.orderIndex,
        targetSets: details.isEmpty ? ex.targetSets : details.length,
        targetReps: details.isEmpty ? ex.targetReps : details.first.reps,
        targetWeight: details.isEmpty ? null : details.first.weight,
        restSeconds: ex.restSeconds,
        imageUrl: picked.isUserCustom ? null : picked.imageUrl,
        loggingType: picked.loggingType,
        targetDurationSeconds: picked.isCardio ? (ex.isCardio ? ex.targetDurationSeconds : 1200) : null,
        targetDistanceMeters: picked.isCardio ? (ex.isCardio ? ex.targetDistanceMeters : 3000) : null,
        targetInclinePercent: picked.isCardio ? ex.targetInclinePercent : null,
        targetSteps: picked.isCardio ? ex.targetSteps : null,
        perArmWeight: ExerciseLoad.resolvePerArmWeight(
          exerciseId: picked.id,
          catalog: catalog,
          exerciseName: picked.name,
        ),
        targetSetDetails: details,
        supersetGroupId: ex.supersetGroupId,
        supersetSlot: ex.supersetSlot,
      );
      _exercises = next;
    });
  }

  void _apply() {
    if (_exercises.isEmpty) return;

    Navigator.pop(
      context,
      Routine(
        id: widget.routine.id,
        userId: widget.routine.userId,
        name: _nameController.text.trim().isEmpty
            ? widget.routine.name
            : _nameController.text.trim(),
        description: widget.routine.description,
        targetMuscles: widget.routine.targetMuscles,
        exercises: _exercises
            .asMap()
            .entries
            .map((e) => e.value.copyWith(orderIndex: e.key))
            .toList(),
        createdAt: widget.routine.createdAt,
        updatedAt: widget.routine.updatedAt,
        isAiGenerated: widget.routine.isAiGenerated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listHeight = (_exercises.length * 64.0).clamp(64.0, 320.0);

    return AlertDialog(
      title: Text(l10n.editRoutine),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.routineName),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: listHeight,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _exercises.length,
                itemBuilder: (_, i) {
                  final ex = _exercises[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedExerciseName(
                                ex.exerciseName,
                                exerciseId: ex.exerciseId,
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                '${ex.targetSets}×${ex.targetReps}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.swapSimilar,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: Icon(Icons.swap_horiz, color: context.accentColor),
                          onPressed: () => _swapExercise(i),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                          onPressed: () {
                            setState(() {
                              _exercises = List<RoutineExercise>.from(_exercises)..removeAt(i);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: _exercises.isEmpty ? null : _apply,
          child: Text(l10n.apply),
        ),
      ],
    );
  }
}
