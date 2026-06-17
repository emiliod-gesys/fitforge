-- Fechas de entrenos completados visibles entre amigos (solo para stats de racha/semana)

CREATE OR REPLACE FUNCTION public.get_friend_workout_completion_dates(p_friend_id UUID)
RETURNS SETOF TIMESTAMPTZ
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_friend_with(p_friend_id) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT w.completed_at
  FROM public.workouts w
  WHERE w.user_id = p_friend_id
    AND w.completed_at IS NOT NULL
  ORDER BY w.completed_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_friend_workout_completion_dates(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_friend_workout_completion_dates(UUID) TO authenticated;
