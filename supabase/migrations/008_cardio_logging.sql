-- Cardio logging: métricas en series, objetivos en rutinas y PRs cardio.

ALTER TABLE public.workout_sets
  ADD COLUMN IF NOT EXISTS duration_seconds INT,
  ADD COLUMN IF NOT EXISTS distance_meters DECIMAL,
  ADD COLUMN IF NOT EXISTS incline_percent DECIMAL,
  ADD COLUMN IF NOT EXISTS steps INT,
  ADD COLUMN IF NOT EXISTS logging_type TEXT DEFAULT 'strength';

ALTER TABLE public.routine_exercises
  ADD COLUMN IF NOT EXISTS target_duration_seconds INT,
  ADD COLUMN IF NOT EXISTS target_distance_meters DECIMAL,
  ADD COLUMN IF NOT EXISTS target_incline_percent DECIMAL,
  ADD COLUMN IF NOT EXISTS target_steps INT,
  ADD COLUMN IF NOT EXISTS logging_type TEXT DEFAULT 'strength';

ALTER TABLE public.personal_records
  ADD COLUMN IF NOT EXISTS record_type TEXT DEFAULT 'strength',
  ADD COLUMN IF NOT EXISTS duration_seconds INT,
  ADD COLUMN IF NOT EXISTS distance_meters DECIMAL,
  ADD COLUMN IF NOT EXISTS incline_percent DECIMAL,
  ADD COLUMN IF NOT EXISTS steps INT;

ALTER TABLE public.personal_records
  ALTER COLUMN weight DROP NOT NULL,
  ALTER COLUMN one_rep_max DROP NOT NULL;

ALTER TABLE public.personal_records
  DROP CONSTRAINT IF EXISTS personal_records_user_id_exercise_id_key;

CREATE UNIQUE INDEX IF NOT EXISTS personal_records_user_exercise_type_idx
  ON public.personal_records(user_id, exercise_id, record_type);
