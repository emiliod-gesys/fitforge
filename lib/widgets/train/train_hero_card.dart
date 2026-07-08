import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/utils/workout_streak.dart';
import '../../l10n/l10n_extensions.dart';

class TrainHeroCard extends StatelessWidget {
  final WorkoutWeeklyStats? stats;
  final bool isLoading;
  final VoidCallback onStartWorkout;

  const TrainHeroCard({
    super.key,
    required this.stats,
    required this.isLoading,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final weeklyGoal = stats?.weeklyGoal ?? WorkoutStreakCalculator.weeklyGoal;
    final weekCount = stats?.currentWeekCount ?? 0;
    final streakWeeks = stats?.streakWeeks ?? 0;
    final progress = weeklyGoal > 0 ? (weekCount / weeklyGoal).clamp(0.0, 1.0) : 0.0;
    final remaining = (weeklyGoal - weekCount).clamp(0, weeklyGoal);
    final goalMet = stats?.metGoalThisWeek ?? false;

    final title = isLoading
        ? l10n.trainHeroReadyTitle
        : goalMet
            ? l10n.trainHeroGoalMetTitle
            : streakWeeks > 0
                ? l10n.trainHeroStreakWeeks(streakWeeks)
                : l10n.trainHeroReadyTitle;

    final subtitle = isLoading
        ? l10n.weeklyWorkoutsSubtitle(weeklyGoal)
        : goalMet
            ? l10n.trainWeeklyProgress(weekCount, weeklyGoal)
            : remaining > 0
                ? l10n.trainWorkoutsRemaining(remaining)
                : l10n.trainWeeklyProgress(weekCount, weeklyGoal);

    return Container(
      decoration: AppDecorations.heroCard(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppDecorations.heroSubtitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _HeroStatChip(
                    icon: Icons.local_fire_department,
                    label: l10n.streakLabel,
                    value: isLoading ? '…' : '$streakWeeks',
                  ),
                ),
                const SizedBox(width: 12),
                _WeeklyRing(
                  progress: isLoading ? 0 : progress,
                  label: isLoading ? '…' : '$weekCount/$weeklyGoal',
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStartWorkout,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.startWorkout),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.goldDark,
                  minimumSize: const Size.fromHeight(50),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
  }
}

class _HeroStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyRing extends StatelessWidget {
  final double progress;
  final String label;

  const _WeeklyRing({
    required this.progress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
