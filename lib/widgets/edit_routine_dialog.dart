import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../models/routine.dart';
import '../providers/app_providers.dart';
import 'localized_exercise_name.dart';
import 'localized_exercise_name.dart';

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
            .map(
              (e) => RoutineExercise(
                id: e.value.id,
                exerciseId: e.value.exerciseId,
                exerciseName: e.value.exerciseName,
                orderIndex: e.key,
                targetSets: e.value.targetSets,
                targetReps: e.value.targetReps,
                targetWeight: e.value.targetWeight,
                restSeconds: e.value.restSeconds,
                imageUrl: e.value.imageUrl,
              ),
            )
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
    final listHeight = (_exercises.length * 56.0).clamp(56.0, 280.0);

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
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: LocalizedExerciseName(
                      ex.exerciseName,
                      exerciseId: ex.exerciseId,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text('${ex.targetSets}×${ex.targetReps}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                      onPressed: () {
                        setState(() {
                          _exercises = List.from(_exercises)..removeAt(i);
                        });
                      },
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
