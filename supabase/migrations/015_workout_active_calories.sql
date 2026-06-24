-- Calorías activas netas estimadas al completar el entreno (misma fórmula que el resumen).
ALTER TABLE workouts
  ADD COLUMN IF NOT EXISTS active_calories_kcal INT
  CHECK (active_calories_kcal IS NULL OR (active_calories_kcal >= 0 AND active_calories_kcal <= 9999));

COMMENT ON COLUMN workouts.active_calories_kcal IS
  'Calorías activas netas del entreno; usadas por Comida para no recalcular.';
