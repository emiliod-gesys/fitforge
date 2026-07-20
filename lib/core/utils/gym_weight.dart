import 'unit_converter.dart';

/// Pesos redondeados a incrementos reales de gimnasio (mancuernas, discos, máquinas).
abstract final class GymWeight {
  /// Incremento mínimo en libras durante entrenos (enteros; el usuario no usa decimales).
  static const lbIncrement = 1.0;

  /// Incremento mínimo en kilogramos (0.5 kg en mancuernas; 2.5 kg en barra).
  static const kgIncrement = 0.5;

  /// Texto para campos de peso en entrenos: lb sin decimales; kg solo .0 o .5.
  static String formatDisplay(double kg, String unitSystem) {
    if (kg <= 0) return '0';

    final snappedKg = snapKg(kg, unitSystem);
    final display = UnitConverter.kgToDisplay(snappedKg, unitSystem);

    if (UnitConverter.isLb(unitSystem)) {
      return display.round().toString();
    }

    if (display == display.truncateToDouble()) {
      return display.toInt().toString();
    }
    return display.toStringAsFixed(1);
  }

  /// Convierte lo que escribió el usuario a kg, ajustado al incremento del gimnasio.
  static double displayToSnappedKg(double display, String unitSystem) {
    if (UnitConverter.isLb(unitSystem)) {
      final lb = display.round();
      return UnitConverter.displayToKg(lb.toDouble(), unitSystem);
    }
    return snapKg(UnitConverter.displayToKg(display, unitSystem), unitSystem);
  }

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
