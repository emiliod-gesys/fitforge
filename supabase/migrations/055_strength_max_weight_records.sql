-- PR de peso máximo (independiente del 1RM estimado).
-- Semilla inicial desde el récord de fuerza existente cuando aún no hay fila dedicada.

INSERT INTO public.personal_records (
  user_id,
  exercise_id,
  exercise_name,
  record_type,
  weight,
  reps,
  achieved_at
)
SELECT
  pr.user_id,
  pr.exercise_id,
  pr.exercise_name,
  'strength_max_weight',
  pr.weight,
  pr.reps,
  pr.achieved_at
FROM public.personal_records pr
WHERE pr.record_type = 'strength'
  AND pr.weight IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM public.personal_records existing
    WHERE existing.user_id = pr.user_id
      AND existing.exercise_id = pr.exercise_id
      AND existing.record_type = 'strength_max_weight'
  );
