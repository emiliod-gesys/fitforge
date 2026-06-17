import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/unit_converter.dart';
import '../models/workout.dart';

class SetLogTile extends StatefulWidget {
  final WorkoutSet set;
  final String unitSystem;
  final void Function(WorkoutSet set) onChanged;
  final VoidCallback? onDelete;

  const SetLogTile({
    super.key,
    required this.set,
    required this.unitSystem,
    required this.onChanged,
    this.onDelete,
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

  WorkoutSet _buildSet({bool? completed}) {
    final parsed = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final weightKg = parsed != null ? UnitConverter.displayToKg(parsed, widget.unitSystem) : null;
    return widget.set.copyWith(
      weight: weightKg,
      reps: int.tryParse(_repsController.text) ?? widget.set.reps,
      completed: completed ?? widget.set.completed,
    );
  }

  void _submit({bool markCompleted = true}) {
    widget.onChanged(_buildSet(completed: markCompleted ? true : widget.set.completed));
    setState(() => _editing = false);
  }

  Widget _buildTile(BuildContext context) {
    final unitLabel = UnitConverter.massLabel(widget.unitSystem);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: widget.set.completed && !_editing ? AppColors.orange.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  widget.set.completed && !_editing ? AppColors.orange : AppColors.slate,
              child: Text('${widget.set.setNumber}', style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _weightController,
                enabled: _fieldsEnabled,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: unitLabel,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _repsController,
                enabled: _fieldsEnabled,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'reps',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            if (widget.set.completed && !_editing)
              IconButton(
                tooltip: 'Editar',
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_outlined, size: 22),
              )
            else
              IconButton(
                tooltip: widget.set.completed ? 'Guardar' : 'Completar serie',
                onPressed: _submit,
                icon: const Icon(Icons.check_circle, color: AppColors.orange),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tile = _buildTile(context);
    if (widget.onDelete == null) return tile;

    return Dismissible(
      key: widget.key ?? ValueKey(widget.set.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
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
