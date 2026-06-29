import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/food_entry.dart';

class MacroChipGrid extends StatelessWidget {
  final MacroTotals eaten;
  final MacroTargets targets;
  final String proteinLabel;
  final String carbsLabel;
  final String fatLabel;
  final String fiberLabel;

  const MacroChipGrid({
    super.key,
    required this.eaten,
    required this.targets,
    required this.proteinLabel,
    required this.carbsLabel,
    required this.fatLabel,
    required this.fiberLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _MacroChip(
          label: proteinLabel,
          current: eaten.proteinG,
          target: targets.proteinG,
          color: const Color(0xFFE85D75),
          unit: 'g',
        ),
        _MacroChip(
          label: carbsLabel,
          current: eaten.carbsG,
          target: targets.carbsG,
          color: const Color(0xFF5BB8F0),
          unit: 'g',
        ),
        _MacroChip(
          label: fatLabel,
          current: eaten.fatG,
          target: targets.fatG,
          color: const Color(0xFFF5B942),
          unit: 'g',
        ),
        _MacroChip(
          label: fiberLabel,
          current: eaten.fiberG,
          target: targets.fiberG,
          color: const Color(0xFF7BC67E),
          unit: 'g',
        ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;

  const _MacroChip({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${current.round()}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '/ ${target.round()}$unit',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.cardElevated,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
