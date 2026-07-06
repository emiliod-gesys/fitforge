-- PostgREST: un solo parámetro JSONB (evita PGRST202 por firma de función)

DROP FUNCTION IF EXISTS public.save_student_routine(UUID, TEXT, TEXT, TEXT[], BOOLEAN, JSONB, UUID);

CREATE OR REPLACE FUNCTION public.save_student_routine(p_payload JSONB)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_student_id UUID := (p_payload->>'student_id')::uuid;
  v_routine_id UUID;
  v_name TEXT := p_payload->>'name';
  v_desc TEXT := NULLIF(trim(p_payload->>'description'), '');
  v_target_muscles TEXT[] := COALESCE(
    ARRAY(SELECT jsonb_array_elements_text(p_payload->'target_muscles')),
    '{}'::text[]
  );
  v_is_ai BOOLEAN := COALESCE((p_payload->>'is_ai_generated')::boolean, FALSE);
  v_exercises JSONB := COALESCE(p_payload->'exercises', '[]'::jsonb);
  v_existing_id UUID := NULLIF(p_payload->>'routine_id', '')::uuid;
  v_ex JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_trainer() THEN
    RAISE EXCEPTION 'Only personal trainers can manage student routines';
  END IF;

  IF v_student_id IS NULL OR v_name IS NULL OR length(trim(v_name)) = 0 THEN
    RAISE EXCEPTION 'Invalid routine payload';
  END IF;

  IF NOT public.is_trainer_of(v_student_id) THEN
    RAISE EXCEPTION 'Student is not assigned to this trainer';
  END IF;

  IF v_existing_id IS NULL THEN
    v_routine_id := gen_random_uuid();
    INSERT INTO public.routines (id, user_id, name, description, target_muscles, is_ai_generated)
    VALUES (v_routine_id, v_student_id, v_name, v_desc, v_target_muscles, v_is_ai);
  ELSE
    v_routine_id := v_existing_id;
    IF NOT EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = v_routine_id AND r.user_id = v_student_id
    ) THEN
      RAISE EXCEPTION 'Routine not found for this student';
    END IF;

    UPDATE public.routines
    SET
      name = v_name,
      description = v_desc,
      target_muscles = v_target_muscles,
      is_ai_generated = v_is_ai,
      updated_at = NOW()
    WHERE id = v_routine_id;

    DELETE FROM public.routine_exercises WHERE routine_id = v_routine_id;
  END IF;

  FOR v_ex IN SELECT value FROM jsonb_array_elements(v_exercises)
  LOOP
    INSERT INTO public.routine_exercises (
      id,
      routine_id,
      exercise_id,
      exercise_name,
      order_index,
      target_sets,
      target_reps,
      target_weight,
      rest_seconds,
      image_url,
      logging_type,
      target_duration_seconds,
      target_distance_meters,
      target_incline_percent,
      target_steps
    ) VALUES (
      COALESCE(NULLIF(v_ex->>'id', '')::uuid, gen_random_uuid()),
      v_routine_id,
      v_ex->>'exercise_id',
      COALESCE(v_ex->>'exercise_name', ''),
      COALESCE((v_ex->>'order_index')::int, 0),
      COALESCE((v_ex->>'target_sets')::int, 3),
      COALESCE((v_ex->>'target_reps')::int, 10),
      NULLIF(v_ex->>'target_weight', '')::decimal,
      COALESCE((v_ex->>'rest_seconds')::int, 90),
      NULLIF(v_ex->>'image_url', ''),
      COALESCE(NULLIF(v_ex->>'logging_type', ''), 'strength'),
      NULLIF(v_ex->>'target_duration_seconds', '')::int,
      NULLIF(v_ex->>'target_distance_meters', '')::decimal,
      NULLIF(v_ex->>'target_incline_percent', '')::decimal,
      NULLIF(v_ex->>'target_steps', '')::int
    );
  END LOOP;

  RETURN v_routine_id;
END;
$$;

REVOKE ALL ON FUNCTION public.save_student_routine(JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.save_student_routine(JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION public.delete_student_routine(p_routine_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_student_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_trainer() THEN
    RAISE EXCEPTION 'Only personal trainers can delete student routines';
  END IF;

  SELECT r.user_id INTO v_student_id
  FROM public.routines r
  WHERE r.id = p_routine_id;

  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'Routine not found';
  END IF;

  IF NOT public.is_trainer_of(v_student_id) THEN
    RAISE EXCEPTION 'Student is not assigned to this trainer';
  END IF;

  DELETE FROM public.routine_exercises WHERE routine_id = p_routine_id;
  DELETE FROM public.routines WHERE id = p_routine_id;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_student_routine(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_student_routine(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
