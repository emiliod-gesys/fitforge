import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../providers/app_providers.dart';
import '../services/exercise_service.dart';
import 'exercise_category_mannequin.dart';

/// Pantalla completa para ver la ilustración de un ejercicio (con zoom).
class ExerciseImageViewer extends ConsumerWidget {
  final String exerciseId;
  final String exerciseName;
  final String? category;
  final List<String> muscles;

  const ExerciseImageViewer({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    this.category,
    this.muscles = const [],
  });

  static Future<void> open(
    BuildContext context, {
    required String exerciseId,
    required String exerciseName,
    String? category,
    List<String> muscles = const [],
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ExerciseImageViewer(
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              category: category,
              muscles: muscles,
            ),
          );
        },
      ),
    );
  }

  ExerciseImageLookup get _lookup => ExerciseImageLookup(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
      );

  bool _isAssetPath(String url) => url.startsWith('assets/');

  bool _isLocalPath(String url) {
    return !url.startsWith('http://') && !url.startsWith('https://');
  }

  ({String? category, List<String> muscles}) _resolveMeta(WidgetRef ref) {
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

    return (category: resolvedCategory, muscles: resolvedMuscles);
  }

  Widget _fallback(WidgetRef ref, {bool loading = false}) {
    final meta = _resolveMeta(ref);
    final size = MediaQuery.sizeOf(ref.context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ExerciseCategoryMannequin(
        category: meta.category,
        muscles: meta.muscles,
        height: size.height * 0.55,
        fullWidth: true,
        borderRadius: BorderRadius.circular(16),
        loading: loading,
      ),
    );
  }

  Widget _zoomableIllustration(Widget child) {
    return InteractiveViewer(
      minScale: 0.75,
      maxScale: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: AppColors.exerciseIllustrationBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final urlAsync = ref.watch(exerciseImageUrlProvider(_lookup));
    final maxWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: urlAsync.when(
                data: (url) {
                  if (url != null && _isAssetPath(url)) {
                    return _zoomableIllustration(
                      Image.asset(
                        url,
                        fit: BoxFit.contain,
                        width: maxWidth,
                      ),
                    );
                  }
                  if (url != null && _isLocalPath(url)) {
                    return _zoomableIllustration(
                      Image.file(
                        File(url),
                        fit: BoxFit.contain,
                        width: maxWidth,
                      ),
                    );
                  }
                  if (url != null) {
                    return _zoomableIllustration(
                      CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        width: maxWidth,
                        placeholder: (_, __) => _fallback(ref, loading: true),
                        errorWidget: (_, __, ___) => _fallback(ref),
                      ),
                    );
                  }
                  return _fallback(ref);
                },
                loading: () => _fallback(ref, loading: true),
                error: (_, __) => _fallback(ref),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                tooltip: l10n.close,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
