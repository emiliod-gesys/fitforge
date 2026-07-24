-- Reacciones en comentarios del feed y borrado de publicaciones propias.

CREATE TABLE IF NOT EXISTS public.feed_comment_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL REFERENCES public.feed_comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL CHECK (emoji IN ('💪', '🔥', '👏', '🏆', '❤️')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (comment_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_feed_comment_reactions_comment
  ON public.feed_comment_reactions(comment_id);

ALTER TABLE public.feed_comment_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View comment reactions when allowed"
  ON public.feed_comment_reactions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.feed_comments c
      WHERE c.id = comment_id
        AND public.can_view_feed_post(c.post_id)
    )
  );

CREATE POLICY "Insert own comment reactions"
  ON public.feed_comment_reactions FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.feed_comments c
      WHERE c.id = comment_id
        AND public.can_view_feed_post(c.post_id)
    )
  );

CREATE POLICY "Update own comment reactions"
  ON public.feed_comment_reactions FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Delete own comment reactions"
  ON public.feed_comment_reactions FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Authors delete own feed posts" ON public.feed_posts;

CREATE POLICY "Authors delete own feed posts"
  ON public.feed_posts FOR DELETE
  TO authenticated
  USING (actor_id = auth.uid());

CREATE OR REPLACE FUNCTION public.delete_feed_post(p_post_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage
AS $$
DECLARE
  post_actor_id UUID;
  image_path TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT p.actor_id, p.metadata->>'image_path'
  INTO post_actor_id, image_path
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

  DELETE FROM public.social_notifications
  WHERE metadata->>'post_id' = p_post_id::text;

  DELETE FROM public.feed_posts
  WHERE id = p_post_id
    AND actor_id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.delete_feed_post(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_feed_post(UUID) TO authenticated;
