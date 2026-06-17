import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

/// Miniatura de ejercicio: usa [imageUrl] guardada o consulta wger por [exerciseId].
class ExerciseThumbnail extends ConsumerWidget {
  final String? imageUrl;
  final String exerciseId;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final bool fullWidth;

  const ExerciseThumbnail({
    super.key,
    this.imageUrl,
    required this.exerciseId,
    this.width = 56,
    this.height = 56,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.fullWidth = false,
  });

  int? get _wgerId {
    final id = int.tryParse(exerciseId);
    if (id == null || id < 0) return null;
    return id;
  }

  Widget _placeholder({bool loading = false}) {
    final box = Container(
      width: fullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: borderRadius,
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.fitness_center, color: Colors.white38),
    );
    return box;
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
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _networkImage(imageUrl!);
    }

    final wgerId = _wgerId;
    if (wgerId == null) return _placeholder();

    final media = ref.watch(exerciseMediaProvider(wgerId));
    return media.when(
      data: (m) => m.imageUrl != null ? _networkImage(m.imageUrl!) : _placeholder(),
      loading: () => _placeholder(loading: true),
      error: (_, __) => _placeholder(),
    );
  }
}
