-- Límite de rutinas guardadas según plan: Free 10, Gymrat 20, Gymrat Pro 50.

CREATE OR REPLACE FUNCTION public.max_saved_routines_for_tier(p_tier TEXT)
RETURNS INTEGER
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_tier
    WHEN 'gymrat' THEN 20
    WHEN 'gymrat_pro' THEN 50
    ELSE 10
  END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_routine_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  routine_count INTEGER;
  user_tier TEXT;
  max_routines INTEGER;
BEGIN
  SELECT subscription_tier
  INTO user_tier
  FROM public.profiles
  WHERE id = NEW.user_id;

  max_routines := public.max_saved_routines_for_tier(COALESCE(user_tier, 'free'));

  SELECT COUNT(*)
  INTO routine_count
  FROM public.routines
  WHERE user_id = NEW.user_id;

  IF routine_count >= max_routines THEN
    RAISE EXCEPTION 'routine_limit_reached'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS routines_limit_check ON public.routines;
CREATE TRIGGER routines_limit_check
  BEFORE INSERT ON public.routines
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_routine_limit();
