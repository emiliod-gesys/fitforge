-- Entrenador: listar y cargar rutinas del alumno (todas, sin importar quién las creó)

CREATE OR REPLACE FUNCTION public.get_student_routines(p_student_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_trainer() THEN
    RAISE EXCEPTION 'Only personal trainers can view student routines';
  END IF;

  IF NOT public.is_trainer_of(p_student_id) THEN
    RAISE EXCEPTION 'Student is not assigned to this trainer';
  END IF;

  RETURN COALESCE(
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', r.id,
          'user_id', r.user_id,
          'name', r.name,
          'description', r.description,
          'target_muscles', COALESCE(r.target_muscles, '{}'::text[]),
          'is_ai_generated', COALESCE(r.is_ai_generated, FALSE),
          'created_at', r.created_at,
          'updated_at', r.updated_at,
          'exercises', COALESCE(
            (
              SELECT jsonb_agg(
                jsonb_build_object(
                  'id', re.id,
                  'exercise_id', re.exercise_id,
                  'exercise_name', re.exercise_name,
                  'order_index', re.order_index,
                  'target_sets', re.target_sets,
                  'target_reps', re.target_reps,
                  'target_weight', re.target_weight,
                  'rest_seconds', re.rest_seconds,
                  'image_url', re.image_url,
                  'logging_type', COALESCE(re.logging_type, 'strength'),
                  'target_duration_seconds', re.target_duration_seconds,
                  'target_distance_meters', re.target_distance_meters,
                  'target_incline_percent', re.target_incline_percent,
                  'target_steps', re.target_steps
                )
                ORDER BY re.order_index
              )
              FROM public.routine_exercises re
              WHERE re.routine_id = r.id
            ),
            '[]'::jsonb
          )
        )
        ORDER BY r.updated_at DESC
      )
      FROM public.routines r
      WHERE r.user_id = p_student_id
    ),
    '[]'::jsonb
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_student_routine(p_routine_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_student_id UUID;
  v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_trainer() THEN
    RAISE EXCEPTION 'Only personal trainers can view student routines';
  END IF;

  SELECT r.user_id INTO v_student_id
  FROM public.routines r
  WHERE r.id = p_routine_id;

  IF v_student_id IS NULL THEN
    RETURN NULL;
  END IF;

  IF NOT public.is_trainer_of(v_student_id) THEN
    RAISE EXCEPTION 'Student is not assigned to this trainer';
  END IF;

  SELECT jsonb_build_object(
    'id', r.id,
    'user_id', r.user_id,
    'name', r.name,
    'description', r.description,
    'target_muscles', COALESCE(r.target_muscles, '{}'::text[]),
    'is_ai_generated', COALESCE(r.is_ai_generated, FALSE),
    'created_at', r.created_at,
    'updated_at', r.updated_at,
    'exercises', COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', re.id,
            'exercise_id', re.exercise_id,
            'exercise_name', re.exercise_name,
            'order_index', re.order_index,
            'target_sets', re.target_sets,
            'target_reps', re.target_reps,
            'target_weight', re.target_weight,
            'rest_seconds', re.rest_seconds,
            'image_url', re.image_url,
            'logging_type', COALESCE(re.logging_type, 'strength'),
            'target_duration_seconds', re.target_duration_seconds,
            'target_distance_meters', re.target_distance_meters,
            'target_incline_percent', re.target_incline_percent,
            'target_steps', re.target_steps
          )
          ORDER BY re.order_index
        )
        FROM public.routine_exercises re
        WHERE re.routine_id = r.id
      ),
      '[]'::jsonb
    )
  )
  INTO v_result
  FROM public.routines r
  WHERE r.id = p_routine_id;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_routines(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_student_routines(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.get_student_routine(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_student_routine(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
