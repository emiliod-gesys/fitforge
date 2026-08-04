import 'food_entry.dart';

/// Alimento del catálogo regional (macros por 100 g/ml, porción cultural).
class CatalogFood {
  final String id;
  final String nameEs;
  final String nameEn;
  final String? brand;
  final String region;
  final String category;
  final double caloriesKcalPer100;
  final double proteinGPer100;
  final double carbsGPer100;
  final double fatGPer100;
  final double fiberGPer100;
  final String amountUnit;
  final double servingAmount;
  final String servingLabelEs;
  final String servingLabelEn;

  const CatalogFood({
    required this.id,
    required this.nameEs,
    required this.nameEn,
    this.brand,
    required this.region,
    required this.category,
    required this.caloriesKcalPer100,
    required this.proteinGPer100,
    required this.carbsGPer100,
    required this.fatGPer100,
    required this.fiberGPer100,
    required this.amountUnit,
    required this.servingAmount,
    required this.servingLabelEs,
    required this.servingLabelEn,
  });

  factory CatalogFood.fromJson(Map<String, dynamic> json) {
    return CatalogFood(
      id: json['id'] as String,
      nameEs: json['name_es'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      brand: json['brand'] as String?,
      region: json['region'] as String? ?? 'latam',
      category: json['category'] as String? ?? 'basico',
      caloriesKcalPer100: (json['calories_kcal'] as num?)?.toDouble() ?? 0,
      proteinGPer100: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsGPer100: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatGPer100: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberGPer100: (json['fiber_g'] as num?)?.toDouble() ?? 0,
      amountUnit: json['amount_unit'] as String? ?? 'g',
      servingAmount: (json['serving_amount'] as num?)?.toDouble() ?? 100,
      servingLabelEs: json['serving_label_es'] as String? ?? '',
      servingLabelEn: json['serving_label_en'] as String? ?? '',
    );
  }

  String localizedName(String languageCode) =>
      languageCode == 'en' && nameEn.isNotEmpty ? nameEn : nameEs;

  String localizedServingLabel(String languageCode) =>
      languageCode == 'en' && servingLabelEn.isNotEmpty ? servingLabelEn : servingLabelEs;

  /// Kcal de la porción cultural (ej. "1 pupusa (120 g)").
  int get servingCalories => (caloriesKcalPer100 * servingAmount / 100).round();

  /// Estimación escalada a la porción cultural, lista para la pantalla de detalle.
  FoodNutritionEstimate toEstimate(String languageCode) {
    final factor = servingAmount / 100;
    final label = localizedServingLabel(languageCode);
    return FoodNutritionEstimate(
      name: localizedName(languageCode),
      brand: brand,
      caloriesKcal: (caloriesKcalPer100 * factor).round(),
      proteinG: proteinGPer100 * factor,
      carbsG: carbsGPer100 * factor,
      fatG: fatGPer100 * factor,
      fiberG: fiberGPer100 * factor,
      servingDescription: label.isNotEmpty
          ? label
          : '${servingAmount.round()} $amountUnit',
      referenceAmount: servingAmount,
      amountUnit: amountUnit,
    );
  }
}
