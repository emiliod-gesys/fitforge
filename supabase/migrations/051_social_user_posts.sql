-- Publicaciones manuales en el feed social (texto ≤150 chars, imagen opcional, PR reciente).

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'feed-media',
  'feed-media',
  false,
  524288,
  ARRAY['image/jpeg', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Authenticated read feed media" ON storage.objects;
DROP POLICY IF EXISTS "Users upload own feed media" ON storage.objects;
DROP POLICY IF EXISTS "Users update own feed media" ON storage.objects;
DROP POLICY IF EXISTS "Users delete own feed media" ON storage.objects;

CREATE POLICY "Authenticated read feed media"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'feed-media');

CREATE POLICY "Users upload own feed media"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'feed-media'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users update own feed media"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'feed-media'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'feed-media'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users delete own feed media"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'feed-media'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

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
  friend_id UUID;
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

  INSERT INTO public.social_notifications (user_id, actor_id, type, message, metadata)
  VALUES (actor_id, actor_id, 'user_post', trimmed, meta);

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
    VALUES (friend_id, actor_id, 'user_post', trimmed, meta);
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.create_feed_post(TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_feed_post(TEXT, JSONB) TO authenticated;

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
