import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/manual_food_template.dart';

/// Biblioteca local de alimentos registrados manualmente (sin IA).
/// Una clave por cuenta: el teléfono no debe mostrar la comida de otro usuario.
class LocalManualFoodStore {
  static const _storageKeyPrefix = 'manual_food_templates_v1_';
  final _uuid = const Uuid();

  String _storageKey(String userId) => '$_storageKeyPrefix$userId';

  Future<List<ManualFoodTemplate>> getAll(String userId) async {
    if (userId.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(userId));
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

  Future<List<ManualFoodTemplate>> search(
    String userId, {
    String? query,
    int limit = 30,
  }) async {
    final all = await getAll(userId);
    final q = query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return all.take(limit).toList();

    return all
        .where((item) => item.name.toLowerCase().contains(q))
        .take(limit)
        .toList();
  }

  Future<ManualFoodTemplate> save({
    required String userId,
    String? id,
    required String name,
    required int caloriesKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    double fiberG = 0,
    String? servingDescription,
  }) async {
    if (userId.isEmpty) {
      throw ArgumentError('userId is required');
    }
    final all = await getAll(userId);
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

    await _persist(userId, updated);
    return template;
  }

  Future<void> delete(String userId, String id) async {
    if (userId.isEmpty) return;
    final all = await getAll(userId);
    await _persist(userId, all.where((item) => item.id != id).toList());
  }

  Future<void> _persist(String userId, List<ManualFoodTemplate> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey(userId), encoded);
  }
}
