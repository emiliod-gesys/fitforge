-- Ajuste personalizado del presupuesto calórico vs TDEE (ej. -15 = 15% déficit, +8 = 8% superávit).
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS calorie_adjustment_pct integer;

COMMENT ON COLUMN profiles.calorie_adjustment_pct IS
  'Override del usuario: porcentaje firmado sobre TDEE. NULL = usar default según fitness_goal.';
