-- Marca onboarding completado para no repetir el flujo en usuarios existentes con perfil mínimo.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ;

UPDATE profiles
SET onboarding_completed_at = COALESCE(updated_at, created_at, NOW())
WHERE onboarding_completed_at IS NULL
  AND display_name IS NOT NULL
  AND TRIM(display_name) <> ''
  AND age IS NOT NULL
  AND gender IS NOT NULL
  AND height_cm IS NOT NULL
  AND body_weight IS NOT NULL;

COMMENT ON COLUMN profiles.onboarding_completed_at IS
  'Timestamp when the user finished the first-run onboarding flow.';
