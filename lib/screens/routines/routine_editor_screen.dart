import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/unit_converter.dart';
import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../providers/app_providers.dart';
import '../../widgets/exercise_picker_sheet.dart';
import '../../widgets/fitforge_app_bar.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final String? routineId;

  const RoutineEditorScreen({super.key, this.routineId});

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<RoutineExercise> _exercises = [];
  final List<String> _targetMuscles = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.routineId != null) _loadRoutine();
    else _loading = false;
  }

  Future<void> _loadRoutine() async {
    final routines = await ref.read(routinesProvider.future);
    Routine? routine;
    for (final r in routines) {
      if (r.id == widget.routineId) {
        routine = r;
        break;
      }
    }
    if (routine != null) {
      _nameController.text = routine.name;
      _descController.text = routine.description ?? '';
      _exercises.addAll(routine.exercises);
      _targetMuscles.addAll(routine.targetMuscles);
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final routine = Routine(
      id: widget.routineId ?? '',
      userId: '',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      targetMuscles: _targetMuscles,
      exercises: _exercises,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.routineId != null) {
      await ref.read(routineServiceProvider).updateRoutine(routine.copyWithId(widget.routineId!));
    } else {
      await ref.read(routineServiceProvider).createRoutine(routine);
    }

    ref.invalidate(routinesProvider);
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _addExercise() async {
    final exercises = await ref.read(exercisesProvider.future);
    if (!mounted) return;

    final selectedIds = _exercises.map((e) => e.exerciseId).toSet();

    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, __) => ExercisePickerSheet(
          exercises: exercises,
          selectedExerciseIds: selectedIds,
        ),
      ),
    );

    if (selected != null) {
      final alreadyAdded = _exercises.any((e) => e.exerciseId == selected.id);
      if (alreadyAdded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${selected.name}" ya está en la rutina')),
          );
        }
        return;
      }

      setState(() {
        _exercises.add(RoutineExercise(
          id: const Uuid().v4(),
          exerciseId: selected.id,
          exerciseName: selected.name,
          orderIndex: _exercises.length,
          imageUrl: selected.imageUrl,
        ));
        for (final m in selected.muscles) {
          if (!_targetMuscles.contains(m)) _targetMuscles.add(m);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unitSystem = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: FitForgeAppBar(
        title: widget.routineId != null ? 'Editar' : 'Nueva rutina',
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre de la rutina'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Descripción'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: AppConstants.muscleGroups.map((m) {
              final selected = _targetMuscles.contains(m);
              return FilterChip(
                label: Text(m),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _targetMuscles.add(m);
                    } else {
                      _targetMuscles.remove(m);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ejercicios (${_exercises.length})', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('Añadir'),
              ),
            ],
          ),
          ..._exercises.asMap().entries.map((entry) {
            final i = entry.key;
            final ex = entry.value;
            return Card(
              child: ListTile(
                leading: ex.imageUrl != null
                    ? Image.network(ex.imageUrl!, width: 48, height: 48, fit: BoxFit.cover)
                    : const Icon(Icons.fitness_center),
                title: Text(ex.exerciseName),
                subtitle: Text(_exerciseSubtitle(ex, unitSystem)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _exercises.removeAt(i)),
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _exerciseSubtitle(RoutineExercise ex, String unitSystem) {
    final weightPart = ex.targetWeight != null
        ? ' · ${UnitConverter.formatMass(ex.targetWeight, unitSystem)}'
        : '';
    return '${ex.targetSets}×${ex.targetReps}$weightPart · ${ex.restSeconds}s descanso';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }
}

extension on Routine {
  Routine copyWithId(String id) => Routine(
        id: id,
        userId: userId,
        name: name,
        description: description,
        targetMuscles: targetMuscles,
        exercises: exercises,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isAiGenerated: isAiGenerated,
      );
}
