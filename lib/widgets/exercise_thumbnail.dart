import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/exercise_service.dart';
import 'exercise_placeholder.dart';

/// Miniatura de ejercicio: URL guardada, ID wger, búsqueda por nombre o video.
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

  Widget _placeholder({bool loading = false}) {
    return ExercisePlaceholder(
      width: width,
      height: height,
      borderRadius: borderRadius,
      fullWidth: fullWidth,
      loading: loading,
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
