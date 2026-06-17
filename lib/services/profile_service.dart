import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/player_level.dart';
import '../core/utils/unit_converter.dart';
import '../models/body_metric.dart';
import '../models/profile.dart';
import 'supabase_service.dart';

class ProfileService {
  final _client = SupabaseService.client;
  final _secureStorage = const FlutterSecureStorage();
  final _uuid = const Uuid();

  static const _openAiKeyStorage = 'openai_api_key';
  static const _geminiKeyStorage = 'gemini_api_key';

  Future<UserProfile?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;

    final provider = response['ai_provider'] as String?;
    final hasKey = await _hasKeyForProvider(provider);
    return UserProfile.fromJson(response, hasAiKey: hasKey);
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await _client.from('profiles').upsert({
      'id': profile.id,
      ...profile.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final payload = {
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (data.containsKey('display_name') && data['display_name'] != null) {
      payload['search_name'] = (data['display_name'] as String).toLowerCase();
    }
    await _client.from('profiles').update(payload).eq('id', user.id);
  }

  Future<void> saveApiKey(AiProvider provider, String apiKey) async {
    final key = provider == AiProvider.openai ? _openAiKeyStorage : _geminiKeyStorage;
    await _secureStorage.write(key: key, value: apiKey);
    await updateProfile({'ai_provider': provider.name});
  }

  Future<String?> getApiKey(AiProvider provider) async {
    final key = provider == AiProvider.openai ? _openAiKeyStorage : _geminiKeyStorage;
    return _secureStorage.read(key: key);
  }

  Future<void> deleteApiKey(AiProvider provider) async {
    final key = provider == AiProvider.openai ? _openAiKeyStorage : _geminiKeyStorage;
    await _secureStorage.delete(key: key);
  }

  Future<bool> _hasKeyForProvider(String? provider) async {
    if (provider == 'openai') {
      return (await _secureStorage.read(key: _openAiKeyStorage))?.isNotEmpty ?? false;
    }
    if (provider == 'gemini') {
      return (await _secureStorage.read(key: _geminiKeyStorage))?.isNotEmpty ?? false;
    }
    return false;
  }

  Future<Map<String, BodyMetricSnapshot>> getBodyMetricSnapshots() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final data = await _client
        .from('body_measurements')
        .select()
        .eq('user_id', user.id)
        .order('measured_at', ascending: false)
        .limit(500);

    final byType = <String, List<BodyMeasurement>>{};
    for (final row in data as List) {
      final m = BodyMeasurement.fromJson(row as Map<String, dynamic>);
      byType.putIfAbsent(m.type, () => []).add(m);
    }

    final profileRow = await _client
        .from('profiles')
        .select('body_weight')
        .eq('id', user.id)
        .maybeSingle();
    final profileWeight = (profileRow?['body_weight'] as num?)?.toDouble();

    final snapshots = <String, BodyMetricSnapshot>{};
    for (final def in BodyMetricDefinition.all) {
      final entries = byType[def.key];
      if (entries == null || entries.isEmpty) {
        if (def.key == 'weight' && profileWeight != null) {
          snapshots[def.key] = BodyMetricSnapshot(
            type: def.key,
            valueKg: profileWeight,
          );
        } else {
          snapshots[def.key] = BodyMetricSnapshot(type: def.key);
        }
        continue;
      }

      final latest = entries.first;
      final previous = entries.length > 1 ? entries[1] : null;
      final isMass = def.kind == BodyMetricKind.mass;

      snapshots[def.key] = BodyMetricSnapshot(
        type: def.key,
        valueKg: isMass ? latest.value : null,
        rawValue: isMass ? null : latest.value,
        deltaKg: isMass && previous != null ? latest.value - previous.value : null,
        deltaRaw: !isMass && previous != null ? latest.value - previous.value : null,
        measuredAt: latest.measuredAt,
      );
    }

    return snapshots;
  }

  Future<void> saveBodyMetric({
    required String type,
    required double displayValue,
    required String unitSystem,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final def = BodyMetricDefinition.forKey(type);
    if (def == null) return;

    final storedValue = def.kind == BodyMetricKind.mass
        ? UnitConverter.displayToKg(displayValue, unitSystem)
        : displayValue;
    final storedUnit = def.kind == BodyMetricKind.mass ? 'kg' : def.unitLabel(unitSystem);

    await _client.from('body_measurements').insert({
      'id': _uuid.v4(),
      'user_id': user.id,
      'type': type,
      'value': storedValue,
      'unit': storedUnit,
      'measured_at': DateTime.now().toIso8601String(),
    });

    if (type == 'weight') {
      await updateProfile({'body_weight': storedValue});
    }
  }

  Future<void> updateUnitSystem(String unitSystem) async {
    await updateProfile({'unit_system': unitSystem});
  }

  Future<XpAwardResult?> awardWorkoutXp({
    required String workoutId,
    required double totalVolumeKg,
    required int streakWeeks,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final workoutRow = await _client
        .from('workouts')
        .select('xp_awarded, user_id')
        .eq('id', workoutId)
        .maybeSingle();

    if (workoutRow == null || workoutRow['user_id'] != user.id) return null;
    if (workoutRow['xp_awarded'] != null) return null;

    final xpEarned = PlayerLevelCalculator.xpFromWorkoutVolume(
      volumeKg: totalVolumeKg,
      streakWeeks: streakWeeks,
    );
    final multiplier = PlayerLevelCalculator.streakMultiplier(streakWeeks);

    final profileRow = await _client
        .from('profiles')
        .select('total_xp')
        .eq('id', user.id)
        .single();

    final previousTotal = (profileRow['total_xp'] as num?)?.toInt() ?? 0;
    final before = PlayerLevelCalculator.fromTotalXp(previousTotal);
    final newTotal = previousTotal + xpEarned;
    final after = PlayerLevelCalculator.fromTotalXp(newTotal);

    await _client.from('profiles').update({
      'total_xp': newTotal,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    await _client.from('workouts').update({'xp_awarded': xpEarned}).eq('id', workoutId);

    return XpAwardResult(
      xpEarned: xpEarned,
      streakWeeks: streakWeeks,
      streakMultiplier: multiplier,
      before: before,
      after: after,
    );
  }
}
