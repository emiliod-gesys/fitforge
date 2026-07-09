-- El feed también muestra las publicaciones propias del usuario.

CREATE OR REPLACE FUNCTION public.notify_friends_feed_event(
  p_type TEXT,
  p_message TEXT,
  p_metadata JSONB DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  friend_id UUID;
  actor_id UUID;
BEGIN
  actor_id := auth.uid();
  IF actor_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_type NOT IN ('milestone_unlocked', 'level_up', 'pr_unlocked') THEN
    RAISE EXCEPTION 'Invalid feed event type';
  END IF;

  INSERT INTO public.social_notifications (user_id, actor_id, type, message, metadata)
  VALUES (actor_id, actor_id, p_type, p_message, p_metadata);

  FOR friend_id IN
    SELECT CASE
      WHEN f.requester_id = actor_id THEN f.addressee_id
      ELSE f.requester_id
    END
    FROM public.friendships f
    WHERE f.status = 'accepted'
      AND (f.requester_id = actor_id OR f.addressee_id = actor_id)
  LOOP
    IF public.is_friend_muted(friend_id, actor_id) THEN
      CONTINUE;
    END IF;

    INSERT INTO public.social_notifications (user_id, actor_id, type, message, metadata)
    VALUES (friend_id, actor_id, p_type, p_message, p_metadata);
  END LOOP;
END;
$$;

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

  INSERT INTO public.social_notifications (user_id, actor_id, type, message, metadata)
  VALUES (
    NEW.user_id,
    NEW.user_id,
    'workout_completed',
    NEW.name,
    jsonb_build_object('workout_name', NEW.name)
  );

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
