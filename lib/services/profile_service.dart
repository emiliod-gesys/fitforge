import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../core/config/ai_secrets.dart';
import '../core/utils/player_level.dart';
import '../core/utils/unit_converter.dart';
import '../core/utils/bmr_calculator.dart';
import '../models/body_metric.dart';
import '../models/profile.dart';
import 'supabase_service.dart';

class ProfileService {
  final _client = SupabaseService.client;
  final _secureStorage = const FlutterSecureStorage();
  final _uuid = const Uuid();

  static const _openAiKeyStorage = 'openai_api_key';
  static const _geminiKeyStorage = 'gemini_api_key';
  static const _anthropicKeyStorage = 'anthropic_api_key';

  static String _storageKeyFor(AiProvider provider) => switch (provider) {
        AiProvider.openai => _openAiKeyStorage,
        AiProvider.gemini => _geminiKeyStorage,
        AiProvider.anthropic => _anthropicKeyStorage,
        AiProvider.none => throw ArgumentError('AiProvider.none has no storage key'),
      };

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
    await _secureStorage.write(key: _storageKeyFor(provider), value: apiKey);
    await updateProfile({'ai_provider': provider.name});
  }

  Future<String?> getApiKey(AiProvider provider) async {
    if (provider == AiProvider.none) return null;

    final stored = await getUserStoredApiKey(provider);
    if (stored != null && stored.isNotEmpty) return stored;

    if (provider == AiProvider.openai) return AiSecrets.openAiDefaultKey;
    return null;
  }

  /// Solo la key guardada por el usuario (no incluye la embebida de respaldo).
  Future<String?> getUserStoredApiKey(AiProvider provider) async {
    if (provider == AiProvider.none) return null;
    return _secureStorage.read(key: _storageKeyFor(provider));
  }

  /// Proveedor efectivo cuando el perfil no tiene uno configurado pero hay key embebida.
  AiProvider resolveAiProvider(UserProfile? profile) {
    final configured = profile?.aiProvider ?? AiProvider.none;
    if (configured != AiProvider.none) return configured;
    return AiSecrets.hasEmbeddedOpenAi ? AiProvider.openai : AiProvider.none;
  }

  Future<bool> hasUsableAiKey(UserProfile? profile) async {
    final provider = resolveAiProvider(profile);
    if (provider == AiProvider.none) return false;
    final key = await getApiKey(provider);
    return key != null && key.isNotEmpty;
  }

  Future<void> deleteApiKey(AiProvider provider) async {
    if (provider == AiProvider.none) return;
    await _secureStorage.delete(key: _storageKeyFor(provider));
  }

  Future<bool> _hasKeyForProvider(String? provider) async {
    final resolved = switch (provider) {
      'openai' => AiProvider.openai,
      'gemini' => AiProvider.gemini,
      'anthropic' => AiProvider.anthropic,
      _ => AiProvider.openai,
    };
    if (provider == null || provider == 'none') {
      return AiSecrets.hasEmbeddedOpenAi;
    }
    return (await getApiKey(resolved))?.isNotEmpty ?? false;
  }

  Future<Map<String, BodyMetricSnapshot>> getBodyMetricSnapshots() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};
    return getBodyMetricSnapshotsForUser(user.id);
  }

  Future<Map<String, BodyMetricSnapshot>> getBodyMetricSnapshotsForUser(String userId) async {
    final data = await _client
        .from('body_measurements')
        .select()
        .eq('user_id', userId)
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
        .eq('id', userId)
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
    if (def == null || def.isComputed) return;

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
