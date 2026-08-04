import 'package:flutter/material.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Opción tappable con borde, fondo y indicador de selección (estilo onboarding).
class FfSelectableTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badge;
  final bool selected;
  final Color? accent;
  final VoidCallback onTap;

  const FfSelectableTile({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    required this.selected,
    this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? context.accentColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space8),
      child: Material(
        color: selected ? accentColor.withValues(alpha: 0.12) : AppColors.card,
        borderRadius: AppTokens.borderRadiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.borderRadiusMd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(AppTokens.space14),
            decoration: BoxDecoration(
              borderRadius: AppTokens.borderRadiusMd,
              border: Border.all(
                color: selected ? accentColor : AppColors.border.withValues(alpha: 0.7),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (badge != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.space8,
                            vertical: AppTokens.space4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.space4),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? accentColor : AppColors.textMuted.withValues(alpha: 0.55),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
