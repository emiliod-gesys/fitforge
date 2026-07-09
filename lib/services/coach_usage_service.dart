import 'package:shared_preferences/shared_preferences.dart';

import '../core/subscription/subscription_features.dart';
import '../models/profile.dart';
import 'profile_service.dart';

/// Estado de uso diario del Coach IA.
class CoachUsageStatus {
  const CoachUsageStatus({
    required this.used,
    required this.limit,
    required this.hasUserOwnedApiKey,
  });

  final int used;
  final int? limit;
  final bool hasUserOwnedApiKey;

  bool get isUnlimited => limit == null;

  int get remaining {
    if (isUnlimited) return 999999;
    return (limit! - used).clamp(0, limit!);
  }

  bool get canSend => isUnlimited || remaining > 0;
}

/// Cuenta mensajes del Coach IA por día (almacenamiento local).
class CoachUsageService {
  static const _countKey = 'coach_daily_message_count';
  static const _dateKey = 'coach_daily_message_date';

  Future<bool> hasUserOwnedApiKey(
    UserProfile? profile,
    ProfileService profileService,
  ) async {
    if (profile == null) return false;
    final provider = profile.aiProvider;
    if (provider == AiProvider.none) return false;
    final stored = await profileService.getUserStoredApiKey(provider);
    return stored != null && stored.isNotEmpty;
  }

  int? effectiveDailyLimit(
    UserProfile? profile, {
    required bool hasUserOwnedApiKey,
  }) {
    final tier = profile?.subscriptionTier ?? SubscriptionTier.free;
    if (tier.isFree && hasUserOwnedApiKey) return null;
    return tier.coachDailyMessageLimit;
  }

  Future<CoachUsageStatus> getStatus(
    UserProfile? profile,
    ProfileService profileService,
  ) async {
    final ownsKey = await hasUserOwnedApiKey(profile, profileService);
    final limit = effectiveDailyLimit(profile, hasUserOwnedApiKey: ownsKey);
    if (limit == null) {
      return CoachUsageStatus(used: 0, limit: null, hasUserOwnedApiKey: ownsKey);
    }
    final used = await _todayCount();
    return CoachUsageStatus(used: used, limit: limit, hasUserOwnedApiKey: ownsKey);
  }

  Future<bool> canSendMessage(
    UserProfile? profile,
    ProfileService profileService,
  ) async {
    final status = await getStatus(profile, profileService);
    return status.canSend;
  }

  Future<void> recordMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_dateKey);
    var count = prefs.getInt(_countKey) ?? 0;

    if (storedDate != today) {
      count = 0;
    }

    await prefs.setString(_dateKey, today);
    await prefs.setInt(_countKey, count + 1);
  }

  Future<int> _todayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_dateKey);
    if (storedDate != today) return 0;
    return prefs.getInt(_countKey) ?? 0;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
