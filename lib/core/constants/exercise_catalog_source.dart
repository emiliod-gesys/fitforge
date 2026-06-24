/// Origen del catálogo de ejercicios de la app.
enum ExerciseCatalogSource {
  /// Catálogo curado en `assets/data/exercise_catalog.json` (recomendado).
  bundled,

  /// Catálogo remoto wger.de (legacy; se mantiene por si hace falta reactivarlo).
  wger,
}
