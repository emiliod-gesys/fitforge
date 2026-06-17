import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/exercise_service.dart';
import 'exercise_placeholder.dart';

/// Miniatura de ejercicio: URL guardada, ID wger, búsqueda por nombre, video o imagen similar.
class ExerciseThumbnail extends ConsumerWidget {
  final String? imageUrl;
  final String exerciseId;
  final String exerciseName;
  final String? category;
  final List<String> muscles;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final bool fullWidth;

  const ExerciseThumbnail({
    super.key,
    this.imageUrl,
    required this.exerciseId,
    required this.exerciseName,
    this.category,
    this.muscles = const [],
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

  ({String? category, List<String> muscles}) _placeholderMeta(WidgetRef ref) {
    var resolvedCategory = category;
    var resolvedMuscles = muscles;

    if (resolvedCategory == null || resolvedMuscles.isEmpty) {
      final catalog = ref.watch(exercisesProvider).valueOrNull;
      if (catalog != null) {
        final match = ref.read(exerciseServiceProvider).findInCatalog(
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              catalog: catalog,
            );
        resolvedCategory ??= match?.category;
        if (resolvedMuscles.isEmpty) {
          resolvedMuscles = match?.muscles ?? const [];
        }
      }
    }

    return (category: resolvedCategory, muscles: resolvedMuscles);
  }

  Widget _placeholder(WidgetRef ref, {bool loading = false}) {
    final meta = _placeholderMeta(ref);
    return ExercisePlaceholder(
      category: meta.category,
      muscles: meta.muscles,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fullWidth: fullWidth,
      loading: loading,
      iconSize: fullWidth ? 64 : 26,
    );
  }

  Widget _networkImage(String url, WidgetRef ref) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: url,
        width: fullWidth ? double.infinity : width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(ref, loading: true),
        errorWidget: (_, __, ___) => _placeholder(ref),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(exerciseImageUrlProvider(_lookup));
    return urlAsync.when(
      data: (url) => url != null ? _networkImage(url, ref) : _placeholder(ref),
      loading: () => _placeholder(ref, loading: true),
      error: (_, __) => _placeholder(ref),
    );
  }
}
