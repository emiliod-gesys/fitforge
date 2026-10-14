-- La foto del entreno desaparece junto con la publicación (a las 24 h o si se borra antes).

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
  WHERE p.created_at < NOW() - INTERVAL '24 hours'
    AND coalesce(p.metadata->>'image_path', '') <> ''
    AND o.bucket_id = 'feed-media'
    AND o.name = p.metadata->>'image_path';

  DELETE FROM storage.objects o
  USING public.workouts w
  JOIN public.feed_posts p
    ON p.type = 'workout_completed'
   AND p.metadata->>'workout_id' = w.id::text
  WHERE p.created_at < NOW() - INTERVAL '24 hours'
    AND coalesce(w.finish_photo_path, '') <> ''
    AND o.bucket_id = 'feed-media'
    AND o.name = w.finish_photo_path;

  DELETE FROM storage.objects o
  USING public.social_notifications n
  WHERE n.created_at < NOW() - INTERVAL '24 hours'
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
  WHERE p.created_at < NOW() - INTERVAL '24 hours'
    AND p.type = 'workout_completed'
    AND p.metadata->>'workout_id' = w.id::text
    AND w.finish_photo_path IS NOT NULL;

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

CREATE OR REPLACE FUNCTION public.delete_feed_post(p_post_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage
AS $$
DECLARE
  post_actor_id UUID;
  image_path TEXT;
  workout_id TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT p.actor_id, p.metadata->>'image_path', p.metadata->>'workout_id'
  INTO post_actor_id, image_path, workout_id
  FROM public.feed_posts p
  WHERE p.id = p_post_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Post not found';
  END IF;

  IF post_actor_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  IF coalesce(image_path, '') <> '' THEN
    DELETE FROM storage.objects
    WHERE bucket_id = 'feed-media'
      AND name = image_path;
  END IF;

  UPDATE public.workouts
  SET finish_photo_path = NULL
  WHERE user_id = post_actor_id
    AND finish_photo_path IS NOT NULL
    AND (
      (coalesce(image_path, '') <> '' AND finish_photo_path = image_path)
      OR (coalesce(workout_id, '') <> '' AND id::text = workout_id)
    );

  DELETE FROM public.social_notifications
  WHERE metadata->>'post_id' = p_post_id::text;

  DELETE FROM public.feed_posts
  WHERE id = p_post_id
    AND actor_id = auth.uid();
END;
$$;
