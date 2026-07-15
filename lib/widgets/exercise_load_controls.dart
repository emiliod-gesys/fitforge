import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/exercise_load.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/l10n_extensions.dart';
import '../core/theme/app_accent.dart';

/// Controles de sesión: alternar peso por brazo/conjunto y aviso de peso corporal.
class ExerciseLoadControls extends StatelessWidget {
  final String exerciseId;
  final String exerciseName;
  final Iterable<Exercise> catalog;
  final bool perArmEnabled;
  final ValueChanged<bool> onPerArmChanged;
  final double? bodyWeightKg;
  final String unitSystem;

  const ExerciseLoadControls({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.catalog,
    required this.perArmEnabled,
    required this.onPerArmChanged,
    this.bodyWeightKg,
    required this.unitSystem,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final perLeg = ExerciseLoad.usesPerLegLabel(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      catalog: catalog,
    );
    final showToggle = ExerciseLoad.supportsPerArmToggle(
      exerciseId,
      catalog,
      exerciseName,
    );
    final isBodyweight = ExerciseLoad.isBodyweightLoad(
      exerciseId,
      catalog,
      exerciseName,
    );

    if (!showToggle && !isBodyweight) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showToggle) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.loadModeToggleHint,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              Text(
                perArmEnabled
                    ? l10n.loadModePerSide(perLeg: perLeg)
                    : l10n.loadModeCombined,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              SizedBox(width: 8),
              Switch.adaptive(
                value: perArmEnabled,
                activeThumbColor: context.accentColor,
                onChanged: onPerArmChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (isBodyweight && bodyWeightKg != null && bodyWeightKg! > 0) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.accentColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              l10n.bodyweightLoadHint(
                UnitConverter.formatMass(bodyWeightKg!, unitSystem),
              ),
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
