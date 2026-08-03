import 'package:flutter/material.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

enum FfButtonVariant { primary, secondary, ghost }

class FfButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FfButtonVariant variant;
  final bool loading;
  final bool expanded;

  const FfButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = FfButtonVariant.primary,
    this.loading = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    final enabled = onPressed != null && !loading;
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == FfButtonVariant.primary ? Colors.black : accent,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppTokens.space8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          );

    final button = switch (variant) {
      FfButtonVariant.primary => FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
            disabledBackgroundColor: AppColors.slate,
            minimumSize: Size(expanded ? double.infinity : 120, AppTokens.buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusMd),
          ),
          child: child,
        ),
      FfButtonVariant.secondary => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
            minimumSize: Size(expanded ? double.infinity : 120, AppTokens.buttonHeight),
            shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusMd),
          ),
          child: child,
        ),
      FfButtonVariant.ghost => TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: accent,
            minimumSize: Size(expanded ? double.infinity : 0, AppTokens.buttonHeightSm),
          ),
          child: child,
        ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
