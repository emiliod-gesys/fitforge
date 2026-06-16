/// Utilidades para fechas devueltas por Supabase/Postgres (`timestamptz`).
abstract final class SupabaseDateTime {
  /// Postgres devuelve a menudo ISO sin sufijo de zona; Dart lo interpreta como local.
  /// Esos valores son instantes UTC y deben parsearse como tal.
  static DateTime parse(String value) {
    final parsed = DateTime.parse(value);
    if (value.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(value)) {
      return parsed.toUtc();
    }
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  static DateTime get nowUtc => DateTime.now().toUtc();
}
