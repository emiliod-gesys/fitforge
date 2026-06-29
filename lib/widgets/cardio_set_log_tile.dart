import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/cardio_format.dart';
import '../l10n/app_localizations.dart';
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
  late TextEditingController _minutesController;
  late TextEditingController _secondsController;
  late TextEditingController _distanceController;
  late TextEditingController _inclineController;
  late TextEditingController _stepsController;
  bool _editing = false;

  bool get _fieldsEnabled => !widget.set.completed || _editing;

  @override
  void initState() {
    super.initState();
    final parts = CardioFormat.durationParts(widget.set.durationSeconds);
    _minutesController = TextEditingController(
      text: parts.minutes > 0 ? '${parts.minutes}' : '',
    );
    _secondsController = TextEditingController(
      text: parts.seconds > 0 ? '${parts.seconds}' : '',
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

  void _syncDurationFields() {
    final parts = CardioFormat.durationParts(widget.set.durationSeconds);
    _minutesController.text = parts.minutes > 0 ? '${parts.minutes}' : '';
    _secondsController.text = parts.seconds > 0 ? '${parts.seconds}' : '';
  }

  @override
  void didUpdateWidget(CardioSetLogTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set.durationSeconds != widget.set.durationSeconds && !_editing) {
      _syncDurationFields();
    }
    if (widget.set.completed) _editing = false;
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _distanceController.dispose();
    _inclineController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  WorkoutSet _buildSet({bool? completed}) {
    return widget.set.copyWith(
      durationSeconds: CardioFormat.durationFromPartStrings(
        _minutesController.text,
        _secondsController.text,
      ),
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

  Widget _metricField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.number,
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      enabled: _fieldsEnabled,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : keyboardType,
      decoration: _fieldDecoration(label),
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _buildMetricFields(AppLocalizations l10n) {
    final hasDuration = widget.config.tracksDuration;
    final hasDistance = widget.config.tracksDistance;
    final hasIncline = widget.config.tracksIncline;
    final hasDifficulty = widget.config.tracksDifficulty;
    final hasSteps = widget.config.tracksSteps;

    final topRow = <Widget>[];
    if (hasDuration) {
      topRow.add(
        _DurationInputRow(
          minutesController: _minutesController,
          secondsController: _secondsController,
          enabled: _fieldsEnabled,
          minutesLabel: l10n.minutes,
          secondsLabel: l10n.cardioSecondsShort,
          decorationBuilder: _fieldDecoration,
          onSubmitted: _submit,
        ),
      );
    }
    if (hasDistance) {
      if (topRow.isNotEmpty) topRow.add(const SizedBox(width: 8));
      topRow.add(
        Expanded(
          child: _metricField(
            controller: _distanceController,
            label: '${l10n.cardioDistance} (${CardioFormat.distanceInputLabel(widget.unitSystem)})',
            decimal: true,
          ),
        ),
      );
    }
    if (hasDifficulty && !hasDistance) {
      if (topRow.isNotEmpty) topRow.add(const SizedBox(width: 8));
      topRow.add(
        Expanded(
          child: _metricField(
            controller: _inclineController,
            label: l10n.cardioDifficulty,
            decimal: true,
          ),
        ),
      );
    }

    final bottomRow = <Widget>[];
    if (hasIncline) {
      bottomRow.add(
        SizedBox(
          width: 120,
          child: _metricField(
            controller: _inclineController,
            label: l10n.cardioIncline,
            decimal: true,
          ),
        ),
      );
    }
    if (hasDifficulty && hasDistance) {
      if (bottomRow.isNotEmpty) bottomRow.add(const SizedBox(width: 8));
      bottomRow.add(
        SizedBox(
          width: 120,
          child: _metricField(
            controller: _inclineController,
            label: l10n.cardioDifficulty,
            decimal: true,
          ),
        ),
      );
    }
    if (hasSteps) {
      if (bottomRow.isNotEmpty) bottomRow.add(const SizedBox(width: 8));
      bottomRow.add(
        SizedBox(
          width: 120,
          child: _metricField(
            controller: _stepsController,
            label: l10n.cardioSteps,
          ),
        ),
      );
    }

    if (topRow.isEmpty && bottomRow.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (topRow.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: topRow,
          ),
        if (bottomRow.isNotEmpty) ...[
          if (topRow.isNotEmpty) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bottomRow,
          ),
        ],
      ],
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
                  _buildMetricFields(l10n),
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

class _DurationInputRow extends StatelessWidget {
  final TextEditingController minutesController;
  final TextEditingController secondsController;
  final bool enabled;
  final String minutesLabel;
  final String secondsLabel;
  final InputDecoration Function(String label) decorationBuilder;
  final VoidCallback onSubmitted;

  const _DurationInputRow({
    required this.minutesController,
    required this.secondsController,
    required this.enabled,
    required this.minutesLabel,
    required this.secondsLabel,
    required this.decorationBuilder,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: TextField(
            controller: minutesController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: decorationBuilder(minutesLabel),
            onSubmitted: (_) => onSubmitted(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ),
        SizedBox(
          width: 72,
          child: TextField(
            controller: secondsController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: decorationBuilder(secondsLabel),
            onSubmitted: (_) => onSubmitted(),
          ),
        ),
      ],
    );
  }
}
