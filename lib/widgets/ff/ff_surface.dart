import 'package:flutter/material.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Superficie premium (card) con borde sutil o acento seleccionado.
class FfSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final bool elevated;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Gradient? gradient;

  const FfSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.space16),
    this.selected = false,
    this.elevated = false,
    this.onTap,
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    final radius = AppTokens.borderRadiusLg;
    final decoration = BoxDecoration(
      color: gradient == null
          ? (elevated ? AppColors.cardElevated : AppColors.card)
          : null,
      gradient: gradient,
      borderRadius: radius,
      border: Border.all(
        color: borderColor ??
            (selected ? accent : AppColors.border.withValues(alpha: 0.75)),
        width: selected ? AppTokens.borderAccent : AppTokens.borderHairline,
      ),
      boxShadow: selected
          ? [
              BoxShadow(
                color: accent.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );

    final content = Padding(padding: padding, child: child);
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(decoration: decoration, child: content),
      ),
    );
  }
}
