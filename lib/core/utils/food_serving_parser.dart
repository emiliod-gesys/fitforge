/// Extrae gramos o mililitros de textos como "1 porción (122 g)".
abstract final class FoodServingParser {
  static double? amountFromDescription(String? description) {
    if (description == null || description.trim().isEmpty) return null;
    final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*(g|ml|gr|gramos?|mililitros?)', caseSensitive: false)
        .firstMatch(description);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  static String unitFromDescription(String? description) {
    if (description == null) return 'g';
    final match = RegExp(r'\d+(?:[.,]\d+)?\s*(ml|mililitros?)', caseSensitive: false)
        .firstMatch(description);
    return match != null ? 'ml' : 'g';
  }

  static String formatAmount(double amount, String unit) {
    final rounded = amount == amount.roundToDouble() ? amount.toInt().toString() : amount.toStringAsFixed(1);
    return '$rounded $unit';
  }
}
