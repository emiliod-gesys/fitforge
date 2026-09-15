-- Gymrat at 3 active referrals, Gymrat Pro at 5 (replaces the 5-only rule).

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

COMMENT ON COLUMN public.profiles.subscription_source IS
  'iap = store purchase; courtesy = manual comp; referral = Gymrat at 3 active referrals or Gymrat Pro at 5. Null on free.';
