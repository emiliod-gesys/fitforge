import '../core/utils/food_serving_parser.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String toJson() => name;

  static MealType fromJson(String? value) {
    return MealType.values.firstWhere(
      (m) => m.name == value,
      orElse: () => MealType.snack,
    );
  }
}

enum FoodEntrySource {
  manual,
  quick,
  search,
  aiPhoto,
  aiText,
  barcode;

  String toJson() => switch (this) {
        FoodEntrySource.aiPhoto => 'ai_photo',
        FoodEntrySource.aiText => 'ai_text',
        _ => name,
      };

  static FoodEntrySource fromJson(String? value) {
    switch (value) {
      case 'quick':
        return FoodEntrySource.quick;
      case 'search':
        return FoodEntrySource.search;
      case 'ai_photo':
        return FoodEntrySource.aiPhoto;
      case 'ai_text':
        return FoodEntrySource.aiText;
      case 'barcode':
        return FoodEntrySource.barcode;
      default:
        return FoodEntrySource.manual;
    }
  }
}

class FoodEntry {
  final String id;
  final String userId;
  final DateTime loggedAt;
  final MealType mealType;
  final String name;
  final String? brand;
  final int caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final String? servingDescription;
  final FoodEntrySource source;
  final String? notes;

  const FoodEntry({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.mealType,
    required this.name,
    this.brand,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 0,
    this.servingDescription,
    this.source = FoodEntrySource.manual,
    this.notes,
  });

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      mealType: MealType.fromJson(json['meal_type'] as String?),
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String?,
      caloriesKcal: json['calories_kcal'] as int? ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
      servingDescription: json['serving_description'] as String?,
      source: FoodEntrySource.fromJson(json['source'] as String?),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'meal_type': mealType.toJson(),
        'name': name,
        if (brand != null) 'brand': brand,
        'calories_kcal': caloriesKcal,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'fiber_g': fiberG,
        if (servingDescription != null) 'serving_description': servingDescription,
        'source': source.toJson(),
        if (notes != null) 'notes': notes,
        'logged_at': loggedAt.toUtc().toIso8601String(),
      };
}

class MacroTotals {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final int caloriesKcal;

  const MacroTotals({
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.caloriesKcal = 0,
  });

  static const zero = MacroTotals();

  MacroTotals operator +(MacroTotals other) => MacroTotals(
        proteinG: proteinG + other.proteinG,
        carbsG: carbsG + other.carbsG,
        fatG: fatG + other.fatG,
        fiberG: fiberG + other.fiberG,
        caloriesKcal: caloriesKcal + other.caloriesKcal,
      );

  static MacroTotals fromEntries(Iterable<FoodEntry> entries) {
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    var fiber = 0.0;
    var kcal = 0;
    for (final e in entries) {
      protein += e.proteinG;
      carbs += e.carbsG;
      fat += e.fatG;
      fiber += e.fiberG;
      kcal += e.caloriesKcal;
    }
    return MacroTotals(
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      fiberG: fiber,
      caloriesKcal: kcal,
    );
  }
}

class MacroTargets {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const MacroTargets({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 30,
  });
}

class FoodNutritionEstimate {
  final String name;
  final int caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final String? servingDescription;
  final String? brand;
  final List<String> ingredients;
  /// Cantidad de referencia (g o ml) para la que aplican los macros anteriores.
  final double referenceAmount;
  final String amountUnit;

  const FoodNutritionEstimate({
    required this.name,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 0,
    this.servingDescription,
    this.brand,
    this.ingredients = const [],
    this.referenceAmount = 100,
    this.amountUnit = 'g',
  });

  factory FoodNutritionEstimate.fromEntry(FoodEntry entry) {
    final unit = FoodServingParser.unitFromDescription(entry.servingDescription);
    final parsed = FoodServingParser.amountFromDescription(entry.servingDescription);
    final reference = parsed ?? 100.0;

    return FoodNutritionEstimate(
      name: entry.name,
      brand: entry.brand,
      caloriesKcal: entry.caloriesKcal,
      proteinG: entry.proteinG,
      carbsG: entry.carbsG,
      fatG: entry.fatG,
      fiberG: entry.fiberG,
      servingDescription: entry.servingDescription,
      ingredients: const [],
      referenceAmount: reference,
      amountUnit: unit,
    );
  }

  FoodNutritionEstimate scaledTo(double amount) {
    if (referenceAmount <= 0 || amount <= 0) return this;
    final factor = amount / referenceAmount;
    return FoodNutritionEstimate(
      name: name,
      brand: brand,
      caloriesKcal: (caloriesKcal * factor).round(),
      proteinG: proteinG * factor,
      carbsG: carbsG * factor,
      fatG: fatG * factor,
      fiberG: fiberG * factor,
      servingDescription: FoodServingParser.formatAmount(amount, amountUnit),
      ingredients: ingredients,
      referenceAmount: amount,
      amountUnit: amountUnit,
    );
  }
}

class DailyNutritionSummary {
  final DateTime day;
  final int baseCalorieGoal;
  final int workoutCaloriesBurned;
  final int calorieBudget;
  final int caloriesEaten;
  final int caloriesRemaining;
  final MacroTargets targets;
  final MacroTotals eaten;
  final Map<MealType, List<FoodEntry>> entriesByMeal;
  final bool bmrAvailable;

  const DailyNutritionSummary({
    required this.day,
    required this.baseCalorieGoal,
    required this.workoutCaloriesBurned,
    required this.calorieBudget,
    required this.caloriesEaten,
    required this.caloriesRemaining,
    required this.targets,
    required this.eaten,
    required this.entriesByMeal,
    this.bmrAvailable = true,
  });

  MacroTotals eatenForMeal(MealType meal) => MacroTotals.fromEntries(entriesByMeal[meal] ?? const []);

  int mealCalorieGoal(MealType meal) {
    final fraction = switch (meal) {
      MealType.breakfast => 0.25,
      MealType.lunch => 0.35,
      MealType.dinner => 0.30,
      MealType.snack => 0.10,
    };
    return (calorieBudget * fraction).round();
  }
}
