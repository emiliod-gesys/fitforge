-- Modo Hyrox: preferencia de perfil + rutinas sistema que no cuentan al límite.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS hyrox_mode boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.hyrox_mode IS
  'When true, FitForge seeds progressive Hyrox prep routines for the user.';

ALTER TABLE public.routines
  ADD COLUMN IF NOT EXISTS is_hyrox_system boolean NOT NULL DEFAULT false;

ALTER TABLE public.routines
  ADD COLUMN IF NOT EXISTS hyrox_level text
  CHECK (hyrox_level IS NULL OR hyrox_level IN ('prep', 'build', 'race'));

COMMENT ON COLUMN public.routines.is_hyrox_system IS
  'System Hyrox templates; excluded from saved-routine limits.';

COMMENT ON COLUMN public.routines.hyrox_level IS
  'Progressive Hyrox template: prep < build < race (official Open).';

CREATE OR REPLACE FUNCTION public.enforce_routine_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  routine_count INTEGER;
  user_tier TEXT;
  max_routines INTEGER;
BEGIN
  IF COALESCE(NEW.is_hyrox_system, false) THEN
    RETURN NEW;
  END IF;

  SELECT subscription_tier
  INTO user_tier
  FROM public.profiles
  WHERE id = NEW.user_id;

  max_routines := public.max_saved_routines_for_tier(COALESCE(user_tier, 'free'));

  SELECT COUNT(*)
  INTO routine_count
  FROM public.routines
  WHERE user_id = NEW.user_id
    AND COALESCE(is_hyrox_system, false) = false;

  IF routine_count >= max_routines THEN
    RAISE EXCEPTION 'routine_limit_reached'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;
