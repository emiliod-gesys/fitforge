import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/body_metric_health.dart';
import '../l10n/l10n_extensions.dart';

class BodyMetricHealthLegend extends StatelessWidget {
  const BodyMetricHealthLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    const levels = [
      (BodyMetricHealthLevel.veryLow, 'bodyMetricHealthVeryLow'),
      (BodyMetricHealthLevel.low, 'bodyMetricHealthLow'),
      (BodyMetricHealthLevel.appropriate, 'bodyMetricHealthAppropriate'),
      (BodyMetricHealthLevel.ideal, 'bodyMetricHealthIdeal'),
      (BodyMetricHealthLevel.high, 'bodyMetricHealthHigh'),
      (BodyMetricHealthLevel.veryBad, 'bodyMetricHealthVeryBad'),
    ];

    String labelFor(String id) => switch (id) {
          'bodyMetricHealthVeryLow' => l10n.bodyMetricHealthVeryLow,
          'bodyMetricHealthLow' => l10n.bodyMetricHealthLow,
          'bodyMetricHealthAppropriate' => l10n.bodyMetricHealthAppropriate,
          'bodyMetricHealthIdeal' => l10n.bodyMetricHealthIdeal,
          'bodyMetricHealthHigh' => l10n.bodyMetricHealthHigh,
          'bodyMetricHealthVeryBad' => l10n.bodyMetricHealthVeryBad,
          _ => '',
        };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bodyMetricColorLegendTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.bodyMetricColorLegendNote,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final (level, labelId) in levels)
                _LegendChip(
                  color: BodyMetricHealthColors.forLevel(level),
                  label: labelFor(labelId),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
