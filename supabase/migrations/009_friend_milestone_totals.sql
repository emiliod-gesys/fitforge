-- Totales de milestones visibles entre amigos aceptados

CREATE OR REPLACE FUNCTION public.get_friend_milestone_data(p_friend_id UUID)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_friend_with(p_friend_id) THEN
    RETURN NULL;
  END IF;

  SELECT json_build_object(
    'workouts', COALESCE((
      SELECT json_agg(
        json_build_object(
          'duration_minutes', w.duration_minutes,
          'total_volume', w.total_volume
        )
        ORDER BY w.completed_at DESC
      )
      FROM public.workouts w
      WHERE w.user_id = p_friend_id
        AND w.completed_at IS NOT NULL
    ), '[]'::json),
    'total_reps', COALESCE((
      SELECT SUM(ws.reps)::bigint
      FROM public.workout_sets ws
      JOIN public.workout_exercises we ON we.id = ws.workout_exercise_id
      JOIN public.workouts w ON w.id = we.workout_id
      WHERE w.user_id = p_friend_id
        AND w.completed_at IS NOT NULL
        AND ws.completed = TRUE
        AND COALESCE(ws.logging_type, 'strength') = 'strength'
    ), 0),
    'total_distance_meters', COALESCE((
      SELECT SUM(ws.distance_meters)::double precision
      FROM public.workout_sets ws
      JOIN public.workout_exercises we ON we.id = ws.workout_exercise_id
      JOIN public.workouts w ON w.id = we.workout_id
      WHERE w.user_id = p_friend_id
        AND w.completed_at IS NOT NULL
        AND ws.completed = TRUE
        AND ws.logging_type = 'cardio'
        AND ws.distance_meters IS NOT NULL
        AND ws.distance_meters > 0
    ), 0)
  )
  INTO v_result;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_friend_milestone_data(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_friend_milestone_data(UUID) TO authenticated;
