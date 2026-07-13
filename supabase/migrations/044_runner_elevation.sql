-- Desnivel acumulado en carreras outdoor (GPS).

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS runner_elevation_gain_m double precision;

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS runner_elevation_loss_m double precision;

COMMENT ON COLUMN public.workouts.runner_elevation_gain_m IS
  'Cumulative elevation gain in meters from GPS altitude.';

COMMENT ON COLUMN public.workouts.runner_elevation_loss_m IS
  'Cumulative elevation loss in meters from GPS altitude.';
