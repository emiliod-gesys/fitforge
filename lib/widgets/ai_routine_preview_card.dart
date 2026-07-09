import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../core/utils/cardio_format.dart';
import '../core/utils/exercise_logging_resolver.dart';
import '../models/exercise_logging.dart';
import '../models/routine.dart';
import '../providers/app_providers.dart';
import '../core/theme/app_accent.dart';

class AiRoutinePreviewCard extends ConsumerWidget {
  final Routine routine;
  final bool isSaved;
  final bool isDiscarded;
  final bool isSaving;
  final bool shareMode;
  final bool previewOnly;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  final VoidCallback onDiscard;

  const AiRoutinePreviewCard({
    super.key,
    required this.routine,
    required this.isSaved,
    required this.isDiscarded,
    this.isSaving = false,
    this.shareMode = false,
    this.previewOnly = false,
    required this.onSave,
    required this.onEdit,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (isDiscarded) {
      return _StatusBanner(
        icon: Icons.delete_outline,
        text: l10n.routineDiscarded,
        color: AppColors.textMuted,
      );
    }

    if (isSaved) {
      return _StatusBanner(
        icon: Icons.check_circle,
        text: l10n.routineSaved,
        color: context.accentColor,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.accentColor.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                shareMode ? Icons.fitness_center : Icons.auto_awesome,
                color: context.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  routine.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          if (routine.description != null && routine.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              routine.description!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
          if (routine.targetMuscles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              routine.targetMuscles.join(' · '),
              style: TextStyle(color: context.accentColor, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
            ...routine.exercises.take(8).map((ex) => _exerciseLine(context, ref, ex)),
          if (routine.exercises.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.moreExercises(routine.exercises.length - 8),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 14),
          if (!previewOnly) ...[
          if (!shareMode)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDiscard,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(l10n.discard, textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(l10n.edit, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          if (!shareMode) const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(shareMode ? l10n.saveRoutine : l10n.save),
            ),
          ),
          if (shareMode) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDiscard,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                child: Text(l10n.close),
              ),
            ),
          ],
          ],
        ],
      ),
    );
  }

  Widget _exerciseLine(BuildContext context, WidgetRef ref, RoutineExercise ex) {
    final name = ref.watch(exercisesProvider).maybeWhen(
          data: (_) => ref.read(exerciseServiceProvider).localizedName(
                exerciseId: ex.exerciseId,
                fallback: ex.exerciseName,
              ),
          orElse: () => ex.exerciseName,
        );
    final detail = ex.isCardio
        ? _cardioDetail(ref, ex)
        : '${ex.targetSets}×${ex.targetReps}${ex.targetWeight != null ? ' · ${ex.targetWeight!.toStringAsFixed(0)} kg' : ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: context.accentColor)),
          Expanded(
            child: Text(
              '$name — $detail',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _cardioDetail(WidgetRef ref, RoutineExercise ex) {
    final unitSystem = ref.watch(unitSystemProvider);
    final parts = <String>[];
    if (ex.targetDurationSeconds != null) {
      parts.add(CardioFormat.duration(ex.targetDurationSeconds));
    }
    if (ex.targetDistanceMeters != null) {
      parts.add(CardioFormat.distance(ex.targetDistanceMeters, unitSystem));
    }
    if (ex.targetInclinePercent != null) {
      final config = ExerciseLoggingResolver.cardioConfigFor(
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
      );
      if (config.tracksDifficulty) {
        parts.add('${CardioFormat.difficulty(ex.targetInclinePercent)} lvl');
      } else {
        parts.add(CardioFormat.incline(ex.targetInclinePercent));
      }
    }
    if (ex.targetSteps != null) {
      parts.add(CardioFormat.steps(ex.targetSteps));
    }
    if (parts.isEmpty) return 'cardio';
    return parts.join(' · ');
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}
