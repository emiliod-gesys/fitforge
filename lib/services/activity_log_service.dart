import 'package:uuid/uuid.dart';

import '../core/utils/supabase_datetime.dart';
import '../models/manual_activity_entry.dart';
import 'supabase_service.dart';

class ActivityLogService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  Future<List<ManualActivityEntry>> getEntriesForDay(DateTime day, {String? userId}) async {
    final uid = userId ?? SupabaseService.currentUser?.id;
    if (uid == null) return [];

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final data = await _client
        .from('manual_activity_entries')
        .select()
        .eq('user_id', uid)
        .gte('logged_at', start.toUtc().toIso8601String())
        .lt('logged_at', end.toUtc().toIso8601String())
        .order('logged_at', ascending: true);

    return (data as List)
        .map((row) => ManualActivityEntry.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<ManualActivityEntry>> getEntriesSince(
    DateTime startInclusive, {
    String? userId,
  }) async {
    final uid = userId ?? SupabaseService.currentUser?.id;
    if (uid == null) return [];

    final data = await _client
        .from('manual_activity_entries')
        .select()
        .eq('user_id', uid)
        .gte('logged_at', startInclusive.toUtc().toIso8601String())
        .order('logged_at', ascending: true);

    return (data as List)
        .map((row) => ManualActivityEntry.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<ManualActivityEntry> addEntry({
    required String name,
    required int caloriesKcal,
    DateTime? loggedAt,
  }) async {
    final userId = SupabaseService.currentUser!.id;
    final id = _uuid.v4();
    final at = loggedAt ?? SupabaseDateTime.nowUtc;

    final payload = {
      'id': id,
      'user_id': userId,
      ...ManualActivityEntry(
        id: id,
        userId: userId,
        loggedAt: at,
        name: name,
        caloriesKcal: caloriesKcal,
      ).toInsertJson(),
    };

    await _client.from('manual_activity_entries').insert(payload);

    return ManualActivityEntry(
      id: id,
      userId: userId,
      loggedAt: at,
      name: name,
      caloriesKcal: caloriesKcal,
    );
  }

  Future<void> deleteEntry(String id) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    await _client.from('manual_activity_entries').delete().eq('id', id).eq('user_id', userId);
  }
}
