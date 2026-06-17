import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../services/exercise_service.dart';

/// Miniatura de ejercicio: URL guardada, ID wger o búsqueda por nombre en catálogo.
class ExerciseThumbnail extends ConsumerWidget {
  final String? imageUrl;
  final String exerciseId;
  final String exerciseName;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final bool fullWidth;

  const ExerciseThumbnail({
    super.key,
    this.imageUrl,
    required this.exerciseId,
    required this.exerciseName,
    this.width = 56,
    this.height = 56,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.fullWidth = false,
  });

  ExerciseImageLookup get _lookup => ExerciseImageLookup(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        imageUrl: imageUrl,
      );

  Widget _placeholder({bool loading = false}) {
    return Container(
      width: fullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: loading
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : const Icon(Icons.fitness_center, color: AppColors.textMuted, size: 26),
    );
  }

  Widget _networkImage(String url) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: url,
        width: fullWidth ? double.infinity : width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(loading: true),
        errorWidget: (_, __, ___) => _placeholder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(exerciseImageUrlProvider(_lookup));
    return urlAsync.when(
      data: (url) => url != null ? _networkImage(url) : _placeholder(),
      loading: () => _placeholder(loading: true),
      error: (_, __) => _placeholder(),
    );
  }
}
