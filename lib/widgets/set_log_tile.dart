import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/exercise_load.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/l10n_extensions.dart';
import '../models/workout.dart';

class SetLogTile extends StatefulWidget {
  final WorkoutSet set;
  final String unitSystem;
  final String exerciseName;
  final bool? perArmWeight;
  final bool isLast;
  final void Function(WorkoutSet set) onChanged;
  final VoidCallback? onDelete;
  final void Function(String message)? onValidationError;

  const SetLogTile({
    super.key,
    required this.set,
    required this.unitSystem,
    required this.exerciseName,
    this.perArmWeight,
    this.isLast = true,
    required this.onChanged,
    this.onDelete,
    this.onValidationError,
  });

  @override
  State<SetLogTile> createState() => _SetLogTileState();
}

class _SetLogTileState extends State<SetLogTile> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late String _lastUnitSystem;
  bool _editing = false;

  bool get _fieldsEnabled => !widget.set.completed || _editing;

  @override
  void initState() {
    super.initState();
    _lastUnitSystem = widget.unitSystem;
    _repsController = TextEditingController(text: widget.set.reps.toString());
    _weightController = TextEditingController();
    _syncWeightField();
  }

  void _syncWeightField() {
    if (widget.set.weight != null) {
      final display = UnitConverter.kgToDisplay(widget.set.weight!, widget.unitSystem);
      _weightController.text = display.toStringAsFixed(1);
    } else if (_weightController.text.isEmpty) {
      _weightController.text = '';
    }
  }

  @override
  void didUpdateWidget(SetLogTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unitSystem != widget.unitSystem) {
      final parsed = double.tryParse(_weightController.text.replaceAll(',', '.'));
      if (parsed != null && _fieldsEnabled) {
        final kg = UnitConverter.displayToKg(parsed, _lastUnitSystem);
        final display = UnitConverter.kgToDisplay(kg, widget.unitSystem);
        _weightController.text = display.toStringAsFixed(1);
      } else {
        _syncWeightField();
      }
      _lastUnitSystem = widget.unitSystem;
    } else if (oldWidget.set.weight != widget.set.weight ||
        oldWidget.set.completed != widget.set.completed) {
      if (!_editing) _syncWeightField();
      if (widget.set.completed) _editing = false;
    }
    if (oldWidget.set.reps != widget.set.reps && !_editing) {
      _repsController.text = widget.set.reps.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  double? _parsedWeightKg() {
    final parsed = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;
    return UnitConverter.displayToKg(parsed, widget.unitSystem);
  }

  WorkoutSet _buildSet({bool? completed}) {
    return widget.set.copyWith(
      weight: _parsedWeightKg(),
      reps: int.tryParse(_repsController.text) ?? widget.set.reps,
      completed: completed ?? widget.set.completed,
    );
  }

  bool _validateForComplete() {
    final l10n = context.l10n;
    if (_parsedWeightKg() == null) {
      widget.onValidationError?.call(l10n.weightRequired);
      return false;
    }
    final reps = int.tryParse(_repsController.text);
    if (reps == null || reps <= 0) {
      widget.onValidationError?.call(l10n.repsRequired);
      return false;
    }
    return true;
  }

  void _submit({bool markCompleted = true}) {
    if (markCompleted && !_validateForComplete()) return;
    widget.onChanged(_buildSet(completed: markCompleted ? true : widget.set.completed));
    setState(() => _editing = false);
  }

  InputDecoration _fieldDecoration({
    required String label,
    bool emphasize = false,
  }) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: emphasize
          ? AppColors.cardElevated
          : (_fieldsEnabled ? AppColors.card : AppColors.card.withValues(alpha: 0.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: emphasize ? AppColors.orange.withValues(alpha: 0.6) : AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final l10n = context.l10n;
    final unitLabel = UnitConverter.massLabel(widget.unitSystem);
    final perArm = ExerciseLoad.isPerArmWeight(
      widget.exerciseName,
      perArmWeight: widget.perArmWeight,
    );
    final weightLabel = perArm ? l10n.weightPerArm(unitLabel) : unitLabel;
    final isDone = widget.set.completed && !_editing;
    final isActive = _fieldsEnabled && !isDone;

    return Opacity(
      opacity: isDone ? 0.72 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? AppColors.orange.withValues(alpha: 0.2)
                            : isActive
                                ? AppColors.cardElevated
                                : AppColors.card,
                        border: Border.all(
                          color: isDone || isActive ? AppColors.orange : AppColors.border,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, size: 16, color: AppColors.orange)
                          : Text(
                              '${widget.set.setNumber}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                    ),
                    if (!widget.isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: AppColors.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          enabled: _fieldsEnabled,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          decoration: _fieldDecoration(
                            label: weightLabel,
                            emphasize: isActive,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _repsController,
                          enabled: _fieldsEnabled,
                          keyboardType: TextInputType.number,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          decoration: _fieldDecoration(
                            label: l10n.reps,
                            emphasize: isActive,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isDone)
                        IconButton(
                          tooltip: l10n.edit,
                          onPressed: () => setState(() => _editing = true),
                          icon: const Icon(Icons.edit_outlined, size: 22),
                        )
                      else
                        FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(l10n.done),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tile = _buildTile(context);
    if (widget.onDelete == null) return tile;

    return Dismissible(
      key: ValueKey('dismiss-${widget.set.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDelete?.call(),
      child: tile,
    );
  }
}
