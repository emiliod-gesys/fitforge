import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trainer.dart';
import '../profile_avatar.dart';

class ProgressTrainerCard extends StatelessWidget {
  final MyTrainerView trainerView;
  final AppLocalizations l10n;

  const ProgressTrainerCard({
    super.key,
    required this.trainerView,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final trainer = trainerView.trainer;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            ProfileAvatar(
              avatarUrl: trainer.avatarUrl,
              radius: 24,
              fallbackLetter: trainer.label,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.progressMyTrainerLabel,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trainer.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.school_outlined, color: AppColors.orange, size: 28),
          ],
        ),
      ),
    );
  }
}
