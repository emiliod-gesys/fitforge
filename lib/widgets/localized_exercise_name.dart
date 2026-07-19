import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/cloud_exercise_catalog.dart';
import '../core/utils/cloud_exercise_name_localizer.dart';
import '../providers/app_providers.dart';

/// Nombre de ejercicio según idioma del perfil (catálogo local → nombre guardado).
class LocalizedExerciseName extends ConsumerWidget {
  final String exerciseId;
  final String fallbackName;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const LocalizedExerciseName(
    this.fallbackName, {
    super.key,
    required this.exerciseId,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(preferredLanguageProvider);
    final store = ref.watch(exerciseTranslationStoreProvider);
    final catalog = ref.watch(exercisesProvider).valueOrNull;

    var name = store.resolveName(
      exerciseId: exerciseId,
      fallback: fallbackName,
      locale: lang,
    );

    if (CloudExerciseCatalogIds.isCloudId(exerciseId)) {
      name = CloudExerciseNameLocalizer.localize(
        nameEn: fallbackName,
        nameEs: fallbackName,
        locale: lang,
      );
    } else if (name == fallbackName && catalog != null) {
      final match = ref.read(exerciseServiceProvider).findInCatalog(
            exerciseId: exerciseId,
            exerciseName: fallbackName,
            catalog: catalog,
          );
      if (match != null) name = match.name;
    }

    return Text(
      name,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
