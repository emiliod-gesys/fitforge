import 'unit_converter.dart';

/// Pesos redondeados a incrementos reales de gimnasio (mancuernas, discos, máquinas).
abstract final class GymWeight {
  /// Incremento mínimo en libras (2.5 lb es estándar en racks y mancuernas).
  static const lbIncrement = 2.5;

  /// Incremento mínimo en kilogramos (0.5 kg en mancuernas; 2.5 kg en barra).
  static const kgIncrement = 0.5;

  /// Redondea un peso en kg al incremento de gimnasio según el sistema del usuario.
  static double snapKg(double kg, String unitSystem) {
    if (kg <= 0) return kg;

    if (UnitConverter.isLb(unitSystem)) {
      final lb = UnitConverter.kgToDisplay(kg, unitSystem);
      final snappedLb = (lb / lbIncrement).round() * lbIncrement;
      return UnitConverter.displayToKg(snappedLb, unitSystem);
    }

    return (kg / kgIncrement).round() * kgIncrement;
  }

  static double? snapKgOrNull(double? kg, String unitSystem) {
    if (kg == null) return null;
    return snapKg(kg, unitSystem);
  }
}
