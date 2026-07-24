-- Comentarios en publicaciones del feed (post canónico compartido entre amigos).

CREATE TABLE IF NOT EXISTS public.feed_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  message TEXT NOT NULL DEFAULT '',
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feed_posts_actor_created
  ON public.feed_posts(actor_id, created_at DESC);

ALTER TABLE public.feed_posts ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.feed_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.feed_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body TEXT NOT NULL CHECK (char_length(trim(body)) BETWEEN 1 AND 300),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feed_comments_post_created
  ON public.feed_comments(post_id, created_at ASC);

ALTER TABLE public.feed_comments ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.can_view_feed_post(p_post_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.feed_posts p
    WHERE p.id = p_post_id
      AND p.created_at >= NOW() - INTERVAL '24 hours'
      AND (
        p.actor_id = auth.uid()
        OR public.is_friend_with(p.actor_id)
      )
  );
$$;

REVOKE ALL ON FUNCTION public.can_view_feed_post(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_view_feed_post(UUID) TO authenticated;

CREATE POLICY "View feed posts when allowed"
  ON public.feed_posts FOR SELECT
  TO authenticated
  USING (public.can_view_feed_post(id));

CREATE POLICY "View feed comments when allowed"
  ON public.feed_comments FOR SELECT
  TO authenticated
  USING (public.can_view_feed_post(post_id));

CREATE POLICY "Insert own feed comments"
  ON public.feed_comments FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND public.can_view_feed_post(post_id)
  );

CREATE POLICY "Delete own feed comments"
  ON public.feed_comments FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.publish_feed_post(
  p_actor_id UUID,
  p_type TEXT,
  p_message TEXT,
  p_metadata JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_post_id UUID;
  v_meta JSONB;
  friend_id UUID;
BEGIN
  v_meta := coalesce(p_metadata, '{}'::jsonb);

  INSERT INTO public.feed_posts (actor_id, type, message, metadata)
  VALUES (p_actor_id, p_type, p_message, v_meta)
  RETURNING id INTO v_post_id;

  v_meta := v_meta || jsonb_build_object('post_id', v_post_id);

  INSERT INTO public.social_notifications (user_id, actor_id, type, message, metadata)
  VALUES (p_actor_id, p_actor_id, p_type, p_message, v_meta);

  FOR friend_id IN
    SELECT CASE
      WHEN f.requester_id = p_actor_id THEN f.addressee_id
      ELSE f.requester_id
    END
    FROM public.friendships f
    WHERE f.status = 'accepted'
      AND (f.requester_id = p_actor_id OR f.addressee_id = p_actor_id)
  LOOP
    IF public.is_friend_muted(friend_id, p_actor_id) THEN
      CONTINUE;
    END IF;

    INSERT INTO public.social_notifications (user_id, actor_id, type, message, metadata)
    VALUES (friend_id, p_actor_id, p_type, p_message, v_meta);
  END LOOP;

  RETURN v_post_id;
END;
$$;

REVOKE ALL ON FUNCTION public.publish_feed_post(UUID, TEXT, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.publish_feed_post(UUID, TEXT, TEXT, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION public.create_feed_post(
  p_text TEXT,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  actor_id UUID;
  trimmed TEXT;
  meta JSONB;
  pr_exercise_id TEXT;
  pr_record_type TEXT;
BEGIN
  actor_id := auth.uid();
  IF actor_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  trimmed := left(trim(coalesce(p_text, '')), 150);
  meta := coalesce(p_metadata, '{}'::jsonb);

  IF char_length(trim(coalesce(p_text, ''))) > 150 THEN
    RAISE EXCEPTION 'Post text exceeds 150 characters';
  END IF;

  IF trimmed = ''
     AND coalesce(meta->>'image_path', '') = ''
     AND meta->'pr' IS NULL THEN
    RAISE EXCEPTION 'Post must include text, image, or a personal record';
  END IF;

  IF meta ? 'pr' THEN
    pr_exercise_id := meta->'pr'->>'exercise_id';
    pr_record_type := coalesce(meta->'pr'->>'record_type', 'strength');
    IF pr_exercise_id IS NULL OR char_length(pr_exercise_id) = 0 THEN
      RAISE EXCEPTION 'Invalid personal record metadata';
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM public.personal_records pr
      WHERE pr.user_id = actor_id
        AND pr.exercise_id = pr_exercise_id
        AND pr.record_type = pr_record_type
        AND pr.achieved_at >= NOW() - INTERVAL '30 days'
    ) THEN
      RAISE EXCEPTION 'Personal record not found or too old';
    END IF;
  END IF;

  IF coalesce(meta->>'image_path', '') <> ''
     AND (storage.foldername(meta->>'image_path'))[1] <> actor_id::text THEN
    RAISE EXCEPTION 'Invalid image path';
  END IF;

  meta := meta || jsonb_build_object('text', trimmed);

  PERFORM public.publish_feed_post(actor_id, 'user_post', trimmed, meta);
END;
$$;

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
  actor_id UUID;
BEGIN
  actor_id := auth.uid();
  IF actor_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_type NOT IN ('milestone_unlocked', 'level_up', 'pr_unlocked') THEN
    RAISE EXCEPTION 'Invalid feed event type';
  END IF;

  PERFORM public.publish_feed_post(actor_id, p_type, p_message, p_metadata);
END;
$$;

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
    jsonb_build_object('workout_name', NEW.name)
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

  INSERT INTO public.feed_comments (post_id, user_id, body)
  VALUES (p_post_id, auth.uid(), trimmed)
  RETURNING id INTO comment_id;

  RETURN comment_id;
END;
$$;

REVOKE ALL ON FUNCTION public.add_feed_comment(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.add_feed_comment(UUID, TEXT) TO authenticated;

DROP POLICY IF EXISTS "Users insert own feed reactions" ON public.feed_reactions;

CREATE POLICY "Users insert own feed reactions"
  ON public.feed_reactions FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.social_notifications n
      WHERE n.id = notification_id
        AND n.user_id = auth.uid()
        AND n.type IN (
          'workout_completed',
          'milestone_unlocked',
          'level_up',
          'pr_unlocked',
          'user_post'
        )
    )
  );

CREATE OR REPLACE FUNCTION public.cleanup_old_social_feed_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM storage.objects o
  USING public.social_notifications n
  WHERE n.type = 'user_post'
    AND n.created_at < NOW() - INTERVAL '24 hours'
    AND coalesce(n.metadata->>'image_path', '') <> ''
    AND o.bucket_id = 'feed-media'
    AND o.name = n.metadata->>'image_path';

  DELETE FROM public.feed_posts
  WHERE created_at < NOW() - INTERVAL '24 hours';

  DELETE FROM public.social_notifications
  WHERE type IN (
      'workout_completed',
      'milestone_unlocked',
      'level_up',
      'pr_unlocked',
      'user_post'
    )
    AND created_at < NOW() - INTERVAL '24 hours';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;
