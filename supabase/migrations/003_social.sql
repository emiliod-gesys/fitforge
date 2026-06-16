-- Social: amigos, notificaciones y visibilidad de perfiles/PRs entre amigos

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS search_name TEXT;

-- Sincronizar email de usuarios existentes
UPDATE public.profiles p
SET
  email = u.email,
  search_name = lower(COALESCE(p.display_name, split_part(u.email, '@', 1)))
FROM auth.users u
WHERE p.id = u.id AND p.email IS NULL;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_name TEXT;
BEGIN
  v_name := COALESCE(
    NEW.raw_user_meta_data->>'display_name',
    NEW.raw_user_meta_data->>'full_name',
    split_part(NEW.email, '@', 1)
  );
  INSERT INTO public.profiles (id, display_name, avatar_url, email, search_name)
  VALUES (
    NEW.id,
    v_name,
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.email,
    lower(v_name)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (requester_id, addressee_id),
  CHECK (requester_id <> addressee_id)
);

CREATE INDEX IF NOT EXISTS idx_friendships_requester ON public.friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON public.friendships(addressee_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON public.friendships(status);

ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own friendships"
  ON public.friendships FOR SELECT
  USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Users send friend requests"
  ON public.friendships FOR INSERT
  WITH CHECK (auth.uid() = requester_id AND status = 'pending');

CREATE POLICY "Addressee accepts or either removes"
  ON public.friendships FOR UPDATE
  USING (auth.uid() = requester_id OR auth.uid() = addressee_id)
  WITH CHECK (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Either party deletes friendship"
  ON public.friendships FOR DELETE
  USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE TABLE IF NOT EXISTS public.social_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  actor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'workout_completed',
  message TEXT NOT NULL,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_social_notifications_user ON public.social_notifications(user_id, created_at DESC);

ALTER TABLE public.social_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own notifications"
  ON public.social_notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users mark notifications read"
  ON public.social_notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.is_friend_with(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.friendships f
    WHERE f.status = 'accepted'
      AND (
        (f.requester_id = auth.uid() AND f.addressee_id = target_user_id)
        OR (f.addressee_id = auth.uid() AND f.requester_id = target_user_id)
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.has_friendship_with(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.friendships f
    WHERE (f.requester_id = auth.uid() AND f.addressee_id = target_user_id)
       OR (f.addressee_id = auth.uid() AND f.requester_id = target_user_id)
  );
$$;

REVOKE ALL ON FUNCTION public.is_friend_with(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_friend_with(UUID) TO authenticated;
REVOKE ALL ON FUNCTION public.has_friendship_with(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_friendship_with(UUID) TO authenticated;

DROP POLICY IF EXISTS "Users view own or friends profiles" ON public.profiles;
CREATE POLICY "Users view own or friends profiles"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id OR public.has_friendship_with(id));

CREATE POLICY "Friends view personal records"
  ON public.personal_records FOR SELECT
  USING (auth.uid() = user_id OR public.is_friend_with(user_id));

CREATE OR REPLACE FUNCTION public.search_users_for_friend(p_query TEXT)
RETURNS TABLE (id UUID, display_name TEXT, avatar_url TEXT, email TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  q TEXT := trim(lower(p_query));
BEGIN
  IF v_uid IS NULL OR length(q) < 2 THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT p.id, p.display_name, p.avatar_url, p.email
  FROM public.profiles p
  WHERE p.id <> v_uid
    AND (
      lower(p.email) = q
      OR p.search_name LIKE '%' || q || '%'
      OR lower(COALESCE(p.display_name, '')) LIKE '%' || q || '%'
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.friendships f
      WHERE (f.requester_id = v_uid AND f.addressee_id = p.id)
         OR (f.addressee_id = v_uid AND f.requester_id = p.id)
    )
  LIMIT 15;
END;
$$;

REVOKE ALL ON FUNCTION public.search_users_for_friend(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.search_users_for_friend(TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.notify_friends_workout_complete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  friend_id UUID;
  actor_name TEXT;
BEGIN
  IF OLD.completed_at IS NOT NULL OR NEW.completed_at IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(display_name, split_part(email, '@', 1), 'Tu amigo')
  INTO actor_name
  FROM public.profiles
  WHERE id = NEW.user_id;

  FOR friend_id IN
    SELECT CASE
      WHEN f.requester_id = NEW.user_id THEN f.addressee_id
      ELSE f.requester_id
    END
    FROM public.friendships f
    WHERE f.status = 'accepted'
      AND (f.requester_id = NEW.user_id OR f.addressee_id = NEW.user_id)
  LOOP
    INSERT INTO public.social_notifications (user_id, actor_id, type, message)
    VALUES (
      friend_id,
      NEW.user_id,
      'workout_completed',
      actor_name || ' completó "' || NEW.name || '"'
    );
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_workout_completed_notify_friends ON public.workouts;
CREATE TRIGGER on_workout_completed_notify_friends
  AFTER UPDATE OF completed_at ON public.workouts
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_friends_workout_complete();

ALTER PUBLICATION supabase_realtime ADD TABLE public.social_notifications;
