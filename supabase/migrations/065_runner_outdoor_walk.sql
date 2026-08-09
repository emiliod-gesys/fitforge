-- Add outdoor walk as a runner system routine type (GPS clone of outdoor run).

ALTER TABLE public.routines
  DROP CONSTRAINT IF EXISTS routines_runner_type_check;

ALTER TABLE public.routines
  ADD CONSTRAINT routines_runner_type_check
  CHECK (
    runner_type IS NULL
    OR runner_type IN ('outdoor', 'outdoor_walk', 'treadmill')
  );

COMMENT ON COLUMN public.routines.runner_type IS
  'outdoor = Go for a run (GPS); outdoor_walk = Go for a walk (GPS); treadmill = Treadmill run.';
