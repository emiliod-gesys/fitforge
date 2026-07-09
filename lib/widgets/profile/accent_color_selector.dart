import 'package:flutter/material.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';

class AccentColorSelector extends StatelessWidget {
  final AppAccent selected;
  final ValueChanged<AppAccent> onChanged;

  const AccentColorSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppAccent.values.map((accent) {
        final isSelected = accent == selected;
        return InkWell(
          onTap: () => onChanged(accent),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 72,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.primary,
                    border: Border.all(
                      color: isSelected ? AppColors.textPrimary : AppColors.border,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accent.primary.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black, size: 20)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.accentLabel(accent),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? context.accentColor : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
