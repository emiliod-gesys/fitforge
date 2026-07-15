import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/exercise_load.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../core/theme/app_accent.dart';

class RoutineExerciseTargetFields extends StatefulWidget {
  const RoutineExerciseTargetFields({
    super.key,
    required this.exercise,
    required this.unitSystem,
    required this.catalog,
    required this.onChanged,
  });

  final RoutineExercise exercise;
  final String unitSystem;
  final Iterable<Exercise> catalog;
  final ValueChanged<RoutineExercise> onChanged;

  @override
  State<RoutineExerciseTargetFields> createState() => _RoutineExerciseTargetFieldsState();
}

class _SetRowControllers {
  _SetRowControllers({
    required int reps,
    required double? weightKg,
    required String unitSystem,
  })  : repsController = TextEditingController(text: '$reps'),
        weightController = TextEditingController(
          text: weightKg == null
              ? ''
              : UnitConverter.kgToDisplay(weightKg, unitSystem).toStringAsFixed(1),
        );

  final TextEditingController repsController;
  final TextEditingController weightController;

  void dispose() {
    repsController.dispose();
    weightController.dispose();
  }
}

class _RoutineExerciseTargetFieldsState extends State<RoutineExerciseTargetFields> {
  final List<_SetRowControllers> _rows = [];
  bool? _perArmWeight;

  @override
  void initState() {
    super.initState();
    _perArmWeight = widget.exercise.perArmWeight;
    _initRows(widget.exercise.resolvedSetDetails);
  }

  @override
  void didUpdateWidget(covariant RoutineExerciseTargetFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _disposeRows();
      _perArmWeight = widget.exercise.perArmWeight;
      _initRows(widget.exercise.resolvedSetDetails);
    }
  }

  void _initRows(List<RoutineSetTarget> details) {
    for (final detail in details) {
      _rows.add(
        _SetRowControllers(
          reps: detail.reps,
          weightKg: detail.weight,
          unitSystem: widget.unitSystem,
        ),
      );
    }
    for (final row in _rows) {
      row.repsController.addListener(_commit);
      row.weightController.addListener(_commit);
    }
  }

  void _disposeRows() {
    for (final row in _rows) {
      row.repsController.removeListener(_commit);
      row.weightController.removeListener(_commit);
      row.dispose();
    }
    _rows.clear();
  }

  bool get _perArmEnabled {
    if (_perArmWeight != null) return _perArmWeight!;
    return ExerciseLoad.resolvePerArmWeight(
      exerciseId: widget.exercise.exerciseId,
      catalog: widget.catalog,
      exerciseName: widget.exercise.exerciseName,
      sessionOverride: _perArmWeight,
    );
  }

  void _commit() {
    final details = <RoutineSetTarget>[];
    for (final row in _rows) {
      final reps = int.tryParse(row.repsController.text.trim());
      if (reps == null || reps < 1) return;

      final weightText = row.weightController.text.trim().replaceAll(',', '.');
      double? weightKg;
      if (weightText.isNotEmpty) {
        final display = double.tryParse(weightText);
        if (display == null || display < 0) return;
        weightKg = UnitConverter.displayToKg(display, widget.unitSystem);
      }

      details.add(RoutineSetTarget(reps: reps, weight: weightKg));
    }

    if (details.isEmpty) return;

    final current = widget.exercise;
    final updated = RoutineExercise(
      id: current.id,
      exerciseId: current.exerciseId,
      exerciseName: current.exerciseName,
      orderIndex: current.orderIndex,
      targetSets: details.length,
      targetReps: details.first.reps,
      targetWeight: details.first.weight,
      restSeconds: current.restSeconds,
      imageUrl: current.imageUrl,
      loggingType: current.loggingType,
      targetDurationSeconds: current.targetDurationSeconds,
      targetDistanceMeters: current.targetDistanceMeters,
      targetInclinePercent: current.targetInclinePercent,
      targetSteps: current.targetSteps,
      perArmWeight: _perArmWeight,
      targetSetDetails: details,
    );

    if (current.perArmWeight == _perArmWeight &&
        _detailsEqual(current.resolvedSetDetails, details)) {
      return;
    }

    widget.onChanged(updated);
  }

  bool _detailsEqual(List<RoutineSetTarget> a, List<RoutineSetTarget> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].reps != b[i].reps || a[i].weight != b[i].weight) return false;
    }
    return true;
  }

  void _addSet() {
    final last = _rows.isEmpty
        ? const RoutineSetTarget(reps: AppConstants.defaultReps)
        : _parseRow(_rows.last);
    setState(() {
      final row = _SetRowControllers(
        reps: last.reps,
        weightKg: last.weight,
        unitSystem: widget.unitSystem,
      );
      row.repsController.addListener(_commit);
      row.weightController.addListener(_commit);
      _rows.add(row);
    });
    _commit();
  }

  RoutineSetTarget _parseRow(_SetRowControllers row) {
    final reps = int.tryParse(row.repsController.text.trim()) ?? AppConstants.defaultReps;
    final weightText = row.weightController.text.trim().replaceAll(',', '.');
    double? weightKg;
    if (weightText.isNotEmpty) {
      final display = double.tryParse(weightText);
      if (display != null && display >= 0) {
        weightKg = UnitConverter.displayToKg(display, widget.unitSystem);
      }
    }
    return RoutineSetTarget(reps: reps, weight: weightKg);
  }

  void _removeSet(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      final row = _rows.removeAt(index);
      row.repsController.removeListener(_commit);
      row.weightController.removeListener(_commit);
      row.dispose();
    });
    _commit();
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: const OutlineInputBorder(),
    );
  }

  @override
  void dispose() {
    _disposeRows();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unit = UnitConverter.massLabel(widget.unitSystem);
    final useLegLabel = ExerciseLoad.isLowerBodySideLoad(
      exerciseName: widget.exercise.exerciseName,
      exerciseId: widget.exercise.exerciseId,
      catalog: widget.catalog,
    );
    final weightLabel = ExerciseLoad.weightLabel(
      unit,
      widget.exercise.exerciseName,
      perArmWeight: _perArmEnabled,
      perArmSuffix: l10n.weightPerArmSuffix,
      perLegSuffix: l10n.weightPerLegSuffix,
      useLegLabel: useLegLabel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.loadModeToggleHint,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
            Text(
              _perArmEnabled
                  ? (useLegLabel ? l10n.loadModePerLeg : l10n.loadModePerArm)
                  : l10n.loadModeCombined,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            SizedBox(width: 8),
            Switch.adaptive(
              value: _perArmEnabled,
              activeThumbColor: context.accentColor,
              onChanged: (value) {
                setState(() => _perArmWeight = value);
                _commit();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_rows.length, (index) {
          final row = _rows[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      l10n.routineSetNumber(index + 1),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: row.repsController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _fieldDecoration(l10n.reps),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: row.weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    ],
                    decoration: _fieldDecoration(weightLabel),
                  ),
                ),
                if (_rows.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.textMuted),
                    onPressed: () => _removeSet(index),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addSet,
            icon: const Icon(Icons.add),
            label: Text(l10n.routineAddSet),
          ),
        ),
      ],
    );
  }
}
