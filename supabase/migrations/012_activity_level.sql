-- Nivel de actividad diaria para cálculo de TDEE en nutrición
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS activity_level TEXT NOT NULL DEFAULT 'moderate';

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_activity_level_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_activity_level_check
  CHECK (activity_level IN ('sedentary', 'moderate', 'high'));
