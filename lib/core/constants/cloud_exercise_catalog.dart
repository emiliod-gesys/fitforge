/// IDs del catálogo extendido en Supabase (`catalog_exercises`).
abstract final class CloudExerciseCatalogIds {
  static const prefix = 'ext_';

  static bool isCloudId(String id) => id.startsWith(prefix);

  static String cloudIdForDataset(String datasetId) => '$prefix$datasetId';

  static String? datasetIdFromCloudId(String id) {
    if (!isCloudId(id)) return null;
    final raw = id.substring(prefix.length);
    return raw.isEmpty ? null : raw;
  }
}
