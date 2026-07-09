import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/utils/json_parsing.dart';
import '../models/exercise.dart';
import '../models/exercise_logging.dart';

/// Catálogo curado de FitForge (`assets/data/exercise_catalog.json`).
abstract final class BundledExerciseCatalog {
  static String? _cachedLocale;
  static List<Exercise>? _cache;

  static Future<List<Exercise>> load({required String locale}) async {
    final lang = locale == 'en' ? 'en' : 'es';
    if (_cache != null && _cachedLocale == lang) {
      return _cache!;
    }

    final raw = await rootBundle.loadString('assets/data/exercise_catalog.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = decoded['exercises'] as List? ?? [];

    final exercises = <Exercise>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final exercise = _parseEntry(item, lang);
      if (exercise != null) exercises.add(exercise);
    }

    exercises.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _cache = exercises;
    _cachedLocale = lang;
    return exercises;
  }

  static void clearCache() {
    _cache = null;
    _cachedLocale = null;
  }

  static Exercise? _parseEntry(Map<String, dynamic> json, String lang) {
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) return null;

    final loggingType = ExerciseLoggingType.fromJson(json['loggingType'] as String?);
    final loadMode = ExerciseLoadMode.fromJson(json['loadMode'] as String?);
    final cardioPresetName = json['cardioPreset'] as String?;
    CardioLoggingConfig? cardioConfig;
    if (loggingType == ExerciseLoggingType.cardio) {
      final preset = CardioPreset.values.firstWhere(
        (p) => p.name == cardioPresetName,
        orElse: () => CardioPreset.custom,
      );
      cardioConfig = CardioLoggingConfig.fromPreset(preset);
    }

    final primary = _localizedString(json['primaryMuscle'], lang);
    final secondary = _localizedStringList(json['secondaryMuscles'], lang);
    final muscles = <String>[
      if (primary.isNotEmpty) primary,
      ...secondary,
    ];

    final equipmentLabel = _localizedString(json['equipment'], lang);

    return Exercise(
      catalogId: id,
      name: _localizedString(json['names'], lang),
      description: _localizedString(json['descriptions'], lang),
      category: _localizedString(json['category'], lang),
      muscles: muscles,
      equipment: equipmentLabel.isEmpty ? const [] : [equipmentLabel],
      imageUrl: json['imageUrl'] as String?,
      aliases: _localizedStringList(json['aliases'], lang),
      loggingType: loggingType,
      cardioConfig: cardioConfig,
      loadMode: loadMode,
      perArmWeight: parseJsonBool(json['perArmWeight']),
      unilateral: parseJsonBool(json['unilateral']),
      weightOptional: json.containsKey('weightOptional')
          ? parseJsonBool(json['weightOptional'])
          : (loadMode.weightOptional || loggingType == ExerciseLoggingType.cardio),
      isBundled: true,
    );
  }

  static String _localizedString(Map<String, dynamic>? map, String lang) {
    if (map == null) return '';
    return (map[lang] as String?)?.trim() ?? (map['es'] as String?)?.trim() ?? '';
  }

  static List<String> _localizedStringList(Map<String, dynamic>? map, String lang) {
    if (map == null) return const [];
    final list = map[lang] ?? map['es'];
    if (list is! List) return const [];
    return list.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
}
