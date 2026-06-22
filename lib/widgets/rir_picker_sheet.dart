import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Pregunta RIR (reps en reserva) tras completar una serie de fuerza.
abstract final class RirPickerSheet {
  static Future<int?> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<int?>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.rirPickerTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.rirPickerSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    for (final rir in const [3, 2, 1, 0]) ...[
                      if (rir != 3) const SizedBox(width: 10),
                      Expanded(child: _RirOption(rir: rir, l10n: l10n)),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.rirPickerSkip),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RirOption extends StatelessWidget {
  final int rir;
  final AppLocalizations l10n;

  const _RirOption({required this.rir, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final label = rir == 3 ? '+3' : '$rir';
    return Material(
      color: AppColors.cardElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Navigator.pop(context, rir),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.rirPickerRepsLeft,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
