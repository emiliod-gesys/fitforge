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
    BodyMetricDefinition(key: 'bmi', label: 'Índice de masa corporal', kind: BodyMetricKind.score),
    BodyMetricDefinition(key: 'body_fat', label: 'Grasa corporal', kind: BodyMetricKind.percent),
    BodyMetricDefinition(key: 'skeletal_muscle', label: 'Músculo esquelético', kind: BodyMetricKind.percent),
    BodyMetricDefinition(key: 'fat_free_mass', label: 'Peso corporal sin grasa', kind: BodyMetricKind.mass),
    BodyMetricDefinition(key: 'subcutaneous_fat', label: 'Grasa subcutánea', kind: BodyMetricKind.percent),
    BodyMetricDefinition(key: 'visceral_fat', label: 'Grasa visceral', kind: BodyMetricKind.score),
    BodyMetricDefinition(key: 'body_water', label: 'Agua corporal', kind: BodyMetricKind.percent),
    BodyMetricDefinition(key: 'muscle_mass', label: 'Masa muscular', kind: BodyMetricKind.mass),
    BodyMetricDefinition(key: 'bone_mass', label: 'Masa ósea', kind: BodyMetricKind.mass),
    BodyMetricDefinition(key: 'protein', label: 'Proteína', kind: BodyMetricKind.percent),
    BodyMetricDefinition(key: 'bmr', label: 'Tasa metabólica basal', kind: BodyMetricKind.kcal, isComputed: true),
    BodyMetricDefinition(key: 'metabolic_age', label: 'Edad metabólica', kind: BodyMetricKind.years),
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
