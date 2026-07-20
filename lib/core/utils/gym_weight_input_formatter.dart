import 'package:flutter/services.dart';

import 'unit_converter.dart';

/// Restringe la entrada de peso en entrenos: lb enteras; kg solo .0 o .5.
final class GymWeightInputFormatter extends TextInputFormatter {
  GymWeightInputFormatter({required this.unitSystem});

  final String unitSystem;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(',', '.');
    if (text.isEmpty) return newValue;

    if (UnitConverter.isLb(unitSystem)) {
      if (RegExp(r'^\d+$').hasMatch(text)) return newValue;
      return oldValue;
    }

    if (RegExp(r'^\d+$').hasMatch(text)) return newValue;
    if (RegExp(r'^\d+\.$').hasMatch(text)) return newValue;
    if (RegExp(r'^\d+\.[05]$').hasMatch(text)) return newValue;

    return oldValue;
  }
}
