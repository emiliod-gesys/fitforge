-- Códigos de referido por usuario: Gymrat con 3 activos, Gymrat Pro con 5.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS referral_code text;

CREATE OR REPLACE FUNCTION public.generate_referral_code()
RETURNS text
LANGUAGE plpgsql
VOLATILE
SET search_path = public
AS $$
DECLARE
  digits constant text := '23456789';
  letters constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ';
  code text;
  i int;
BEGIN
  FOR i IN 1..40 LOOP
    code :=
      substr(digits, 1 + (floor(random() * 8))::int, 1) ||
      substr(digits, 1 + (floor(random() * 8))::int, 1) ||
      substr(digits, 1 + (floor(random() * 8))::int, 1) ||
      substr(letters, 1 + (floor(random() * 23))::int, 1) ||
      substr(letters, 1 + (floor(random() * 23))::int, 1) ||
      substr(letters, 1 + (floor(random() * 23))::int, 1);
    IF NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE referral_code = code
    ) THEN
      RETURN code;
    END IF;
  END LOOP;
  RAISE EXCEPTION 'referral_code_generation_failed';
END;
$$;

REVOKE ALL ON FUNCTION public.generate_referral_code() FROM PUBLIC;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT id FROM public.profiles WHERE referral_code IS NULL
  LOOP
    UPDATE public.profiles
    SET referral_code = public.generate_referral_code()
    WHERE id = r.id;
  END LOOP;
END;
$$;

ALTER TABLE public.profiles
  ALTER COLUMN referral_code SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'profiles_referral_code_key'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_referral_code_key UNIQUE (referral_code);
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'profiles_referral_code_format'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_referral_code_format
      CHECK (referral_code ~ '^[2-9]{3}[ABCDEFGHJKMNPQRSTUVWXYZ]{3}$');
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_referral_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.referral_code IS DISTINCT FROM OLD.referral_code THEN
    RAISE EXCEPTION 'referral_code_immutable'
      USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_protect_referral_code ON public.profiles;
CREATE TRIGGER profiles_protect_referral_code
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_referral_code();

CREATE TABLE IF NOT EXISTS public.referrals (
  referred_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  referrer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT referrals_no_self CHECK (referred_id <> referrer_id)
);

CREATE INDEX IF NOT EXISTS referrals_referrer_idx
  ON public.referrals (referrer_id);

ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Referrers view own referrals" ON public.referrals;
CREATE POLICY "Referrers view own referrals"
  ON public.referrals FOR SELECT
  USING (referrer_id = auth.uid());

GRANT SELECT ON TABLE public.referrals TO authenticated;

CREATE OR REPLACE FUNCTION public.is_referral_active(
  p_user_id uuid,
  p_now timestamptz DEFAULT now()
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_created timestamptz;
  v_count int;
  v_week_start timestamptz;
BEGIN
  SELECT created_at INTO v_created
  FROM public.profiles
  WHERE id = p_user_id;

  IF v_created IS NULL THEN
    RETURN false;
  END IF;

  IF v_created > p_now - interval '7 days' THEN
    RETURN true;
  END IF;

  v_week_start := date_trunc('week', timezone('UTC', p_now)) AT TIME ZONE 'UTC';

  SELECT count(*)::int
  INTO v_count
  FROM public.workouts
  WHERE user_id = p_user_id
    AND completed_at IS NOT NULL
    AND completed_at >= v_week_start - interval '7 days'
    AND completed_at < v_week_start;

  RETURN COALESCE(v_count, 0) >= 2;
END;
$$;

REVOKE ALL ON FUNCTION public.is_referral_active(uuid, timestamptz) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.referral_active_count(
  p_referrer_id uuid,
  p_now timestamptz DEFAULT now()
)
RETURNS integer
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT count(*)::int
  FROM public.referrals r
  WHERE r.referrer_id = p_referrer_id
    AND public.is_referral_active(r.referred_id, p_now);
$$;

REVOKE ALL ON FUNCTION public.referral_active_count(uuid, timestamptz) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.sync_referral_entitlement(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count int;
  v_tier text;
  v_source text;
BEGIN
  v_count := public.referral_active_count(p_user_id);

  SELECT subscription_tier, subscription_source
  INTO v_tier, v_source
  FROM public.profiles
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  IF v_source IN ('iap', 'courtesy') THEN
    RETURN;
  END IF;

  IF v_count >= 5 THEN
    UPDATE public.profiles
    SET subscription_tier = 'gymrat_pro',
        subscription_source = 'referral',
        subscription_product_id = NULL,
        subscription_expires_at = NULL,
        updated_at = now()
    WHERE id = p_user_id
      AND (
        subscription_tier IS DISTINCT FROM 'gymrat_pro'
        OR subscription_source IS DISTINCT FROM 'referral'
      );
  ELSIF v_count >= 3 THEN
    UPDATE public.profiles
    SET subscription_tier = 'gymrat',
        subscription_source = 'referral',
        subscription_product_id = NULL,
        subscription_expires_at = NULL,
        updated_at = now()
    WHERE id = p_user_id
      AND (
        subscription_tier IS DISTINCT FROM 'gymrat'
        OR subscription_source IS DISTINCT FROM 'referral'
      );
  ELSIF v_source = 'referral' THEN
    UPDATE public.profiles
    SET subscription_tier = 'free',
        subscription_source = NULL,
        subscription_product_id = NULL,
        subscription_expires_at = NULL,
        updated_at = now()
    WHERE id = p_user_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_referral_entitlement(uuid) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.sync_all_referral_entitlements()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
  n int := 0;
BEGIN
  FOR v_id IN SELECT DISTINCT referrer_id FROM public.referrals
  LOOP
    PERFORM public.sync_referral_entitlement(v_id);
    n := n + 1;
  END LOOP;
  RETURN n;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_all_referral_entitlements() FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.apply_referral_code(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_code text;
  v_referrer uuid;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'unauthenticated');
  END IF;

  v_code := upper(regexp_replace(coalesce(p_code, ''), '[^a-zA-Z0-9]', '', 'g'));

  IF length(v_code) <> 6
     OR v_code !~ '^[2-9]{3}[ABCDEFGHJKMNPQRSTUVWXYZ]{3}$' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid');
  END IF;

  IF EXISTS (SELECT 1 FROM public.referrals WHERE referred_id = v_uid) THEN
    RETURN jsonb_build_object('ok', true, 'already', true);
  END IF;

  SELECT id INTO v_referrer
  FROM public.profiles
  WHERE referral_code = v_code;

  IF v_referrer IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  IF v_referrer = v_uid THEN
    RETURN jsonb_build_object('ok', false, 'error', 'self');
  END IF;

  INSERT INTO public.referrals (referred_id, referrer_id)
  VALUES (v_uid, v_referrer);

  PERFORM public.sync_referral_entitlement(v_referrer);
  RETURN jsonb_build_object('ok', true);
END;
$$;

REVOKE ALL ON FUNCTION public.apply_referral_code(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.apply_referral_code(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.list_my_referrals()
RETURNS TABLE (
  user_id uuid,
  display_name text,
  avatar_url text,
  created_at timestamptz,
  is_active boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RETURN;
  END IF;

  PERFORM public.sync_referral_entitlement(v_uid);

  RETURN QUERY
  SELECT
    p.id,
    p.display_name,
    p.avatar_url,
    r.created_at,
    public.is_referral_active(p.id)
  FROM public.referrals r
  JOIN public.profiles p ON p.id = r.referred_id
  WHERE r.referrer_id = v_uid
  ORDER BY r.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.list_my_referrals() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_my_referrals() TO authenticated;

CREATE OR REPLACE FUNCTION public.referrals_on_workout_completed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_referrer uuid;
BEGIN
  IF NEW.completed_at IS NULL THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.completed_at IS NOT NULL THEN
    RETURN NEW;
  END IF;

  SELECT referrer_id INTO v_referrer
  FROM public.referrals
  WHERE referred_id = NEW.user_id;

  IF v_referrer IS NOT NULL THEN
    PERFORM public.sync_referral_entitlement(v_referrer);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS workouts_referral_entitlement ON public.workouts;
CREATE TRIGGER workouts_referral_entitlement
  AFTER INSERT OR UPDATE OF completed_at ON public.workouts
  FOR EACH ROW
  EXECUTE FUNCTION public.referrals_on_workout_completed();

DO $source$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT con.conname
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE nsp.nspname = 'public'
      AND rel.relname = 'profiles'
      AND con.contype = 'c'
      AND pg_get_constraintdef(con.oid) ILIKE '%subscription_source%'
  LOOP
    EXECUTE format('ALTER TABLE public.profiles DROP CONSTRAINT %I', r.conname);
  END LOOP;
END;
$source$;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_subscription_source_check
  CHECK (
    subscription_source IS NULL
    OR subscription_source IN ('iap', 'courtesy', 'referral')
  );

COMMENT ON COLUMN public.profiles.subscription_source IS
  'iap = store purchase; courtesy = manual comp; referral = Gymrat at 3 active referrals or Gymrat Pro at 5. Null on free.';
COMMENT ON COLUMN public.profiles.referral_code IS
  'Unique shareable code: 3 digits (2-9) + 3 letters. Immutable.';

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_name TEXT;
  v_avatar TEXT;
BEGIN
  v_name := COALESCE(
    NEW.raw_user_meta_data->>'display_name',
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(NEW.email, '@', 1)
  );

  v_avatar := COALESCE(
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.raw_user_meta_data->>'picture',
    NEW.raw_user_meta_data->'user_metadata'->>'avatar_url'
  );

  INSERT INTO public.profiles (id, display_name, avatar_url, email, search_name, referral_code)
  VALUES (
    NEW.id,
    v_name,
    v_avatar,
    NEW.email,
    lower(v_name),
    public.generate_referral_code()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

DO $cron$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'cron') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'sync_referral_entitlements';

    PERFORM cron.schedule(
      'sync_referral_entitlements',
      '10 0 * * *',
      $job$SELECT public.sync_all_referral_entitlements();$job$
    );
  END IF;
END;
$cron$;
