-- Color de acento personalizable por usuario (solo afecta su propia vista de la app).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS accent_color TEXT NOT NULL DEFAULT 'gold';

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_accent_color_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_accent_color_check
  CHECK (accent_color IN ('gold', 'orange', 'cobalt', 'violet', 'emerald', 'rose', 'crimson'));
