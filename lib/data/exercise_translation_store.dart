import 'dart:convert';

import 'package:flutter/services.dart';

/// Traducción guardada de un ejercicio wger (nombre + descripción).
class ExerciseTranslation {
  final String name;
  final String description;

  const ExerciseTranslation({
    required this.name,
    this.description = '',
  });

  factory ExerciseTranslation.fromJson(Map<String, dynamic> json) {
    return ExerciseTranslation(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// Catálogo local ES/EN por `wger_id`, generado con `tool/generate_exercise_translations.dart`.
class ExerciseTranslationStore {
  Map<String, Map<String, ExerciseTranslation>> _byId = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;

    final raw = await rootBundle.loadString('assets/data/exercise_translations.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    final parsed = <String, Map<String, ExerciseTranslation>>{};
    decoded.forEach((id, value) {
      if (value is! Map<String, dynamic>) return;
      final locales = <String, ExerciseTranslation>{};
      for (final code in ['es', 'en']) {
        final entry = value[code];
        if (entry is Map<String, dynamic>) {
          locales[code] = ExerciseTranslation.fromJson(entry);
        }
      }
      if (locales.isNotEmpty) parsed[id] = locales;
    });

    _byId = parsed;
    _loaded = true;
  }

  ExerciseTranslation? get(int? wgerId, String locale) {
    if (wgerId == null || wgerId < 0) return null;
    final locales = _byId['$wgerId'];
    if (locales == null) return null;

    final code = locale == 'en' ? 'en' : 'es';
    return locales[code] ?? locales['es'] ?? locales['en'];
  }

  String? nameFor(int? wgerId, String locale) {
    final t = get(wgerId, locale);
    final name = t?.name.trim();
    return name != null && name.isNotEmpty ? name : null;
  }

  String resolveName({
    required String exerciseId,
    required String fallback,
    required String locale,
  }) {
    final parsed = int.tryParse(exerciseId);
    if (parsed != null) {
      final stored = nameFor(parsed, locale);
      if (stored != null) return stored;
    }
    return fallback;
  }
}
