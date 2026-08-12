-- Preferencia de unidad de agua. false = litros (default), true = onzas fluidas.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS water_use_fl_oz boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.water_use_fl_oz IS
  'Water display unit. false = liters (default), true = US fluid ounces.';
