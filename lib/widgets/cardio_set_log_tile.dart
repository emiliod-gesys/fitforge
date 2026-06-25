import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/cardio_format.dart';
import '../l10n/l10n_extensions.dart';
import '../models/exercise_logging.dart';
import '../models/workout.dart';

class CardioSetLogTile extends StatefulWidget {
  final WorkoutSet set;
  final String unitSystem;
  final CardioLoggingConfig config;
  final bool isLast;
  final bool isSaving;
  final void Function(WorkoutSet set) onChanged;
  final VoidCallback? onDelete;
  final void Function(String message)? onValidationError;

  const CardioSetLogTile({
    super.key,
    required this.set,
    required this.unitSystem,
    required this.config,
    this.isLast = true,
    this.isSaving = false,
    required this.onChanged,
    this.onDelete,
    this.onValidationError,
  });

  @override
  State<CardioSetLogTile> createState() => _CardioSetLogTileState();
}

class _CardioSetLogTileState extends State<CardioSetLogTile> {
  late TextEditingController _durationController;
  late TextEditingController _distanceController;
  late TextEditingController _inclineController;
  late TextEditingController _stepsController;
  bool _editing = false;

  bool get _fieldsEnabled => !widget.set.completed || _editing;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
      text: widget.set.durationSeconds != null
          ? CardioFormat.duration(widget.set.durationSeconds)
          : '',
    );
    _distanceController = TextEditingController(
      text: _distanceDisplay(widget.set.distanceMeters),
    );
    _inclineController = TextEditingController(
      text: widget.set.inclinePercent?.toStringAsFixed(1) ?? '',
    );
    _stepsController = TextEditingController(
      text: widget.set.steps?.toString() ?? '',
    );
  }

  String _distanceDisplay(double? meters) {
    if (meters == null || meters <= 0) return '';
    if (widget.unitSystem == 'imperial') {
      return (meters / 1609.344).toStringAsFixed(2);
    }
    return (meters / 1000).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _inclineController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  WorkoutSet _buildSet({bool? completed}) {
    return widget.set.copyWith(
      durationSeconds: CardioFormat.parseDuration(_durationController.text),
      distanceMeters: CardioFormat.parseDistanceMeters(
        _distanceController.text,
        widget.unitSystem,
      ),
      inclinePercent: double.tryParse(_inclineController.text.replaceAll(',', '.')),
      steps: int.tryParse(_stepsController.text),
      loggingType: ExerciseLoggingType.cardio,
      completed: completed ?? widget.set.completed,
    );
  }

  bool _validateForComplete() {
    final l10n = context.l10n;
    final built = _buildSet();
    if (!widget.config.isSetComplete(
      durationSeconds: built.durationSeconds,
      distanceMeters: built.distanceMeters,
      inclinePercent: built.inclinePercent,
      steps: built.steps,
    )) {
      widget.onValidationError?.call(l10n.cardioMetricRequired);
      return false;
    }
    return true;
  }

  void _submit({bool markCompleted = true}) {
    if (markCompleted && !_validateForComplete()) return;
    widget.onChanged(_buildSet(completed: markCompleted ? true : widget.set.completed));
    setState(() => _editing = false);
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: _fieldsEnabled ? AppColors.cardElevated : AppColors.card.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDone = widget.set.completed && !_editing;

    return Opacity(
      opacity: isDone ? 0.72 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? AppColors.orange.withValues(alpha: 0.2)
                            : AppColors.cardElevated,
                        border: Border.all(color: AppColors.orange),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, size: 16, color: AppColors.orange)
                          : Text('${widget.set.setNumber}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isDone
                            ? CardioFormat.setSummary(
                                config: widget.config,
                                unitSystem: widget.unitSystem,
                                durationSeconds: widget.set.durationSeconds,
                                distanceMeters: widget.set.distanceMeters,
                                inclinePercent: widget.set.inclinePercent,
                                stepCount: widget.set.steps,
                              )
                            : l10n.cardioSetLabel(widget.set.setNumber),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isDone)
                      IconButton(
                        tooltip: l10n.edit,
                        onPressed: () => setState(() => _editing = true),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                    if (widget.onDelete != null)
                      IconButton(
                        tooltip: l10n.delete,
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline, size: 20),
                      ),
                  ],
                ),
                if (!isDone) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.config.tracksDuration)
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: _durationController,
                            enabled: _fieldsEnabled,
                            keyboardType: TextInputType.datetime,
                            decoration: _fieldDecoration(l10n.cardioDuration),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      if (widget.config.tracksDistance)
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: _distanceController,
                            enabled: _fieldsEnabled,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _fieldDecoration(
                              '${l10n.cardioDistance} (${CardioFormat.distanceInputLabel(widget.unitSystem)})',
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      if (widget.config.tracksIncline)
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _inclineController,
                            enabled: _fieldsEnabled,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _fieldDecoration(l10n.cardioIncline),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      if (widget.config.tracksDifficulty)
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _inclineController,
                            enabled: _fieldsEnabled,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _fieldDecoration(l10n.cardioDifficulty),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      if (widget.config.tracksSteps)
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _stepsController,
                            enabled: _fieldsEnabled,
                            keyboardType: TextInputType.number,
                            decoration: _fieldDecoration(l10n.cardioSteps),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: widget.isSaving ? null : () => _submit(),
                      child: widget.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.done),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
