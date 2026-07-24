-- Permite adjuntar cualquier PR actual del usuario, no solo los de los últimos 30 días.

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
    ) THEN
      RAISE EXCEPTION 'Personal record not found';
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
