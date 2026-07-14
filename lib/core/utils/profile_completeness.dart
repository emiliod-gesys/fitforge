import '../../models/profile.dart';

/// Comprueba si el perfil tiene los datos mínimos obligatorios.
abstract final class ProfileCompleteness {
  static const weightUpdateMaxDays = 15;

  /// Usuario debe pasar por el flujo de onboarding de primera vez.
  static bool needsOnboarding(UserProfile? profile) {
    if (profile == null) return true;
    return !profile.hasCompletedOnboarding;
  }

  /// Datos físicos mínimos (validación dentro del onboarding).
  static bool hasMinimumProfileData(UserProfile? profile) {
    if (profile == null) return false;

    final name = profile.displayName?.trim();
    if (name == null || name.isEmpty) return false;

    final age = profile.age;
    if (age == null || age < 13 || age >= 120) return false;

    if (profile.gender == null) return false;

    final height = profile.heightCm;
    if (height == null || height < 50 || height > 280) return false;

    final weight = profile.bodyWeight;
    if (weight == null || weight < 20 || weight > 500) return false;

    return true;
  }

  static bool needsWeightUpdate(DateTime? lastWeightMeasuredAt) {
    if (lastWeightMeasuredAt == null) return true;
    final days = DateTime.now().difference(lastWeightMeasuredAt).inDays;
    return days >= weightUpdateMaxDays;
  }
}
