-- Compartir rutinas entre amigos (solicitud pendiente → aceptar / rechazar)

ALTER TABLE public.social_notifications
  ADD COLUMN IF NOT EXISTS reference_id UUID;

CREATE TABLE IF NOT EXISTS public.routine_share_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  routine_id UUID NOT NULL REFERENCES public.routines(id) ON DELETE CASCADE,
  routine_snapshot JSONB NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  CHECK (sender_id <> recipient_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_routine_share_pending_unique
  ON public.routine_share_requests(sender_id, recipient_id, routine_id)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_routine_share_recipient_pending
  ON public.routine_share_requests(recipient_id, created_at DESC)
  WHERE status = 'pending';

ALTER TABLE public.routine_share_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own routine share requests"
  ON public.routine_share_requests FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

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
      'target_set_details', re.target_set_details
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
        target_set_details
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
        END
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

REVOKE ALL ON FUNCTION public.send_routine_share(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_routine_share(UUID, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.respond_routine_share(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.respond_routine_share(UUID, BOOLEAN) TO authenticated;

NOTIFY pgrst, 'reload schema';
