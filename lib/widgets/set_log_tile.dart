import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/unit_converter.dart';
import '../models/workout.dart';

class SetLogTile extends StatefulWidget {
  final WorkoutSet set;
  final String unitSystem;
  final ValueChanged<WorkoutSet> onChanged;

  const SetLogTile({
    super.key,
    required this.set,
    required this.unitSystem,
    required this.onChanged,
  });

  @override
  State<SetLogTile> createState() => _SetLogTileState();
}

class _SetLogTileState extends State<SetLogTile> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late String _lastUnitSystem;

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
      if (parsed != null && !widget.set.completed) {
        final kg = UnitConverter.displayToKg(parsed, _lastUnitSystem);
        final display = UnitConverter.kgToDisplay(kg, widget.unitSystem);
        _weightController.text = display.toStringAsFixed(1);
      } else {
        _syncWeightField();
      }
      _lastUnitSystem = widget.unitSystem;
    } else if (oldWidget.set.weight != widget.set.weight || oldWidget.set.completed != widget.set.completed) {
      _syncWeightField();
    }
    if (oldWidget.set.reps != widget.set.reps) {
      _repsController.text = widget.set.reps.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final weightKg = parsed != null ? UnitConverter.displayToKg(parsed, widget.unitSystem) : null;
    widget.onChanged(widget.set.copyWith(
      weight: weightKg,
      reps: int.tryParse(_repsController.text) ?? widget.set.reps,
      completed: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = UnitConverter.massLabel(widget.unitSystem);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: widget.set.completed ? AppColors.orange.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.set.completed ? AppColors.orange : AppColors.slate,
              child: Text('${widget.set.setNumber}', style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _weightController,
                enabled: !widget.set.completed,
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
                enabled: !widget.set.completed,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'reps',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            IconButton(
              onPressed: widget.set.completed ? null : _submit,
              icon: Icon(
                widget.set.completed ? Icons.check_circle : Icons.check_circle_outline,
                color: widget.set.completed ? AppColors.orange : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
