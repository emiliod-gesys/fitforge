import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/exercise_service.dart';
import 'exercise_category_mannequin.dart';

/// Miniatura: foto wger (`exerciseinfo`) → maniquí por categoría → isotipo FitForge.
class ExerciseThumbnail extends ConsumerWidget {
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
      );

  Widget _categoryFallback({
    required WidgetRef ref,
    bool loading = false,
  }) {
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
        if (match != null) {
          resolvedCategory ??= match.category;
          if (resolvedMuscles.isEmpty) resolvedMuscles = match.muscles;
        }
      }
    }

    return ExerciseCategoryMannequin(
      category: resolvedCategory,
      muscles: resolvedMuscles,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fullWidth: fullWidth,
      loading: loading,
    );
  }

  Widget _placeholder({required WidgetRef ref, bool loading = false}) {
    return _categoryFallback(ref: ref, loading: loading);
  }

  bool _isLocalPath(String url) {
    return !url.startsWith('http://') && !url.startsWith('https://');
  }

  Widget _localImage(String path, WidgetRef ref) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.file(
        File(path),
        width: fullWidth ? double.infinity : width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _categoryFallback(ref: ref),
      ),
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
        placeholder: (_, __) => _placeholder(ref: ref, loading: true),
        errorWidget: (_, __, ___) => _placeholder(ref: ref),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(exerciseImageUrlProvider(_lookup));
    return urlAsync.when(
      data: (url) {
        if (url != null && _isLocalPath(url)) return _localImage(url, ref);
        if (url != null) return _networkImage(url, ref);
        return _categoryFallback(ref: ref);
      },
      loading: () => _categoryFallback(ref: ref, loading: true),
      error: (_, __) => _categoryFallback(ref: ref),
    );
  }
}
