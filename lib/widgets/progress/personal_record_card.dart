import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cardio_format.dart';
import '../../core/utils/unit_converter.dart';
import '../../models/exercise_logging.dart';
import '../../models/profile.dart';
import '../../l10n/l10n_extensions.dart';
import '../exercise_history_sheet.dart';
import '../exercise_thumbnail.dart';
import '../localized_exercise_name.dart';

class PersonalRecordCard extends ConsumerWidget {
  final PersonalRecord record;
  final String unitSystem;
  final List<String> muscleGroups;
  final bool isRecent;

  const PersonalRecordCard({
    super.key,
    required this.record,
    required this.unitSystem,
    this.muscleGroups = const [],
    this.isRecent = false,
  });

  String _subtitle(dynamic l10n) {
    switch (record.recordType) {
      case PersonalRecordType.strength:
        return UnitConverter.formatSetLine(record.weight ?? 0, record.reps, unitSystem);
      case PersonalRecordType.cardioDistance:
        return l10n.cardioPrDistance;
      case PersonalRecordType.cardioDuration:
        return l10n.cardioPrDuration;
      case PersonalRecordType.cardioSteps:
        return l10n.cardioPrSteps;
      case PersonalRecordType.cardioIncline:
        return l10n.cardioPrIncline;
      case PersonalRecordType.cardioDifficulty:
        return l10n.cardioPrDifficulty;
    }
  }

  String _trailing(dynamic l10n) {
    switch (record.recordType) {
      case PersonalRecordType.strength:
        return '${l10n.oneRm}: ${UnitConverter.formatMass(record.oneRepMax ?? 0, unitSystem)}';
      case PersonalRecordType.cardioDistance:
        return CardioFormat.distance(record.distanceMeters, unitSystem);
      case PersonalRecordType.cardioDuration:
        return CardioFormat.duration(record.durationSeconds);
      case PersonalRecordType.cardioSteps:
        return CardioFormat.steps(record.steps);
      case PersonalRecordType.cardioIncline:
        return CardioFormat.incline(record.inclinePercent);
      case PersonalRecordType.cardioDifficulty:
        return CardioFormat.difficulty(record.inclinePercent);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ExerciseHistorySheet.show(
          context,
          exerciseId: record.exerciseId,
          exerciseName: record.exerciseName,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExerciseThumbnail(
                exerciseId: record.exerciseId,
                exerciseName: record.exerciseName,
                width: 52,
                height: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LocalizedExerciseName(
                            record.exerciseName,
                            exerciseId: record.exerciseId,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                        if (isRecent)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.progressNewPrBadge,
                              style: const TextStyle(
                                color: AppColors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.timeAgo(record.achievedAt)} · ${_subtitle(l10n)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    if (muscleGroups.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: muscleGroups.take(2).map((muscle) {
                          return Chip(
                            label: Text(l10n.muscleLabel(muscle)),
                            labelStyle: const TextStyle(fontSize: 11),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppColors.cardElevated,
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _trailing(l10n),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
