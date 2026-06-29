import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/manual_food_template.dart';

/// Biblioteca local de alimentos registrados manualmente (sin IA).
class LocalManualFoodStore {
  static const _storageKey = 'manual_food_templates_v1';
  final _uuid = const Uuid();

  Future<List<ManualFoodTemplate>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => ManualFoodTemplate.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return const [];
    }
  }

  Future<List<ManualFoodTemplate>> search({String? query, int limit = 30}) async {
    final all = await getAll();
    final q = query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return all.take(limit).toList();

    return all
        .where((item) => item.name.toLowerCase().contains(q))
        .take(limit)
        .toList();
  }

  Future<ManualFoodTemplate> save({
    String? id,
    required String name,
    required int caloriesKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    double fiberG = 0,
    String? servingDescription,
  }) async {
    final all = await getAll();
    final now = DateTime.now().toUtc();
    final template = ManualFoodTemplate(
      id: id ?? _uuid.v4(),
      name: name.trim(),
      caloriesKcal: caloriesKcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      servingDescription: servingDescription?.trim().isEmpty == true ? null : servingDescription?.trim(),
      updatedAt: now,
    );

    final updated = [
      template,
      ...all.where((item) => item.id != template.id),
    ];

    await _persist(updated);
    return template;
  }

  Future<void> delete(String id) async {
    final all = await getAll();
    await _persist(all.where((item) => item.id != id).toList());
  }

  Future<void> _persist(List<ManualFoodTemplate> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
