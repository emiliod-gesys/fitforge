import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_accent.dart';
import '../core/utils/unit_converter.dart';
import '../l10n/l10n_extensions.dart';

/// Compact kg/lb switch for the active workout (session-only; storage stays in kg).
class WorkoutUnitToggle extends StatelessWidget {
  const WorkoutUnitToggle({
    super.key,
    required this.unitSystem,
    required this.onChanged,
    this.compact = false,
  });

  final String unitSystem;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Tooltip(
      message: l10n.workoutUnitToggleHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact)
            Text(
              l10n.workoutWeightUnit,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          if (!compact) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _UnitSegment(
                  label: 'kg',
                  selected: !UnitConverter.isLb(unitSystem),
                  onTap: () => onChanged('kg'),
                ),
                _UnitSegment(
                  label: 'lb',
                  selected: UnitConverter.isLb(unitSystem),
                  onTap: () => onChanged('lb'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitSegment extends StatelessWidget {
  const _UnitSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.accentColor : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
