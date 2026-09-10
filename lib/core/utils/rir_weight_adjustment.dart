import 'gym_weight.dart';
import 'unit_converter.dart';

/// Ajuste de peso de la siguiente serie según el RIR, sin IA.
///
/// Escalón de gimnasio: **5 lb** o **2.5 kg**, según la unidad del logger.
abstract final class RirWeightAdjustment {
  static const kgStep = 2.5;
  static const lbStep = 5.0;

  static String formatLabel(int rir) => rir >= 3 ? '+3' : '$rir';

  /// Solo RIR 3+ sube un escalón. Ninguna opción baja el peso.
  static int stepsForRir(int rir) => rir >= 3 ? 1 : 0;

  static double stepKg(String unitSystem) {
    if (UnitConverter.isLb(unitSystem)) {
      return UnitConverter.displayToKg(lbStep, unitSystem);
    }
    return kgStep;
  }

  static double? apply({
    required double? baselineKg,
    required int rir,
    required String unitSystem,
  }) {
    if (baselineKg == null || baselineKg <= 0) return null;
    final steps = stepsForRir(rir);
    if (steps == 0) return GymWeight.snapKg(baselineKg, unitSystem);
    final adjusted = baselineKg + steps * stepKg(unitSystem);
    if (adjusted <= 0) return 0;
    return GymWeight.snapKg(adjusted, unitSystem);
  }
}
