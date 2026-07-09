import '../../models/profile.dart';

/// Comprueba si el perfil tiene los datos mínimos obligatorios.
abstract final class ProfileCompleteness {
  static const weightUpdateMaxDays = 15;

  static bool needsOnboarding(UserProfile? profile) {
    if (profile == null) return true;

    final name = profile.displayName?.trim();
    if (name == null || name.isEmpty) return true;

    final age = profile.age;
    if (age == null || age < 13 || age >= 120) return true;

    if (profile.gender == null) return true;

    final height = profile.heightCm;
    if (height == null || height < 50 || height > 280) return true;

    final weight = profile.bodyWeight;
    if (weight == null || weight < 20 || weight > 500) return true;

    return false;
  }

  static bool needsWeightUpdate(DateTime? lastWeightMeasuredAt) {
    if (lastWeightMeasuredAt == null) return true;
    final days = DateTime.now().difference(lastWeightMeasuredAt).inDays;
    return days >= weightUpdateMaxDays;
  }
}
