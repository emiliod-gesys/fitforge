import 'package:fitforge/core/subscription/subscription_features.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfile _profile({
  SubscriptionTier tier = SubscriptionTier.free,
  AiProvider aiProvider = AiProvider.none,
  bool hasAiKey = false,
}) {
  return UserProfile(
    id: 'u1',
    createdAt: DateTime.utc(2026, 1, 1),
    aiProvider: aiProvider,
    hasAiKey: hasAiKey,
    subscriptionTier: tier,
  );
}

void main() {
  group('ProfileSubscriptionAccess', () {
    test('free without API key keeps AI features locked', () {
      final profile = _profile();

      expect(profile.hasUserOwnedApiKey, isFalse);
      expect(profile.canUseProactiveAi, isFalse);
      expect(profile.canUseFoodPhotoAi, isFalse);
    });

    test('free with own API key unlocks proactive AI and food photo', () {
      final profile = _profile(
        aiProvider: AiProvider.openai,
        hasAiKey: true,
      );

      expect(profile.hasUserOwnedApiKey, isTrue);
      expect(profile.canUseProactiveAi, isTrue);
      expect(profile.canUseFoodPhotoAi, isTrue);
    });

    test('gymrat keeps food photo locked without pro', () {
      final profile = _profile(
        tier: SubscriptionTier.gymrat,
        hasAiKey: true,
      );

      expect(profile.canUseProactiveAi, isTrue);
      expect(profile.canUseFoodPhotoAi, isFalse);
    });

    test('gymrat pro includes all AI features', () {
      final profile = _profile(tier: SubscriptionTier.gymratPro);

      expect(profile.canUseProactiveAi, isTrue);
      expect(profile.canUseFoodPhotoAi, isTrue);
    });
  });
}
