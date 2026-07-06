-- Silenciar amigos: sin notificaciones sociales de su parte

CREATE TABLE IF NOT EXISTS public.friend_mutes (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  muted_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, muted_user_id),
  CHECK (user_id <> muted_user_id)
);

CREATE INDEX IF NOT EXISTS idx_friend_mutes_user
  ON public.friend_mutes(user_id);

ALTER TABLE public.friend_mutes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own friend mutes" ON public.friend_mutes;
CREATE POLICY "Users manage own friend mutes"
  ON public.friend_mutes FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND public.is_friend_with(muted_user_id)
  );

CREATE OR REPLACE FUNCTION public.is_friend_muted(p_user_id UUID, p_actor_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.friend_mutes fm
    WHERE fm.user_id = p_user_id
      AND fm.muted_user_id = p_actor_id
  );
$$;

REVOKE ALL ON FUNCTION public.is_friend_muted(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_friend_muted(UUID, UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.notify_friends_workout_complete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  friend_id UUID;
  actor_name TEXT;
BEGIN
  IF OLD.completed_at IS NOT NULL OR NEW.completed_at IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(display_name, split_part(email, '@', 1), 'Tu amigo')
  INTO actor_name
  FROM public.profiles
  WHERE id = NEW.user_id;

  FOR friend_id IN
    SELECT CASE
      WHEN f.requester_id = NEW.user_id THEN f.addressee_id
      ELSE f.requester_id
    END
    FROM public.friendships f
    WHERE f.status = 'accepted'
      AND (f.requester_id = NEW.user_id OR f.addressee_id = NEW.user_id)
  LOOP
    IF public.is_friend_muted(friend_id, NEW.user_id) THEN
      CONTINUE;
    END IF;

    INSERT INTO public.social_notifications (user_id, actor_id, type, message)
    VALUES (
      friend_id,
      NEW.user_id,
      'workout_completed',
      actor_name || ' completó "' || NEW.name || '"'
    );
  END LOOP;

  RETURN NEW;
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

  IF NOT public.is_friend_muted(p_recipient_id, v_sender_id) THEN
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
  END IF;

  RETURN v_request_id;
END;
$$;

NOTIFY pgrst, 'reload schema';
