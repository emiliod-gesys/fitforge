import 'package:flutter/material.dart';
import '../models/workout.dart';

class SetLogTile extends StatefulWidget {
  final WorkoutSet set;
  final ValueChanged<WorkoutSet> onChanged;

  const SetLogTile({super.key, required this.set, required this.onChanged});

  @override
  State<SetLogTile> createState() => _SetLogTileState();
}

class _SetLogTileState extends State<SetLogTile> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.set.weight?.toString() ?? '');
    _repsController = TextEditingController(text: widget.set.reps.toString());
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onChanged(widget.set.copyWith(
      weight: double.tryParse(_weightController.text),
      reps: int.tryParse(_repsController.text) ?? widget.set.reps,
      completed: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: widget.set.completed ? Colors.green.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.set.completed
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              child: Text('${widget.set.setNumber}', style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'kg',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _repsController,
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
                color: widget.set.completed ? Colors.green : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
