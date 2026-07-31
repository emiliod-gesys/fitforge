/// Muestra de métrica corporal leída de Apple Health / Health Connect.
class HealthBodyMetricSample {
  const HealthBodyMetricSample({
    required this.type,
    required this.value,
    required this.measuredAt,
    required this.sourceKey,
  });

  /// `weight` o `body_fat` (claves de [BodyMetricDefinition]).
  final String type;

  /// Peso en kg o grasa corporal en porcentaje (0–100).
  final double value;
  final DateTime measuredAt;

  /// Identificador estable para evitar re-prompt de la misma muestra.
  final String sourceKey;
}
