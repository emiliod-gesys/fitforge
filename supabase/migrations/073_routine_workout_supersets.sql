-- Superseries de 2–3 ejercicios: agrupación por UUID compartido + slot A/B/C.

ALTER TABLE public.routine_exercises
  ADD COLUMN IF NOT EXISTS superset_group_id uuid,
  ADD COLUMN IF NOT EXISTS superset_slot smallint;

ALTER TABLE public.workout_exercises
  ADD COLUMN IF NOT EXISTS superset_group_id uuid,
  ADD COLUMN IF NOT EXISTS superset_slot smallint;

ALTER TABLE public.routine_exercises
  DROP CONSTRAINT IF EXISTS routine_exercises_superset_slot_check;
ALTER TABLE public.routine_exercises
  ADD CONSTRAINT routine_exercises_superset_slot_check
  CHECK (superset_slot IS NULL OR superset_slot BETWEEN 1 AND 3);

ALTER TABLE public.workout_exercises
  DROP CONSTRAINT IF EXISTS workout_exercises_superset_slot_check;
ALTER TABLE public.workout_exercises
  ADD CONSTRAINT workout_exercises_superset_slot_check
  CHECK (superset_slot IS NULL OR superset_slot BETWEEN 1 AND 3);

CREATE INDEX IF NOT EXISTS idx_routine_exercises_superset_group
  ON public.routine_exercises (superset_group_id)
  WHERE superset_group_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_workout_exercises_superset_group
  ON public.workout_exercises (superset_group_id)
  WHERE superset_group_id IS NOT NULL;

COMMENT ON COLUMN public.routine_exercises.superset_group_id IS
  'Shared UUID for a 2–3 exercise super set; members must be consecutive in order_index.';
COMMENT ON COLUMN public.routine_exercises.superset_slot IS
  '1=A, 2=B, 3=C within the super set.';
COMMENT ON COLUMN public.workout_exercises.superset_group_id IS
  'Copied from the routine when a workout starts.';
COMMENT ON COLUMN public.workout_exercises.superset_slot IS
  '1=A, 2=B, 3=C within the super set.';

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
      target_steps,
      per_arm_weight,
      target_set_details,
      superset_group_id,
      superset_slot
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
      NULLIF(v_ex->>'target_steps', '')::int,
      CASE
        WHEN v_ex ? 'per_arm_weight' THEN (v_ex->>'per_arm_weight')::boolean
        ELSE NULL
      END,
      CASE
        WHEN jsonb_typeof(v_ex->'target_set_details') = 'array' THEN v_ex->'target_set_details'
        ELSE NULL
      END,
      NULLIF(v_ex->>'superset_group_id', '')::uuid,
      NULLIF(v_ex->>'superset_slot', '')::smallint
    );
  END LOOP;

  RETURN v_routine_id;
END;
$$;

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
                  'target_steps', re.target_steps,
                  'per_arm_weight', re.per_arm_weight,
                  'target_set_details', re.target_set_details,
                  'superset_group_id', re.superset_group_id,
                  'superset_slot', re.superset_slot
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
            'target_steps', re.target_steps,
            'per_arm_weight', re.per_arm_weight,
            'target_set_details', re.target_set_details,
            'superset_group_id', re.superset_group_id,
            'superset_slot', re.superset_slot
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

CREATE OR REPLACE FUNCTION public.send_routine_share(p_routine_id UUID, p_recipient_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sender_id UUID := auth.uid();
  v_request_id UUID;
  v_routine RECORD;
  v_snapshot JSONB;
  v_exercises JSONB;
  v_actor_name TEXT;
  v_routine_name TEXT;
BEGIN
  IF v_sender_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_recipient_id IS NULL OR p_recipient_id = v_sender_id THEN
    RAISE EXCEPTION 'Invalid recipient';
  END IF;

  IF NOT public.is_friend_with(p_recipient_id) THEN
    RAISE EXCEPTION 'Recipient is not your friend';
  END IF;

  SELECT r.id, r.user_id, r.name, r.description, r.target_muscles, r.is_ai_generated
  INTO v_routine
  FROM public.routines r
  WHERE r.id = p_routine_id;

  IF v_routine.id IS NULL THEN
    RAISE EXCEPTION 'Routine not found';
  END IF;

  IF v_routine.user_id != v_sender_id THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.routine_share_requests
    WHERE sender_id = v_sender_id
      AND recipient_id = p_recipient_id
      AND routine_id = p_routine_id
      AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'Share request already pending';
  END IF;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
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
      'target_steps', re.target_steps,
      'per_arm_weight', re.per_arm_weight,
      'target_set_details', re.target_set_details,
      'superset_group_id', re.superset_group_id,
      'superset_slot', re.superset_slot
    )
    ORDER BY re.order_index
  ), '[]'::jsonb)
  INTO v_exercises
  FROM public.routine_exercises re
  WHERE re.routine_id = p_routine_id;

  v_snapshot := jsonb_build_object(
    'name', v_routine.name,
    'description', v_routine.description,
    'target_muscles', COALESCE(v_routine.target_muscles, '{}'::text[]),
    'is_ai_generated', COALESCE(v_routine.is_ai_generated, FALSE),
    'exercises', v_exercises
  );

  INSERT INTO public.routine_share_requests (
    sender_id,
    recipient_id,
    routine_id,
    routine_snapshot
  ) VALUES (
    v_sender_id,
    p_recipient_id,
    p_routine_id,
    v_snapshot
  )
  RETURNING id INTO v_request_id;

  SELECT COALESCE(display_name, split_part(email, '@', 1), 'Tu amigo')
  INTO v_actor_name
  FROM public.profiles
  WHERE id = v_sender_id;

  v_routine_name := v_routine.name;

  INSERT INTO public.social_notifications (user_id, actor_id, type, message, reference_id)
  VALUES (
    p_recipient_id,
    v_sender_id,
    'routine_share',
    v_actor_name || ' quiere compartir la rutina "' || v_routine_name || '" contigo',
    v_request_id
  );

  RETURN v_request_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.respond_routine_share(p_request_id UUID, p_accept BOOLEAN)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_request RECORD;
  v_new_routine_id UUID;
  v_ex JSONB;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT *
  INTO v_request
  FROM public.routine_share_requests
  WHERE id = p_request_id;

  IF v_request.id IS NULL THEN
    RAISE EXCEPTION 'Share request not found';
  END IF;

  IF v_request.recipient_id != v_user_id THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  IF v_request.status != 'pending' THEN
    RAISE EXCEPTION 'Share request already resolved';
  END IF;

  IF p_accept THEN
    v_new_routine_id := gen_random_uuid();

    INSERT INTO public.routines (
      id,
      user_id,
      name,
      description,
      target_muscles,
      is_ai_generated
    ) VALUES (
      v_new_routine_id,
      v_user_id,
      v_request.routine_snapshot->>'name',
      NULLIF(trim(v_request.routine_snapshot->>'description'), ''),
      COALESCE(
        ARRAY(SELECT jsonb_array_elements_text(v_request.routine_snapshot->'target_muscles')),
        '{}'::text[]
      ),
      COALESCE((v_request.routine_snapshot->>'is_ai_generated')::boolean, FALSE)
    );

    FOR v_ex IN SELECT value FROM jsonb_array_elements(COALESCE(v_request.routine_snapshot->'exercises', '[]'::jsonb))
    LOOP
      INSERT INTO public.routine_exercises (
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
        target_steps,
        per_arm_weight,
        target_set_details,
        superset_group_id,
        superset_slot
      ) VALUES (
        v_new_routine_id,
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
        NULLIF(v_ex->>'target_steps', '')::int,
        CASE WHEN v_ex ? 'per_arm_weight' THEN (v_ex->>'per_arm_weight')::boolean ELSE NULL END,
        CASE
          WHEN jsonb_typeof(v_ex->'target_set_details') = 'array' THEN v_ex->'target_set_details'
          ELSE NULL
        END,
        NULLIF(v_ex->>'superset_group_id', '')::uuid,
        NULLIF(v_ex->>'superset_slot', '')::smallint
      );
    END LOOP;

    UPDATE public.routine_share_requests
    SET status = 'accepted', resolved_at = NOW()
    WHERE id = p_request_id;
  ELSE
    UPDATE public.routine_share_requests
    SET status = 'declined', resolved_at = NOW()
    WHERE id = p_request_id;
  END IF;

  UPDATE public.social_notifications
  SET read_at = NOW()
  WHERE reference_id = p_request_id
    AND user_id = v_user_id
    AND read_at IS NULL;
END;
$$;

NOTIFY pgrst, 'reload schema';
