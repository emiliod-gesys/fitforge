import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/profile.dart';
import '../../core/theme/app_accent.dart';

class ProgressBodySnapshot extends StatelessWidget {
  final List<BodyMeasurement> measurements;
  final AppLocalizations l10n;
  final String unitSystem;

  const ProgressBodySnapshot({
    super.key,
    required this.measurements,
    required this.l10n,
    required this.unitSystem,
  });

  BodyMeasurement? _latest(String type) {
    BodyMeasurement? latest;
    for (final entry in measurements) {
      if (entry.type != type) continue;
      if (latest == null || entry.measuredAt.isAfter(latest.measuredAt)) {
        latest = entry;
      }
    }
    return latest;
  }

  String _formatWeight(BodyMeasurement measurement) {
    return UnitConverter.formatMass(measurement.value, unitSystem);
  }

  @override
  Widget build(BuildContext context) {
    final weight = _latest('weight');
    final bodyFat = _latest('body_fat');

    if (weight == null && bodyFat == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.progressBodyTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (weight != null)
                Expanded(
                  child: _MetricTile(
                    icon: Icons.monitor_weight_outlined,
                    label: l10n.metricWeight,
                    value: _formatWeight(weight),
                  ),
                ),
              if (weight != null && bodyFat != null) const SizedBox(width: 10),
              if (bodyFat != null)
                Expanded(
                  child: _MetricTile(
                    icon: Icons.pie_chart_outline,
                    label: l10n.metricBodyFat,
                    value: '${bodyFat.value.toStringAsFixed(1)}%',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
