/// Utilidades de edad a partir de fecha de nacimiento.
abstract final class AgeCalculator {
  /// Edad en años cumplidos a [asOf] (por defecto hoy local).
  static int yearsFromDateOfBirth(DateTime dateOfBirth, [DateTime? asOf]) {
    final today = asOf ?? DateTime.now();
    final dob = DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day);
    var years = today.year - dob.year;
    final hadBirthday = today.month > dob.month ||
        (today.month == dob.month && today.day >= dob.day);
    if (!hadBirthday) years -= 1;
    return years;
  }

  /// Fecha de nacimiento estimada a partir de una edad en años (hoy − N años).
  static DateTime estimateDateOfBirthFromAge(int age, [DateTime? asOf]) {
    final today = asOf ?? DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return DateTime(base.year - age, base.month, base.day);
  }

  static bool isValidAge(int age) => age >= 13 && age < 120;

  static bool isValidDateOfBirth(DateTime dateOfBirth, [DateTime? asOf]) {
    return isValidAge(yearsFromDateOfBirth(dateOfBirth, asOf));
  }

  /// ISO date `yyyy-MM-dd` para Postgres DATE.
  static String toDateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime? tryParseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
