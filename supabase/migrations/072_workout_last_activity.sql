-- Momento de la última serie / acción en un entreno activo.
-- Sirve para recortar el cronómetro si el usuario olvida pulsar Terminar.

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS last_activity_at timestamptz;

COMMENT ON COLUMN public.workouts.last_activity_at IS
  'Last set or user action during an active workout; used to drop idle time.';

UPDATE public.workouts
SET last_activity_at = COALESCE(completed_at, started_at)
WHERE last_activity_at IS NULL;
