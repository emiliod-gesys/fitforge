import 'package:fitforge/core/utils/profile_completeness.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final completeProfile = UserProfile(
    id: 'u1',
    displayName: 'Alex',
    age: 28,
    gender: Gender.male,
    heightCm: 175,
    bodyWeight: 75,
    createdAt: DateTime(2026, 1, 1),
    onboardingCompletedAt: DateTime(2026, 1, 2),
  );

  test('needsOnboarding is false when onboarding is completed', () {
    expect(ProfileCompleteness.needsOnboarding(completeProfile), isFalse);
  });

  test('needsOnboarding is true when onboarding timestamp is missing', () {
    expect(
      ProfileCompleteness.needsOnboarding(
        UserProfile(
          id: 'u1',
          displayName: 'Alex',
          age: 28,
          gender: Gender.male,
          heightCm: 175,
          bodyWeight: 75,
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
      isTrue,
    );
  });

  test('hasMinimumProfileData validates physical fields', () {
    expect(ProfileCompleteness.hasMinimumProfileData(completeProfile), isTrue);
    expect(
      ProfileCompleteness.hasMinimumProfileData(
        UserProfile(id: 'u1', createdAt: DateTime(2026, 1, 1)),
      ),
      isFalse,
    );
  });

  test('needsWeightUpdate after 15 days', () {
    final recent = DateTime.now().subtract(const Duration(days: 10));
    final stale = DateTime.now().subtract(const Duration(days: 16));

    expect(ProfileCompleteness.needsWeightUpdate(recent), isFalse);
    expect(ProfileCompleteness.needsWeightUpdate(stale), isTrue);
    expect(ProfileCompleteness.needsWeightUpdate(null), isTrue);
  });
}
