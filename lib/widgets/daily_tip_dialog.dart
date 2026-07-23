import 'package:flutter/material.dart';

import '../core/content/fitness_daily_tips.dart';
import '../core/l10n/app_locale.dart';
import '../core/theme/app_accent.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';

Future<void> showDailyTipDialog(
  BuildContext context, {
  required FitnessDailyTip tip,
  required String languageCode,
}) {
  final l10n = AppLocale.localizations(languageCode);

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (ctx) {
      final accent = ctx.fitForgeAccent;
      final isMyth = tip.kind == FitnessDailyTipKind.myth;
      final categoryLabel = isMyth ? l10n.dailyTipCategoryMyth : l10n.dailyTipCategoryTip;
      final categoryColor = isMyth ? AppColors.error.withValues(alpha: 0.9) : accent.accentColor;

      return AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: accent.accentColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.dailyTipOfDayTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: categoryColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                categoryLabel,
                style: TextStyle(
                  color: categoryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.dailyTipBody(tip.id),
              style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.dailyTipGotIt),
          ),
        ],
      );
    },
  );
}
