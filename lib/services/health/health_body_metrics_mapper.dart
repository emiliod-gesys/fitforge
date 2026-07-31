import 'package:health/health.dart';

import '../../core/utils/unit_converter.dart';

/// Normaliza muestras crudas de Apple Health / Health Connect a unidades FitForge:
/// peso en kg y grasa corporal en porcentaje 0–100.
abstract final class HealthBodyMetricsMapper {
  static const minWeightKg = 20.0;
  static const maxWeightKg = 400.0;
  static const minBodyFatPct = 2.0;
  static const maxBodyFatPct = 70.0;

  /// Convierte el valor numérico de peso a kg según la unidad del punto de salud.
  static double? weightToKg(double value, HealthDataUnit unit) {
    if (value <= 0) return null;

    final kg = switch (unit) {
      HealthDataUnit.KILOGRAM => value,
      HealthDataUnit.GRAM => value / 1000,
      HealthDataUnit.POUND => UnitConverter.displayToKg(value, 'lb'),
      HealthDataUnit.OUNCE => value / (UnitConverter.lbPerKg * 16),
      HealthDataUnit.STONE => value * 6.35029318,
      _ => value, // el plugin suele devolver kg por defecto
    };

    if (kg < minWeightKg || kg > maxWeightKg) return null;
    return kg;
  }

  /// Apple HealthKit usa fracción 0–1 con unidad PERCENT; Health Connect usa 0–100.
  static double? bodyFatToPercent(double value) {
    if (value <= 0) return null;

    final percent = value <= 1.0 ? value * 100 : value;
    if (percent < minBodyFatPct || percent > maxBodyFatPct) return null;
    return percent;
  }
}
