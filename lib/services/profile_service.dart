import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/profile.dart';
import 'supabase_service.dart';

class ProfileService {
  final _client = SupabaseService.client;
  final _secureStorage = const FlutterSecureStorage();

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
    await _client.from('profiles').update({
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
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
}
