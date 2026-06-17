-- Campos personales adicionales en el perfil
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS age INTEGER,
  ADD COLUMN IF NOT EXISTS gender TEXT,
  ADD COLUMN IF NOT EXISTS height_cm DECIMAL,
  ADD COLUMN IF NOT EXISTS preferred_language TEXT DEFAULT 'es';

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_gender_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_gender_check
  CHECK (gender IS NULL OR gender IN ('male', 'female', 'non_binary', 'prefer_not_to_say'));

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_preferred_language_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_preferred_language_check
  CHECK (preferred_language IN ('es', 'en'));
