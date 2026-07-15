enum BodyMetricKind { mass, percent, score, kcal, years }

class BodyMetricDefinition {
  final String key;
  final String label;
  final BodyMetricKind kind;
  final bool isComputed;

  const BodyMetricDefinition({
    required this.key,
    required this.label,
    required this.kind,
    this.isComputed = false,
  });

  String unitLabel(String unitSystem, {String yearsLabel = 'años'}) {
    switch (kind) {
      case BodyMetricKind.mass:
        return unitSystem == 'lb' ? 'lb' : 'kg';
      case BodyMetricKind.percent:
        return '%';
      case BodyMetricKind.score:
        return key == 'bmi' ? '' : '';
      case BodyMetricKind.kcal:
        return 'kcal';
      case BodyMetricKind.years:
        return yearsLabel;
    }
  }

  static const all = [
    BodyMetricDefinition(key: 'weight', label: 'Peso', kind: BodyMetricKind.mass),
    BodyMetricDefinition(
      key: 'bmi',
      label: 'Índice de masa corporal',
      kind: BodyMetricKind.score,
      isComputed: true,
    ),
    BodyMetricDefinition(key: 'body_fat', label: 'Grasa corporal', kind: BodyMetricKind.percent),
    BodyMetricDefinition(
      key: 'bmr',
      label: 'Tasa metabólica basal',
      kind: BodyMetricKind.kcal,
      isComputed: true,
    ),
  ];

  static BodyMetricDefinition? forKey(String key) {
    for (final m in all) {
      if (m.key == key) return m;
    }
    return null;
  }
}

class BodyMetricSnapshot {
  final String type;
  final double? valueKg;
  final double? rawValue;
  final double? deltaKg;
  final double? deltaRaw;
  final DateTime? measuredAt;

  const BodyMetricSnapshot({
    required this.type,
    this.valueKg,
    this.rawValue,
    this.deltaKg,
    this.deltaRaw,
    this.measuredAt,
  });

  bool get hasValue => valueKg != null || rawValue != null;
}
