import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_accent.dart';

class ProgressStatsGrid extends StatelessWidget {
  final AppLocalizations l10n;
  final String unitSystem;
  final int monthlyWorkouts;
  final double monthlyVolumeKg;
  final int monthlyPrCount;
  final int streakWeeks;

  const ProgressStatsGrid({
    super.key,
    required this.l10n,
    required this.unitSystem,
    required this.monthlyWorkouts,
    required this.monthlyVolumeKg,
    required this.monthlyPrCount,
    required this.streakWeeks,
  });

  @override
  Widget build(BuildContext context) {
    const gap = 10.0;
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.fitness_center,
                  label: l10n.progressStatsMonthlyWorkouts,
                  value: '$monthlyWorkouts',
                  accent: context.accentColor,
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: _StatTile(
                  icon: Icons.trending_up,
                  label: l10n.progressStatsMonthlyVolume,
                  value:
                      UnitConverter.formatVolume(monthlyVolumeKg, unitSystem),
                  accent: const Color(0xFF5BB8F0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.emoji_events_outlined,
                  label: l10n.progressStatsMonthlyPrs,
                  value: '$monthlyPrCount',
                  accent: const Color(0xFFFFD54F),
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department,
                  label: l10n.streakLabel,
                  value: l10n.progressStreakWeeks(streakWeeks),
                  accent: context.accentDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
