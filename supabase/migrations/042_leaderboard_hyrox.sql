-- Leaderboards: categoría Hyrox (mejor tiempo de la rutina Race Day 100%).
-- El tiempo se mide en segundos (menor es mejor). Solo cuentan entrenamientos
-- completados de una rutina Hyrox de nivel 'race'. Los usuarios sin un Race Day
-- completado quedan fuera de esta clasificación.

CREATE OR REPLACE FUNCTION public.get_leaderboard(
  p_metric TEXT,
  p_scope TEXT DEFAULT 'friends',
  p_period TEXT DEFAULT 'all',
  p_limit INT DEFAULT 50
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_result JSON;
  v_period_start TIMESTAMPTZ;
  v_limit INT;
BEGIN
  IF v_uid IS NULL THEN
    RETURN json_build_object(
      'entries', '[]'::json,
      'current_user_outside_top', NULL,
      'has_more', FALSE
    );
  END IF;

  IF p_metric NOT IN ('level', 'volume', 'workouts', 'distance', 'calories', 'reps', 'hyrox') THEN
    RAISE EXCEPTION 'Invalid metric: %', p_metric;
  END IF;

  IF p_scope NOT IN ('friends', 'global') THEN
    RAISE EXCEPTION 'Invalid scope: %', p_scope;
  END IF;

  IF p_period NOT IN ('week', 'month', 'all') THEN
    RAISE EXCEPTION 'Invalid period: %', p_period;
  END IF;

  v_limit := GREATEST(1, LEAST(COALESCE(p_limit, 50), 500));

  v_period_start := CASE p_period
    WHEN 'week' THEN date_trunc('week', timezone('utc', now()))
    WHEN 'month' THEN date_trunc('month', timezone('utc', now()))
    ELSE NULL
  END;

  WITH friend_ids AS (
    SELECT v_uid AS user_id
    UNION
    SELECT CASE
      WHEN f.requester_id = v_uid THEN f.addressee_id
      ELSE f.requester_id
    END
    FROM public.friendships f
    WHERE f.status = 'accepted'
      AND (f.requester_id = v_uid OR f.addressee_id = v_uid)
  ),
  scope_users AS (
    SELECT p.id AS user_id, p.display_name, p.avatar_url, p.total_xp, p.body_weight
    FROM public.profiles p
    WHERE p_scope = 'global'
       OR p.id IN (SELECT user_id FROM friend_ids)
  ),
  workout_stats AS (
    SELECT
      w.user_id,
      COALESCE(SUM(w.total_volume), 0)::double precision AS total_volume,
      COUNT(DISTINCT (w.completed_at AT TIME ZONE 'UTC')::date)::bigint AS total_workouts,
      COALESCE(SUM(
        CASE
          WHEN w.duration_minutes >= 1 THEN
            GREATEST(1, ROUND(
              (
                3.5 + LEAST(
                  1.0,
                  GREATEST(
                    0.0,
                    (COALESCE(w.total_volume, 0) / NULLIF(w.duration_minutes, 0) - 40) / 150.0
                  )
                ) * 2.5
              )
              * COALESCE(NULLIF(su.body_weight, 0), 70)
              * (w.duration_minutes::double precision / 60.0) * 0.55
              + COALESCE(w.total_volume, 0) * 0.00045
            )::bigint)
          ELSE 0
        END
      ), 0)::bigint AS total_calories
    FROM public.workouts w
    INNER JOIN scope_users su ON su.user_id = w.user_id
    WHERE w.completed_at IS NOT NULL
      AND (v_period_start IS NULL OR w.completed_at >= v_period_start)
    GROUP BY w.user_id
  ),
  set_stats AS (
    SELECT
      w.user_id,
      COALESCE(SUM(ws.reps) FILTER (
        WHERE ws.completed = TRUE AND COALESCE(ws.logging_type, 'strength') = 'strength'
      ), 0)::bigint AS total_reps,
      COALESCE(SUM(ws.distance_meters) FILTER (
        WHERE ws.completed = TRUE
          AND ws.logging_type = 'cardio'
          AND ws.distance_meters IS NOT NULL
          AND ws.distance_meters > 0
      ), 0)::double precision AS total_distance
    FROM public.workouts w
    INNER JOIN scope_users su ON su.user_id = w.user_id
    INNER JOIN public.workout_exercises we ON we.workout_id = w.id
    INNER JOIN public.workout_sets ws ON ws.workout_exercise_id = we.id
    WHERE w.completed_at IS NOT NULL
      AND (v_period_start IS NULL OR w.completed_at >= v_period_start)
    GROUP BY w.user_id
  ),
  hyrox_stats AS (
    SELECT
      w.user_id,
      MIN(
        GREATEST(
          1,
          EXTRACT(EPOCH FROM (w.completed_at - w.started_at))
        )
      )::double precision AS best_race_seconds
    FROM public.workouts w
    INNER JOIN scope_users su ON su.user_id = w.user_id
    INNER JOIN public.routines r ON r.id = w.routine_id
    WHERE w.completed_at IS NOT NULL
      AND r.hyrox_level = 'race'
      AND r.is_hyrox_system = TRUE
      AND (v_period_start IS NULL OR w.completed_at >= v_period_start)
    GROUP BY w.user_id
  ),
  period_xp AS (
    SELECT
      w.user_id,
      COALESCE(SUM(w.xp_awarded), 0)::bigint AS xp_in_period
    FROM public.workouts w
    INNER JOIN scope_users su ON su.user_id = w.user_id
    WHERE w.completed_at IS NOT NULL
      AND w.xp_awarded IS NOT NULL
      AND (v_period_start IS NULL OR w.completed_at >= v_period_start)
    GROUP BY w.user_id
  ),
  ranked AS (
    SELECT
      su.user_id,
      su.display_name,
      su.avatar_url,
      su.total_xp,
      COALESCE(wst.total_volume, 0) AS total_volume,
      COALESCE(wst.total_workouts, 0) AS total_workouts,
      COALESCE(wst.total_calories, 0) AS total_calories,
      COALESCE(ss.total_reps, 0) AS total_reps,
      COALESCE(ss.total_distance, 0) AS total_distance,
      CASE p_metric
        WHEN 'level' THEN
          CASE
            WHEN p_period = 'all' THEN su.total_xp::double precision
            ELSE COALESCE(px.xp_in_period, 0)::double precision
          END
        WHEN 'volume' THEN COALESCE(wst.total_volume, 0)
        WHEN 'workouts' THEN COALESCE(wst.total_workouts, 0)::double precision
        WHEN 'distance' THEN COALESCE(ss.total_distance, 0)
        WHEN 'calories' THEN COALESCE(wst.total_calories, 0)::double precision
        WHEN 'reps' THEN COALESCE(ss.total_reps, 0)::double precision
        WHEN 'hyrox' THEN hs.best_race_seconds
      END AS metric_value,
      ROW_NUMBER() OVER (
        ORDER BY
          CASE
            WHEN p_metric = 'hyrox' THEN NULL
            ELSE
              CASE p_metric
                WHEN 'level' THEN
                  CASE
                    WHEN p_period = 'all' THEN su.total_xp::double precision
                    ELSE COALESCE(px.xp_in_period, 0)::double precision
                  END
                WHEN 'volume' THEN COALESCE(wst.total_volume, 0)
                WHEN 'workouts' THEN COALESCE(wst.total_workouts, 0)::double precision
                WHEN 'distance' THEN COALESCE(ss.total_distance, 0)
                WHEN 'calories' THEN COALESCE(wst.total_calories, 0)::double precision
                WHEN 'reps' THEN COALESCE(ss.total_reps, 0)::double precision
              END
          END DESC NULLS LAST,
          CASE WHEN p_metric = 'hyrox' THEN hs.best_race_seconds END ASC NULLS LAST,
          lower(COALESCE(su.display_name, ''))
      )::int AS rank
    FROM scope_users su
    LEFT JOIN workout_stats wst ON wst.user_id = su.user_id
    LEFT JOIN set_stats ss ON ss.user_id = su.user_id
    LEFT JOIN hyrox_stats hs ON hs.user_id = su.user_id
    LEFT JOIN period_xp px ON px.user_id = su.user_id
  ),
  filtered AS (
    SELECT * FROM ranked
    WHERE p_metric <> 'hyrox' OR metric_value IS NOT NULL
  )
  SELECT json_build_object(
    'entries', COALESCE((
      SELECT json_agg(
        json_build_object(
          'rank', r.rank,
          'user_id', r.user_id,
          'display_name', r.display_name,
          'avatar_url', r.avatar_url,
          'total_xp', r.total_xp,
          'metric_value', r.metric_value,
          'total_reps', r.total_reps,
          'total_volume', r.total_volume,
          'total_distance', r.total_distance,
          'total_calories', r.total_calories,
          'total_workouts', r.total_workouts,
          'is_current_user', r.user_id = v_uid
        )
        ORDER BY r.rank
      )
      FROM (
        SELECT * FROM filtered
        ORDER BY rank
        LIMIT v_limit
      ) r
    ), '[]'::json),
    'current_user_outside_top', (
      SELECT json_build_object(
        'rank', r.rank,
        'user_id', r.user_id,
        'display_name', r.display_name,
        'avatar_url', r.avatar_url,
        'total_xp', r.total_xp,
        'metric_value', r.metric_value,
        'total_reps', r.total_reps,
        'total_volume', r.total_volume,
        'total_distance', r.total_distance,
        'total_calories', r.total_calories,
        'total_workouts', r.total_workouts,
        'is_current_user', TRUE
      )
      FROM filtered r
      WHERE r.user_id = v_uid
        AND r.rank > v_limit
      LIMIT 1
    ),
    'has_more', (
      SELECT COUNT(*)::int > v_limit FROM filtered
    )
  )
  INTO v_result;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_leaderboard(TEXT, TEXT, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_leaderboard(TEXT, TEXT, TEXT, INT) TO authenticated;
