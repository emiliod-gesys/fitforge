import 'package:uuid/uuid.dart';

import '../core/utils/supabase_datetime.dart';
import '../models/food_entry.dart';
import 'supabase_service.dart';

class FoodService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  Future<List<FoodEntry>> getEntriesForDay(DateTime day, {String? userId}) async {
    final uid = userId ?? SupabaseService.currentUser?.id;
    if (uid == null) return [];

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final data = await _client
        .from('food_entries')
        .select()
        .eq('user_id', uid)
        .gte('logged_at', start.toUtc().toIso8601String())
        .lt('logged_at', end.toUtc().toIso8601String())
        .order('logged_at', ascending: true);

    return (data as List)
        .map((row) => FoodEntry.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<FoodEntry>> getRecentEntries({int limit = 20}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('food_entries')
        .select()
        .eq('user_id', userId)
        .order('logged_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((row) => FoodEntry.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// Alimentos únicos registrados antes (para pestaña Search).
  Future<List<FoodEntry>> getDistinctRecentFoods({
    String? query,
    int limit = 30,
  }) async {
    final recent = await getRecentEntries(limit: 120);
    final seen = <String>{};
    final result = <FoodEntry>[];
    final q = query?.trim().toLowerCase();

    for (final entry in recent) {
      final key = '${entry.name.toLowerCase()}|${entry.brand?.toLowerCase() ?? ''}';
      if (seen.contains(key)) continue;

      if (q != null && q.isNotEmpty) {
        final haystack = '${entry.name} ${entry.brand ?? ''}'.toLowerCase();
        if (!haystack.contains(q)) continue;
      }

      seen.add(key);
      result.add(entry);
      if (result.length >= limit) break;
    }

    return result;
  }

  Future<FoodEntry> addEntry({
    required MealType mealType,
    required String name,
    required int caloriesKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    double fiberG = 0,
    String? brand,
    String? servingDescription,
    FoodEntrySource source = FoodEntrySource.manual,
    String? notes,
    DateTime? loggedAt,
  }) async {
    final userId = SupabaseService.currentUser!.id;
    final id = _uuid.v4();
    final at = loggedAt ?? SupabaseDateTime.nowUtc;

    final payload = {
      'id': id,
      'user_id': userId,
      ...FoodEntry(
        id: id,
        userId: userId,
        loggedAt: at,
        mealType: mealType,
        name: name,
        brand: brand,
        caloriesKcal: caloriesKcal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        fiberG: fiberG,
        servingDescription: servingDescription,
        source: source,
        notes: notes,
      ).toInsertJson(),
    };

    await _client.from('food_entries').insert(payload);

    return FoodEntry(
      id: id,
      userId: userId,
      loggedAt: at,
      mealType: mealType,
      name: name,
      brand: brand,
      caloriesKcal: caloriesKcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      servingDescription: servingDescription,
      source: source,
      notes: notes,
    );
  }

  Future<void> deleteEntry(String id) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    await _client.from('food_entries').delete().eq('id', id).eq('user_id', userId);
  }
}
