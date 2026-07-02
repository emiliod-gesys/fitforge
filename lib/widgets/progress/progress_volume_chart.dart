import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/progress_weekly_volume.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/app_localizations.dart';

class ProgressVolumeChart extends StatelessWidget {
  final List<WeeklyVolumeBucket> buckets;
  final AppLocalizations l10n;
  final String unitSystem;

  const ProgressVolumeChart({
    super.key,
    required this.buckets,
    required this.l10n,
    required this.unitSystem,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = buckets.any((bucket) => bucket.volumeKg > 0 || bucket.workoutCount > 0);
    final maxVolume = buckets.fold<double>(0, (max, b) => b.volumeKg > max ? b.volumeKg : max);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.progressVolumeTrend,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  l10n.completeWorkoutsForVolume,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxVolume <= 0 ? 1 : maxVolume * 1.15,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVolume > 0 ? maxVolume / 4 : 1,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= buckets.length) {
                            return const SizedBox.shrink();
                          }
                          final week = buckets[index].weekStart;
                          final label = '${week.day}/${week.month}';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < buckets.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: buckets[i].volumeKg,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [AppColors.orangeDark, AppColors.orange],
                            ),
                          ),
                        ],
                      ),
                  ],
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final bucket = buckets[group.x];
                        return BarTooltipItem(
                          '${UnitConverter.formatVolume(bucket.volumeKg, unitSystem)}\n${bucket.workoutCount} ${l10n.progressWorkoutsLabel.toLowerCase()}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
