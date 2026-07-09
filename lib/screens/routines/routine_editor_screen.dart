import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/subscription/routine_limit_gate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/exercise_load.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../providers/app_providers.dart';
import '../../widgets/exercise_picker_sheet.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/localized_exercise_name.dart';
import '../../widgets/routine_exercise_target_fields.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final String? routineId;
  final String? studentId;

  const RoutineEditorScreen({super.key, this.routineId, this.studentId});

  bool get isStudentRoutine => studentId != null && studentId!.isNotEmpty;

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
    Routine? routine;
    if (widget.isStudentRoutine) {
      routine = await ref.read(routineServiceProvider).getRoutineById(
            widget.routineId!,
            forStudentId: widget.studentId,
          );
    } else {
      final routines = await ref.read(routinesProvider.future);
      for (final r in routines) {
        if (r.id == widget.routineId) {
          routine = r;
          break;
        }
      }
    }
    if (routine != null) {
      _nameController.text = routine.name;
      _descController.text = routine.description ?? '';
      final sorted = [...routine.exercises]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      _exercises.addAll(sorted);
      _targetMuscles.addAll(routine.targetMuscles);
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);

    _normalizeOrderIndices();

    final exercises = _exercises.map((e) => e.withSyncedLegacyFields()).toList();

    final routine = Routine(
      id: widget.routineId ?? '',
      userId: widget.studentId ?? '',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      targetMuscles: _targetMuscles,
      exercises: exercises,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final service = ref.read(routineServiceProvider);
      if (widget.routineId != null) {
        await service.updateRoutine(
          routine.copyWithId(widget.routineId!),
          forStudentId: widget.isStudentRoutine ? widget.studentId : null,
        );
      } else if (widget.isStudentRoutine) {
        await service.createRoutine(routine, forUserId: widget.studentId);
      } else {
        await service.createRoutine(routine);
      }

      if (widget.isStudentRoutine) {
        ref.invalidate(studentRoutinesProvider(widget.studentId!));
      } else {
        ref.invalidate(routinesProvider);
        ref.invalidate(routineLimitStatusProvider);
      }

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) {
        showRoutineSaveErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
            SnackBar(content: Text(context.l10n.alreadyInRoutine(selected.name))),
          );
        }
        return;
      }

      setState(() {
        final defaultSets = List.generate(
          AppConstants.defaultSets,
          (_) => const RoutineSetTarget(reps: AppConstants.defaultReps),
        );
        _exercises.add(RoutineExercise(
          id: const Uuid().v4(),
          exerciseId: selected.id,
          exerciseName: selected.name,
          orderIndex: _exercises.length,
          imageUrl: selected.isUserCustom ? null : selected.imageUrl,
          loggingType: selected.loggingType,
          targetSets: defaultSets.length,
          targetReps: AppConstants.defaultReps,
          targetSetDetails: defaultSets,
          perArmWeight: ExerciseLoad.perArmWeightForExerciseId(selected.id, exercises),
          targetDurationSeconds: selected.isCardio ? 1200 : null,
          targetDistanceMeters: selected.isCardio ? 3000 : null,
        ));
        _normalizeOrderIndices();
        for (final m in selected.muscles) {
          if (!_targetMuscles.contains(m)) _targetMuscles.add(m);
        }
      });
    }
  }

  void _normalizeOrderIndices() {
    for (var i = 0; i < _exercises.length; i++) {
      if (_exercises[i].orderIndex != i) {
        _exercises[i] = _exercises[i].copyWith(orderIndex: i);
      }
    }
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    setState(() {
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
      _normalizeOrderIndices();
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      _normalizeOrderIndices();
    });
  }

  void _updateExercise(int index, RoutineExercise updated) {
    setState(() => _exercises[index] = updated);
  }

  Widget _buildExerciseCard({
    required int index,
    required RoutineExercise ex,
    required String unitSystem,
    required Iterable<Exercise> catalog,
    required AppLocalizations l10n,
    required bool showDragHandle,
  }) {
    return Card(
      key: ValueKey(ex.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDragHandle)
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 4, top: 12),
                      child: Icon(Icons.drag_handle, color: AppColors.textMuted),
                    ),
                  ),
                ExerciseThumbnail(
                  exerciseId: ex.exerciseId,
                  exerciseName: ex.exerciseName,
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LocalizedExerciseName(
                      ex.exerciseName,
                      exerciseId: ex.exerciseId,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeExercise(index),
                ),
              ],
            ),
            if (ex.isCardio) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _exerciseSubtitle(ex, unitSystem, l10n),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              RoutineExerciseTargetFields(
                exercise: ex,
                unitSystem: unitSystem,
                catalog: catalog,
                onChanged: (updated) => _updateExercise(index, updated),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return Scaffold(body: FitForgeLoadingScreen());
    }

    final String unitSystem;
    if (widget.isStudentRoutine && widget.studentId != null) {
      unitSystem = ref.watch(studentProfileProvider(widget.studentId!)).valueOrNull?.profile.unitSystem ??
          ref.watch(unitSystemProvider);
    } else {
      unitSystem = ref.watch(unitSystemProvider);
    }
    final canReorder = _exercises.length > 1;
    final catalog = ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];

    return Scaffold(
      appBar: FitForgeAppBar(
        title: widget.isStudentRoutine
            ? (widget.routineId != null ? l10n.studentRoutineEdit : l10n.studentRoutineNew)
            : (widget.routineId != null ? l10n.edit : l10n.newRoutine),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.save),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.routineName),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(labelText: l10n.description),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: AppConstants.muscleGroups.map((m) {
                    final selected = _targetMuscles.contains(m);
                    return FilterChip(
                      label: Text(l10n.muscleLabel(m)),
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
                    Text(l10n.exercisesSection(_exercises.length), style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.add),
                    ),
                  ],
                ),
                if (canReorder) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.reorderExercise,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
                const SizedBox(height: 8),
              ]),
            ),
          ),
          if (canReorder)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverReorderableList(
                itemCount: _exercises.length,
                onReorderItem: _reorderExercises,
                itemBuilder: (context, index) => _buildExerciseCard(
                  index: index,
                  ex: _exercises[index],
                  unitSystem: unitSystem,
                  catalog: catalog,
                  l10n: l10n,
                  showDragHandle: true,
                ),
              ),
            )
          else if (_exercises.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildExerciseCard(
                    index: index,
                    ex: _exercises[index],
                    unitSystem: unitSystem,
                    catalog: catalog,
                    l10n: l10n,
                    showDragHandle: false,
                  ),
                  childCount: _exercises.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  String _exerciseSubtitle(RoutineExercise ex, String unitSystem, AppLocalizations l10n) {
    if (ex.isCardio) {
      return l10n.restPeriod(ex.restSeconds);
    }
    final details = ex.resolvedSetDetails;
    if (details.length == 1) {
      final weightPart = details.first.weight != null
          ? ' · ${UnitConverter.formatMass(details.first.weight, unitSystem)}'
          : '';
      return '${details.first.reps}$weightPart · ${l10n.restPeriod(ex.restSeconds)}';
    }
    final repsSummary = details.map((s) => s.reps).join('/');
    final weightPart = details.every((s) => s.weight == details.first.weight) &&
            details.first.weight != null
        ? ' · ${UnitConverter.formatMass(details.first.weight, unitSystem)}'
        : '';
    return '${details.length}× ($repsSummary)$weightPart · ${l10n.restPeriod(ex.restSeconds)}';
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
