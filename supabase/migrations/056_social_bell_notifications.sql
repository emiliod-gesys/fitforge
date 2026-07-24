-- Notificaciones de campana social: comentarios, reacciones, solicitudes de amistad.
-- Solo estos tipos (+ routine_share, trainer_request) deben aparecer en la campana y push.

CREATE OR REPLACE FUNCTION public.social_actor_display_name(p_user_id UUID)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    NULLIF(trim(display_name), ''),
    NULLIF(split_part(email, '@', 1), ''),
    'Tu amigo'
  )
  FROM public.profiles
  WHERE id = p_user_id;
$$;

REVOKE ALL ON FUNCTION public.social_actor_display_name(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.social_actor_display_name(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.notify_friend_request()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_name TEXT;
BEGIN
  IF NEW.status <> 'pending' THEN
    RETURN NEW;
  END IF;

  v_actor_name := public.social_actor_display_name(NEW.requester_id);

  INSERT INTO public.social_notifications (user_id, actor_id, type, message, reference_id)
  VALUES (
    NEW.addressee_id,
    NEW.requester_id,
    'friend_request',
    v_actor_name || ' te envió una solicitud de amistad',
    NEW.id
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_friend_request_notify ON public.friendships;
CREATE TRIGGER on_friend_request_notify
  AFTER INSERT ON public.friendships
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_friend_request();

CREATE OR REPLACE FUNCTION public.notify_feed_post_reaction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_feed RECORD;
  v_actor_name TEXT;
  v_post_id TEXT;
BEGIN
  SELECT n.actor_id, n.metadata
  INTO v_feed
  FROM public.social_notifications n
  WHERE n.id = NEW.notification_id;

  IF NOT FOUND OR v_feed.actor_id IS NULL OR v_feed.actor_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  v_post_id := v_feed.metadata->>'post_id';
  v_actor_name := public.social_actor_display_name(NEW.user_id);

  INSERT INTO public.social_notifications (user_id, actor_id, type, message, metadata, reference_id)
  VALUES (
    v_feed.actor_id,
    NEW.user_id,
    'feed_reaction',
    v_actor_name || ' reaccionó ' || NEW.emoji || ' a tu publicación',
    jsonb_build_object(
      'post_id', v_post_id,
      'emoji', NEW.emoji,
      'feed_notification_id', NEW.notification_id
    ),
    CASE WHEN v_post_id IS NOT NULL AND v_post_id <> '' THEN v_post_id::uuid ELSE NULL END
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_feed_reaction_notify ON public.feed_reactions;
CREATE TRIGGER on_feed_reaction_notify
  AFTER INSERT ON public.feed_reactions
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_feed_post_reaction();

CREATE OR REPLACE FUNCTION public.notify_feed_comment_reaction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_comment RECORD;
  v_actor_name TEXT;
BEGIN
  SELECT c.user_id, c.post_id
  INTO v_comment
  FROM public.feed_comments c
  WHERE c.id = NEW.comment_id;

  IF NOT FOUND OR v_comment.user_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  v_actor_name := public.social_actor_display_name(NEW.user_id);

  INSERT INTO public.social_notifications (user_id, actor_id, type, message, metadata, reference_id)
  VALUES (
    v_comment.user_id,
    NEW.user_id,
    'feed_comment_reaction',
    v_actor_name || ' reaccionó ' || NEW.emoji || ' a tu comentario',
    jsonb_build_object(
      'post_id', v_comment.post_id,
      'comment_id', NEW.comment_id,
      'emoji', NEW.emoji
    ),
    v_comment.post_id
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_feed_comment_reaction_notify ON public.feed_comment_reactions;
CREATE TRIGGER on_feed_comment_reaction_notify
  AFTER INSERT ON public.feed_comment_reactions
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_feed_comment_reaction();

CREATE OR REPLACE FUNCTION public.add_feed_comment(
  p_post_id UUID,
  p_body TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  trimmed TEXT;
  comment_id UUID;
  post_author_id UUID;
  v_actor_name TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  trimmed := trim(coalesce(p_body, ''));
  IF char_length(trimmed) = 0 OR char_length(trimmed) > 300 THEN
    RAISE EXCEPTION 'Invalid comment length';
  END IF;

  IF NOT public.can_view_feed_post(p_post_id) THEN
    RAISE EXCEPTION 'Cannot comment on this post';
  END IF;

  SELECT p.actor_id
  INTO post_author_id
  FROM public.feed_posts p
  WHERE p.id = p_post_id;

  INSERT INTO public.feed_comments (post_id, user_id, body)
  VALUES (p_post_id, auth.uid(), trimmed)
  RETURNING id INTO comment_id;

  IF post_author_id IS NOT NULL AND post_author_id <> auth.uid() THEN
    v_actor_name := public.social_actor_display_name(auth.uid());

    INSERT INTO public.social_notifications (user_id, actor_id, type, message, metadata, reference_id)
    VALUES (
      post_author_id,
      auth.uid(),
      'feed_comment',
      v_actor_name || ' comentó en tu publicación',
      jsonb_build_object(
        'post_id', p_post_id,
        'comment_id', comment_id,
        'preview', left(trimmed, 120)
      ),
      p_post_id
    );
  END IF;

  RETURN comment_id;
END;
$$;

REVOKE ALL ON FUNCTION public.add_feed_comment(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.add_feed_comment(UUID, TEXT) TO authenticated;
