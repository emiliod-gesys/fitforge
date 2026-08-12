import 'package:intl/intl.dart';

/// Agrupa miles con coma, coherente con los decimales con punto de la app (171.2 lb).
abstract final class QuantityFormat {
  static final NumberFormat _integer = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _oneDecimal = NumberFormat('#,##0.0', 'en_US');
  static final NumberFormat _twoDecimals = NumberFormat('#,##0.00', 'en_US');

  static String integer(num value) => _integer.format(value.round());

  static String decimal(num value, {int decimals = 1}) {
    if (decimals <= 0) return integer(value);
    if (decimals == 1) return _oneDecimal.format(value);
    if (decimals == 2) return _twoDecimals.format(value);
    return NumberFormat('#,##0.${'0' * decimals}', 'en_US').format(value);
  }

  static String kcal(int value) => '${integer(value)} kcal';
}
