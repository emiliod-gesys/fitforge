import 'package:flutter/material.dart';
import 'package:flutter_body_heatmap/flutter_body_heatmap.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/exercise_category_illustration.dart';
import 'exercise_placeholder.dart';

/// Maniquí compacto con el grupo muscular de la categoría resaltado en rojo.
class ExerciseCategoryMannequin extends StatelessWidget {
  final String? category;
  final List<String> muscles;
  final double? width;
  final double height;
  final BorderRadius borderRadius;
  final bool fullWidth;
  final bool loading;

  const ExerciseCategoryMannequin({
    super.key,
    this.category,
    this.muscles = const [],
    this.width = 56,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.fullWidth = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return ExercisePlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
        fullWidth: fullWidth,
        loading: true,
      );
    }

    final config = ExerciseCategoryIllustration.resolve(
      category: category,
      muscles: muscles,
    );
    if (config == null) {
      return ExercisePlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
        fullWidth: fullWidth,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: fullWidth ? double.infinity : width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 100,
            height: 200,
            child: BodyHeatmap(
              side: config.side,
              gender: BodyGender.male,
              data: config.data,
              colors: ExerciseCategoryIllustration.highlightColors,
              bodyColor: const Color(0xFF343A42),
              borderColor: const Color(0xFF252A30),
              showBorder: true,
            ),
          ),
        ),
      ),
    );
  }
}
