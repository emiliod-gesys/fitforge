import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/progress_exercise_curve.dart' as curve;
import '../../core/utils/rir_weight_adjustment.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/l10n_extensions.dart';
import '../../providers/app_providers.dart';
import '../exercise_thumbnail.dart';
import '../localized_exercise_name.dart';
import '../workout_exercise_picker_sheet.dart';

class ProgressExerciseCurve extends ConsumerStatefulWidget {
  const ProgressExerciseCurve({super.key});

  @override
  ConsumerState<ProgressExerciseCurve> createState() => _ProgressExerciseCurveState();
}

class _ProgressExerciseCurveState extends ConsumerState<ProgressExerciseCurve> {
  String? _selectedId;
  String? _selectedName;
  String? _selectedCategory;
  List<String> _selectedMuscles = const [];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unitSystem = ref.watch(unitSystemProvider);
    final loggedAsync = ref.watch(loggedExercisesProvider);

    return loggedAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (exercises) {
        final selected = _selectedId ?? (exercises.isEmpty ? null : exercises.first.id);
        String? selectedName = _selectedName;
        if (selectedName == null && selected != null) {
          for (final exercise in exercises) {
            if (exercise.id == selected) {
              selectedName = exercise.name;
              break;
            }
          }
        }
        final historyAsync = selected == null ? null : ref.watch(progressExerciseCurveProvider(selected));

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.progressExerciseCurveTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _ExercisePickerButton(
                exerciseId: selected,
                exerciseName: selectedName,
                category: _selectedCategory,
                muscles: _selectedMuscles,
                placeholder: l10n.progressExercisePickerTitle,
                onTap: () => _openPicker(l10n.progressExercisePickerTitle),
              ),
              const SizedBox(height: 16),
              if (historyAsync == null)
                Text(
                  l10n.progressExerciseCurveEmpty,
                  style: const TextStyle(color: AppColors.textMuted),
                )
              else
                historyAsync.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (sessions) {
                  final points = curve.ProgressExerciseCurve.fromSessions(sessions);
                  if (points.isEmpty) {
                    return Text(
                      l10n.progressExerciseCurveEmpty,
                      style: const TextStyle(color: AppColors.textMuted),
                    );
                  }
                  final latest = points.last;
                  final usesWeight = points.any((point) => point.weightKg > 0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (points.length < 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            l10n.progressExerciseCurveNeedAnother,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      else
                        SizedBox(
                          height: 180,
                          child: _CurveChart(
                            points: points,
                            unitSystem: unitSystem,
                            usesWeight: usesWeight,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.progressExerciseCurveLatest(
                          _detail(latest, unitSystem, usesWeight),
                        ),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPicker(String title) async {
    final picked = await WorkoutExercisePickerSheet.show(
      context,
      title: title,
      showCreate: false,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedId = picked.id;
      _selectedName = picked.name;
      _selectedCategory = picked.category;
      _selectedMuscles = picked.muscles;
    });
  }

  String _detail(curve.ExerciseCurvePoint point, String unitSystem, bool usesWeight) {
    final l10n = context.l10n;
    final load = usesWeight && point.weightKg > 0
        ? UnitConverter.formatSetLine(point.weightKg, point.reps, unitSystem)
        : l10n.repsOnly(point.reps);
    if (point.rir == null) return load;
    return '$load · ${l10n.setRirCaption(RirWeightAdjustment.formatLabel(point.rir!))}';
  }
}

class _ExercisePickerButton extends StatelessWidget {
  final String? exerciseId;
  final String? exerciseName;
  final String? category;
  final List<String> muscles;
  final String placeholder;
  final VoidCallback onTap;

  const _ExercisePickerButton({
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.muscles,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasExercise = exerciseId != null && exerciseName != null;
    return Material(
      color: AppColors.cardElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (hasExercise)
                ExerciseThumbnail(
                  exerciseId: exerciseId!,
                  exerciseName: exerciseName!,
                  category: category,
                  muscles: muscles,
                  width: 44,
                  height: 44,
                )
              else
                const Icon(Icons.search, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: hasExercise
                    ? LocalizedExerciseName(
                        exerciseName!,
                        exerciseId: exerciseId!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        placeholder,
                        style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
              ),
              const Icon(Icons.unfold_more, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _CurveChart extends StatelessWidget {
  final List<curve.ExerciseCurvePoint> points;
  final String unitSystem;
  final bool usesWeight;

  const _CurveChart({
    required this.points,
    required this.unitSystem,
    required this.usesWeight,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    final values = [
      for (final point in points) usesWeight ? point.weightKg : point.reps.toDouble(),
    ];
    final maxValue = values.fold<double>(0, (best, value) => value > best ? value : best);
    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxValue <= 0 ? 1 : maxValue * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
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
                if (index < 0 || index >= points.length || index != value) {
                  return const SizedBox.shrink();
                }
                final show = points.length <= 6 ||
                    index == 0 ||
                    index == points.length - 1 ||
                    index == points.length ~/ 2;
                if (!show) return const SizedBox.shrink();
                final date = points[index].date.toLocal();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return [
                for (final spot in spots)
                  LineTooltipItem(
                    _tooltip(points[spot.x.toInt()]),
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ),
              ];
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: accent,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: accent,
                strokeWidth: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tooltip(curve.ExerciseCurvePoint point) {
    final date = point.date.toLocal();
    final load = usesWeight && point.weightKg > 0
        ? UnitConverter.formatSetLine(point.weightKg, point.reps, unitSystem)
        : '${point.reps}';
    final rir = point.rir == null ? '' : '\nRIR ${RirWeightAdjustment.formatLabel(point.rir!)}';
    return '${date.day}/${date.month}\n$load$rir';
  }
}
