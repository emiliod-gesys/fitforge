import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/unit_converter.dart';
import '../models/body_metric.dart';

class BodyMetricCard extends StatelessWidget {
  final BodyMetricDefinition definition;
  final BodyMetricSnapshot snapshot;
  final String unitSystem;
  final VoidCallback onTap;

  const BodyMetricCard({
    super.key,
    required this.definition,
    required this.snapshot,
    required this.unitSystem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final valueText = _formatValue();
    final deltaText = _formatDelta();
    final valueColor = snapshot.valueColor(definition);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                definition.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                valueText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: snapshot.hasValue ? valueColor : AppColors.textMuted,
                ),
              ),
              if (deltaText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  deltaText,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue() {
    if (!snapshot.hasValue) return '—';

    switch (definition.kind) {
      case BodyMetricKind.mass:
        final kg = snapshot.valueKg!;
        return UnitConverter.formatMass(kg, unitSystem);
      case BodyMetricKind.percent:
        return '${snapshot.rawValue!.toStringAsFixed(1)} %';
      case BodyMetricKind.score:
        if (definition.key == 'bmi') {
          return snapshot.rawValue!.toStringAsFixed(1);
        }
        return snapshot.rawValue!.toStringAsFixed(0);
      case BodyMetricKind.kcal:
        return '${snapshot.rawValue!.toStringAsFixed(0)} kcal';
      case BodyMetricKind.years:
        return '${snapshot.rawValue!.toStringAsFixed(0)} años';
    }
  }

  String _formatDelta() {
    switch (definition.kind) {
      case BodyMetricKind.mass:
        return UnitConverter.formatDelta(snapshot.deltaKg, unitSystem);
      case BodyMetricKind.percent:
      case BodyMetricKind.score:
      case BodyMetricKind.kcal:
      case BodyMetricKind.years:
        if (snapshot.deltaRaw == null) return '';
        final d = snapshot.deltaRaw!;
        final sign = d > 0 ? '+' : '';
        final decimals =
            definition.kind == BodyMetricKind.score && definition.key != 'bmi' ? 0 : 1;
        final suffix = definition.kind == BodyMetricKind.percent ? ' %' : '';
        return '$sign${d.toStringAsFixed(decimals)}$suffix';
    }
  }
}
