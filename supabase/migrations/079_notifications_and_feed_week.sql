-- Avisos del celular (activos si no hay fila) y feed de 7 días.

CREATE TABLE IF NOT EXISTS public.notification_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  rest_end BOOLEAN NOT NULL DEFAULT TRUE,
  friend_requests BOOLEAN NOT NULL DEFAULT TRUE,
  comments BOOLEAN NOT NULL DEFAULT TRUE,
  routines BOOLEAN NOT NULL DEFAULT TRUE,
  friend_activity BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own notification settings"
  ON public.notification_settings;
CREATE POLICY "Users manage own notification settings"
  ON public.notification_settings FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_settings TO authenticated;

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
      AND p.created_at >= NOW() - INTERVAL '7 days'
      AND (
        p.actor_id = auth.uid()
        OR public.is_friend_with(p.actor_id)
      )
  );
$$;

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
  USING public.feed_posts p
  WHERE p.created_at < NOW() - INTERVAL '7 days'
    AND coalesce(p.metadata->>'image_path', '') <> ''
    AND o.bucket_id = 'feed-media'
    AND o.name = p.metadata->>'image_path';

  DELETE FROM storage.objects o
  USING public.workouts w
  JOIN public.feed_posts p
    ON p.type = 'workout_completed'
   AND p.metadata->>'workout_id' = w.id::text
  WHERE p.created_at < NOW() - INTERVAL '7 days'
    AND coalesce(w.finish_photo_path, '') <> ''
    AND o.bucket_id = 'feed-media'
    AND o.name = w.finish_photo_path;

  DELETE FROM storage.objects o
  USING public.social_notifications n
  WHERE n.created_at < NOW() - INTERVAL '7 days'
    AND n.type IN (
      'workout_completed',
      'milestone_unlocked',
      'level_up',
      'pr_unlocked',
      'user_post'
    )
    AND coalesce(n.metadata->>'image_path', '') <> ''
    AND o.bucket_id = 'feed-media'
    AND o.name = n.metadata->>'image_path';

  UPDATE public.workouts w
  SET finish_photo_path = NULL
  FROM public.feed_posts p
  WHERE p.created_at < NOW() - INTERVAL '7 days'
    AND p.type = 'workout_completed'
    AND p.metadata->>'workout_id' = w.id::text
    AND w.finish_photo_path IS NOT NULL;

  DELETE FROM public.feed_posts
  WHERE created_at < NOW() - INTERVAL '7 days';

  DELETE FROM public.social_notifications
  WHERE type IN (
      'workout_completed',
      'milestone_unlocked',
      'level_up',
      'pr_unlocked',
      'user_post'
    )
    AND created_at < NOW() - INTERVAL '7 days';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;
