-- Reacciones con emoji en publicaciones del feed (máx. 5 tipos).

CREATE TABLE IF NOT EXISTS public.feed_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES public.social_notifications(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL CHECK (emoji IN ('💪', '🔥', '👏', '🏆', '❤️')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (notification_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_feed_reactions_notification
  ON public.feed_reactions(notification_id);

ALTER TABLE public.feed_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read reactions on own feed"
  ON public.feed_reactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.social_notifications n
      WHERE n.id = notification_id
        AND n.user_id = auth.uid()
    )
  );

CREATE POLICY "Users insert own feed reactions"
  ON public.feed_reactions FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.social_notifications n
      WHERE n.id = notification_id
        AND n.user_id = auth.uid()
        AND n.type IN ('workout_completed', 'milestone_unlocked', 'level_up', 'pr_unlocked')
    )
  );

CREATE POLICY "Users update own feed reactions"
  ON public.feed_reactions FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users delete own feed reactions"
  ON public.feed_reactions FOR DELETE
  USING (user_id = auth.uid());
