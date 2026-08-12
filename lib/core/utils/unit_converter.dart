import 'gym_weight.dart';
import 'quantity_format.dart';

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
    return '${QuantityFormat.decimal(display, decimals: decimals)} ${massLabel(unitSystem)}';
  }

  /// Peso de entrenamiento: lb enteras; kg solo .0 o .5.
  static String formatGymMass(double? kg, String unitSystem) {
    if (kg == null) return '—';
    return '${_groupedGymDisplay(kg, unitSystem)} ${massLabel(unitSystem)}';
  }

  static String formatDelta(double? delta, String unitSystem, {int decimals = 1}) {
    if (delta == null) return '';
    final display = isLb(unitSystem) ? delta * lbPerKg : delta;
    final sign = display > 0 ? '+' : '';
    return '$sign${QuantityFormat.decimal(display, decimals: decimals)}';
  }

  static String formatVolume(double kg, String unitSystem, {int decimals = 0}) {
    final display = kgToDisplay(kg, unitSystem);
    return '${QuantityFormat.decimal(display, decimals: decimals)} ${massLabel(unitSystem)}';
  }

  static String formatSetLine(double weightKg, int reps, String unitSystem) {
    final w = _groupedGymDisplay(weightKg, unitSystem);
    return '$w ${massLabel(unitSystem)} × $reps';
  }

  static String _groupedGymDisplay(double kg, String unitSystem) {
    final raw = GymWeight.formatDisplay(kg, unitSystem);
    final parsed = double.tryParse(raw);
    if (parsed == null) return raw;
    if (raw.contains('.')) {
      return QuantityFormat.decimal(parsed, decimals: 1);
    }
    return QuantityFormat.integer(parsed);
  }

  static String heightLabel(String unitSystem) => isLb(unitSystem) ? 'ft/in' : 'cm';

  static double cmToDisplay(double cm, String unitSystem) => cm;

  static double displayToCm(double value, String unitSystem) => value;

  /// Altura siempre en centímetros (independiente del sistema de peso).
  static String formatHeight(double? cm, [String? unitSystem]) {
    if (cm == null) return '—';
    return '${cm.toStringAsFixed(0)} cm';
  }
}
