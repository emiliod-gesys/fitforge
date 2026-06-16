abstract final class UnitConverter {
  static const lbPerKg = 2.2046226218;

  static bool isLb(String unitSystem) => unitSystem == 'lb';

  static String massLabel(String unitSystem) => isLb(unitSystem) ? 'lb' : 'kg';

  static double kgToDisplay(double kg, String unitSystem) =>
      isLb(unitSystem) ? kg * lbPerKg : kg;

  static double displayToKg(double value, String unitSystem) =>
      isLb(unitSystem) ? value / lbPerKg : value;

  static String formatMass(double? kg, String unitSystem, {int decimals = 1}) {
    if (kg == null) return '—';
    final display = kgToDisplay(kg, unitSystem);
    return '${display.toStringAsFixed(decimals)} ${massLabel(unitSystem)}';
  }

  static String formatDelta(double? delta, String unitSystem, {int decimals = 1}) {
    if (delta == null) return '';
    final display = isLb(unitSystem) ? delta * lbPerKg : delta;
    final sign = display > 0 ? '+' : '';
    return '$sign${display.toStringAsFixed(decimals)}';
  }

  static String formatVolume(double kg, String unitSystem, {int decimals = 0}) {
    final display = kgToDisplay(kg, unitSystem);
    return '${display.toStringAsFixed(decimals)} ${massLabel(unitSystem)}';
  }

  static String formatSetLine(double weightKg, int reps, String unitSystem) {
    final w = kgToDisplay(weightKg, unitSystem).toStringAsFixed(1);
    return '$w ${massLabel(unitSystem)} × $reps';
  }
}
