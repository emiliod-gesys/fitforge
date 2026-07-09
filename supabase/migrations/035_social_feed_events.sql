-- Feed social: metadata estructurada + eventos de medallas y niveles

ALTER TABLE public.social_notifications
  ADD COLUMN IF NOT EXISTS metadata JSONB;

COMMENT ON COLUMN public.social_notifications.metadata IS
  'Datos estructurados del evento (p. ej. milestone category/tier, level).';

-- Notifica a amigos aceptados (respeta silencios). Solo tipos de feed pasivos.
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

REVOKE ALL ON FUNCTION public.notify_friends_feed_event(TEXT, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.notify_friends_feed_event(TEXT, TEXT, JSONB) TO authenticated;
