-- Foto al terminar un entreno: queda en el resumen y en la publicación del feed.

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS finish_photo_path TEXT;

CREATE OR REPLACE FUNCTION public.notify_friends_workout_complete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  actor_name TEXT;
BEGIN
  IF OLD.completed_at IS NOT NULL OR NEW.completed_at IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(display_name, split_part(email, '@', 1), 'Tu amigo')
  INTO actor_name
  FROM public.profiles
  WHERE id = NEW.user_id;

  PERFORM public.publish_feed_post(
    NEW.user_id,
    'workout_completed',
    NEW.name,
    jsonb_build_object(
      'workout_name', NEW.name,
      'workout_id', NEW.id
    )
  );

  UPDATE public.social_notifications n
  SET message = actor_name || ' completó "' || NEW.name || '"'
  WHERE n.actor_id = NEW.user_id
    AND n.type = 'workout_completed'
    AND n.message = NEW.name
    AND n.user_id <> NEW.user_id
    AND n.created_at >= NOW() - INTERVAL '1 minute';

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.attach_workout_finish_photo(
  p_workout_id UUID,
  p_image_path TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  actor UUID;
  v_post_id UUID;
BEGIN
  actor := auth.uid();
  IF actor IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF coalesce(p_image_path, '') = ''
     OR (storage.foldername(p_image_path))[1] <> actor::text THEN
    RAISE EXCEPTION 'Invalid image path';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.workouts w
    WHERE w.id = p_workout_id
      AND w.user_id = actor
  ) THEN
    RAISE EXCEPTION 'Workout not found';
  END IF;

  UPDATE public.workouts
  SET finish_photo_path = p_image_path
  WHERE id = p_workout_id
    AND user_id = actor;

  SELECT p.id
  INTO v_post_id
  FROM public.feed_posts p
  WHERE p.actor_id = actor
    AND p.type = 'workout_completed'
    AND p.metadata->>'workout_id' = p_workout_id::text
  ORDER BY p.created_at DESC
  LIMIT 1;

  IF v_post_id IS NULL THEN
    SELECT p.id
    INTO v_post_id
    FROM public.feed_posts p
    WHERE p.actor_id = actor
      AND p.type = 'workout_completed'
      AND p.created_at >= NOW() - INTERVAL '2 minutes'
      AND coalesce(p.metadata->>'image_path', '') = ''
    ORDER BY p.created_at DESC
    LIMIT 1;
  END IF;

  IF v_post_id IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.feed_posts
  SET metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object('image_path', p_image_path)
  WHERE id = v_post_id;

  UPDATE public.social_notifications
  SET metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object('image_path', p_image_path)
  WHERE type = 'workout_completed'
    AND metadata->>'post_id' = v_post_id::text;
END;
$$;

REVOKE ALL ON FUNCTION public.attach_workout_finish_photo(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.attach_workout_finish_photo(UUID, TEXT) TO authenticated;
