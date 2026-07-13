-- Modo Runner: preferencia de perfil + rutinas sistema (outdoor / treadmill) sin cupo.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS runner_mode boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.runner_mode IS
  'When true, FitForge seeds outdoor and treadmill running system routines.';

ALTER TABLE public.routines
  ADD COLUMN IF NOT EXISTS is_runner_system boolean NOT NULL DEFAULT false;

ALTER TABLE public.routines
  ADD COLUMN IF NOT EXISTS runner_type text
  CHECK (runner_type IS NULL OR runner_type IN ('outdoor', 'treadmill'));

COMMENT ON COLUMN public.routines.is_runner_system IS
  'System running templates; excluded from saved-routine limits.';

COMMENT ON COLUMN public.routines.runner_type IS
  'outdoor = Salir a correr (GPS); treadmill = Correr en cinta.';

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS runner_surface text
  CHECK (runner_surface IS NULL OR runner_surface IN ('asphalt', 'track', 'trail'));

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS runner_route jsonb;

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS runner_splits jsonb;

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS runner_avg_pace_sec_per_km double precision;

COMMENT ON COLUMN public.workouts.runner_surface IS
  'Running surface for outdoor sessions (asphalt, track, trail).';

COMMENT ON COLUMN public.workouts.runner_route IS
  'Compact GPS route: [{lat, lng, t}]';

COMMENT ON COLUMN public.workouts.runner_splits IS
  'Km splits: [{km, seconds}]';

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
  IF COALESCE(NEW.is_hyrox_system, false) OR COALESCE(NEW.is_runner_system, false) THEN
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
    AND COALESCE(is_hyrox_system, false) = false
    AND COALESCE(is_runner_system, false) = false;

  IF routine_count >= max_routines THEN
    RAISE EXCEPTION 'routine_limit_reached'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;
