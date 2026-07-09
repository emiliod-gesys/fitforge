import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../core/theme/app_accent.dart';

class ProgressMuscleFilterBar extends StatelessWidget {
  final String selectedMuscle;
  final List<String> muscles;
  final ValueChanged<String> onChanged;

  const ProgressMuscleFilterBar({
    super.key,
    required this.selectedMuscle,
    required this.muscles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...muscles.map(
            (muscle) => _FilterChip(
              label: l10n.muscleLabel(muscle),
              selected: selectedMuscle == muscle,
              onTap: () => onChanged(muscle),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? context.accentColor.withValues(alpha: 0.16) : AppColors.cardElevated,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? context.accentColor : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? context.accentColor : AppColors.textMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
