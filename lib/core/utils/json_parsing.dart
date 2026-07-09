/// Helpers defensivos para JSON de Supabase / catálogos locales.
bool parseJsonBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

String? parseJsonString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}
