import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'fitforge_logo.dart';
import '../core/theme/app_accent.dart';

/// Placeholder con logo FitForge cuando el ejercicio no tiene imagen.
class ExercisePlaceholder extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;
  final bool fullWidth;
  final bool loading;

  const ExercisePlaceholder({
    super.key,
    this.width = 56,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.fullWidth = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = fullWidth
        ? 80.0
        : (height * 0.55).clamp(24.0, 40.0);

    return Container(
      width: fullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: loading
          ? Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: context.accentColor),
              ),
            )
          : Center(
              child: FitForgeLogo.icon(height: logoSize),
            ),
    );
  }
}
