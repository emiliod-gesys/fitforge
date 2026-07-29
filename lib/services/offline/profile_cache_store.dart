import '../../models/profile.dart';
import 'offline_json_file.dart';

/// Caché local del perfil para usar Train y Profile sin red.
class ProfileCacheStore {
  static const _fileName = 'profile_cache.json';

  Future<void> save(
    String userId,
    Map<String, dynamic> json, {
    required bool hasAiKey,
  }) async {
    await OfflineJsonFile.writeMap(_fileName, {
      'user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'profile': json,
      'has_ai_key': hasAiKey,
    });
  }

  Future<UserProfile?> load(String userId) async {
    final state = await OfflineJsonFile.readMap(_fileName);
    if (state['user_id'] != userId) return null;
    final raw = state['profile'];
    if (raw is! Map) return null;
    return UserProfile.fromJson(
      Map<String, dynamic>.from(raw),
      hasAiKey: state['has_ai_key'] as bool? ?? false,
    );
  }
}
