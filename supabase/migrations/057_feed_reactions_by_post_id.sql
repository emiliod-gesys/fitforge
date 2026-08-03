-- Reacciones del feed ancladas al post canónico (feed_posts), no a cada
-- copia fan-out de social_notifications. Así autor y amigos ven las mismas.

ALTER TABLE public.feed_reactions
  ADD COLUMN IF NOT EXISTS post_id UUID REFERENCES public.feed_posts(id) ON DELETE CASCADE;

UPDATE public.feed_reactions fr
SET post_id = NULLIF(n.metadata->>'post_id', '')::uuid
FROM public.social_notifications n
WHERE fr.notification_id = n.id
  AND fr.post_id IS NULL
  AND NULLIF(n.metadata->>'post_id', '') IS NOT NULL;

-- Si el mismo usuario reaccionó en copias distintas del mismo post, conservar una.
DELETE FROM public.feed_reactions a
USING public.feed_reactions b
WHERE a.post_id IS NOT NULL
  AND a.post_id = b.post_id
  AND a.user_id = b.user_id
  AND a.ctid > b.ctid;

ALTER TABLE public.feed_reactions
  ALTER COLUMN notification_id DROP NOT NULL;

ALTER TABLE public.feed_reactions
  DROP CONSTRAINT IF EXISTS feed_reactions_notification_id_fkey;

ALTER TABLE public.feed_reactions
  ADD CONSTRAINT feed_reactions_notification_id_fkey
  FOREIGN KEY (notification_id)
  REFERENCES public.social_notifications(id)
  ON DELETE SET NULL;

ALTER TABLE public.feed_reactions
  DROP CONSTRAINT IF EXISTS feed_reactions_notification_id_user_id_key;

CREATE UNIQUE INDEX IF NOT EXISTS feed_reactions_post_id_user_id_key
  ON public.feed_reactions (post_id, user_id)
  WHERE post_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS feed_reactions_notification_id_user_id_legacy_key
  ON public.feed_reactions (notification_id, user_id)
  WHERE notification_id IS NOT NULL AND post_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_feed_reactions_post
  ON public.feed_reactions(post_id);

DROP POLICY IF EXISTS "Users read reactions on own feed" ON public.feed_reactions;
DROP POLICY IF EXISTS "Users insert own feed reactions" ON public.feed_reactions;
DROP POLICY IF EXISTS "Users update own feed reactions" ON public.feed_reactions;
DROP POLICY IF EXISTS "Users delete own feed reactions" ON public.feed_reactions;

CREATE POLICY "View feed reactions when allowed"
  ON public.feed_reactions FOR SELECT
  TO authenticated
  USING (
    (post_id IS NOT NULL AND public.can_view_feed_post(post_id))
    OR (
      post_id IS NULL
      AND notification_id IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.social_notifications n
        WHERE n.id = notification_id
          AND n.user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Insert own feed reactions"
  ON public.feed_reactions FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND (
      (post_id IS NOT NULL AND public.can_view_feed_post(post_id))
      OR (
        post_id IS NULL
        AND notification_id IS NOT NULL
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
      )
    )
  );

CREATE POLICY "Update own feed reactions"
  ON public.feed_reactions FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Delete own feed reactions"
  ON public.feed_reactions FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.notify_feed_post_reaction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_id UUID;
  v_actor_name TEXT;
  v_post_id TEXT;
BEGIN
  IF NEW.post_id IS NOT NULL THEN
    SELECT p.actor_id, p.id::text
    INTO v_actor_id, v_post_id
    FROM public.feed_posts p
    WHERE p.id = NEW.post_id;
  ELSIF NEW.notification_id IS NOT NULL THEN
    SELECT n.actor_id, n.metadata->>'post_id'
    INTO v_actor_id, v_post_id
    FROM public.social_notifications n
    WHERE n.id = NEW.notification_id;
  ELSE
    RETURN NEW;
  END IF;

  IF v_actor_id IS NULL OR v_actor_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  v_actor_name := public.social_actor_display_name(NEW.user_id);

  INSERT INTO public.social_notifications (user_id, actor_id, type, message, metadata, reference_id)
  VALUES (
    v_actor_id,
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
