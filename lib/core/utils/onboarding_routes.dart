/// Rutas accesibles mientras el onboarding no está completado.
abstract final class OnboardingRoutes {
  static bool allowsDuringOnboarding(String matchedLocation) {
    if (matchedLocation == '/onboarding') return true;
    if (matchedLocation.startsWith('/routines/new')) return true;
    if (matchedLocation == '/food') return true;
    if (matchedLocation.startsWith('/food/add')) return true;
    if (matchedLocation.startsWith('/food/detail')) return true;
    return false;
  }
}
