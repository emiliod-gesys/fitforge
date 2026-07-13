-- Validación anti-fraude para entrenamientos Hyrox.
-- Marca sesiones con tiempos imposibles o datos manipulados; excluye del leaderboard.

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS hyrox_validation_status TEXT;

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS hyrox_validation_reasons JSONB NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE public.workouts
  DROP CONSTRAINT IF EXISTS workouts_hyrox_validation_status_check;

ALTER TABLE public.workouts
  ADD CONSTRAINT workouts_hyrox_validation_status_check
  CHECK (
    hyrox_validation_status IS NULL
    OR hyrox_validation_status IN ('valid', 'suspicious', 'rejected')
  );

COMMENT ON COLUMN public.workouts.hyrox_validation_status IS
  'Resultado de validación Hyrox: valid, suspicious o rejected. NULL si no aplica.';

CREATE OR REPLACE FUNCTION public.hyrox_min_station_seconds(
  p_exercise_id TEXT,
  p_distance_meters DOUBLE PRECISION,
  p_reps INT
)
RETURNS DOUBLE PRECISION
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_exercise_id
    WHEN 'ff_cardio_outdoor_running' THEN 150.0 * COALESCE(NULLIF(p_distance_meters, 0), 1000) / 1000.0
    WHEN 'ff_cardio_ski_erg' THEN 150.0 * COALESCE(NULLIF(p_distance_meters, 0), 1000) / 1000.0
    WHEN 'ff_cardio_rowing_machine' THEN 150.0 * COALESCE(NULLIF(p_distance_meters, 0), 1000) / 1000.0
    WHEN 'ff_cf_sled_push' THEN 30.0 * COALESCE(NULLIF(p_distance_meters, 0), 50) / 50.0
    WHEN 'ff_cf_sled_pull' THEN 30.0 * COALESCE(NULLIF(p_distance_meters, 0), 50) / 50.0
    WHEN 'ff_cf_burpee_broad_jump' THEN 60.0 * COALESCE(NULLIF(p_distance_meters, 0), 80) / 80.0
    WHEN 'ff_cf_farmers_walk' THEN 45.0 * COALESCE(NULLIF(p_distance_meters, 0), 200) / 200.0
    WHEN 'ff_cf_sandbag_lunge' THEN 60.0 * COALESCE(NULLIF(p_distance_meters, 0), 100) / 100.0
    WHEN 'ff_cf_wall_ball' THEN 90.0 * COALESCE(NULLIF(p_reps, 0), 100)::double precision / 100.0
    ELSE 30.0
  END;
$$;

CREATE OR REPLACE FUNCTION public.hyrox_min_total_seconds(
  p_level TEXT,
  p_gender TEXT
)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_level
    WHEN 'prep' THEN 25 * 60
    WHEN 'build' THEN 35 * 60
    ELSE CASE WHEN p_gender = 'female' THEN 42 * 60 ELSE 45 * 60 END
  END;
$$;

CREATE OR REPLACE FUNCTION public.validate_hyrox_workout(p_workout_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_workout RECORD;
  v_gender TEXT;
  v_completed_sets INT := 0;
  v_total_seconds DOUBLE PRECISION := 0;
  v_split_sum DOUBLE PRECISION := 0;
  v_reasons TEXT[] := ARRAY[]::TEXT[];
  v_status TEXT := 'valid';
  v_set RECORD;
  v_min_station DOUBLE PRECISION;
BEGIN
  SELECT
    w.id,
    w.started_at,
    w.completed_at,
    r.is_hyrox_system,
    r.hyrox_level
  INTO v_workout
  FROM public.workouts w
  LEFT JOIN public.routines r ON r.id = w.routine_id
  WHERE w.id = p_workout_id;

  IF v_workout.id IS NULL OR NOT COALESCE(v_workout.is_hyrox_system, FALSE) THEN
    RETURN jsonb_build_object('status', NULL, 'reasons', '[]'::jsonb);
  END IF;

  IF v_workout.completed_at IS NULL OR v_workout.started_at IS NULL THEN
    RETURN jsonb_build_object('status', NULL, 'reasons', '[]'::jsonb);
  END IF;

  SELECT p.gender INTO v_gender
  FROM public.profiles p
  JOIN public.workouts w ON w.user_id = p.id
  WHERE w.id = p_workout_id;

  SELECT COUNT(*)::INT INTO v_completed_sets
  FROM public.workout_exercises we
  JOIN public.workout_sets ws ON ws.workout_exercise_id = we.id
  WHERE we.workout_id = p_workout_id
    AND ws.completed = TRUE;

  IF v_completed_sets < 16 THEN
    v_reasons := array_append(v_reasons, 'incomplete_stations');
    v_status := 'rejected';
  END IF;

  v_total_seconds := GREATEST(
    0,
    EXTRACT(EPOCH FROM (v_workout.completed_at - v_workout.started_at))
  );

  IF v_total_seconds < public.hyrox_min_total_seconds(v_workout.hyrox_level, v_gender) THEN
    v_reasons := array_append(v_reasons, 'total_time_too_fast');
    v_status := 'rejected';
  END IF;

  SELECT COALESCE(SUM(ws.duration_seconds), 0)::double precision INTO v_split_sum
  FROM public.workout_exercises we
  JOIN public.workout_sets ws ON ws.workout_exercise_id = we.id
  WHERE we.workout_id = p_workout_id
    AND ws.completed = TRUE;

  IF v_split_sum > v_total_seconds + 120 THEN
    v_reasons := array_append(v_reasons, 'split_sum_exceeds_total');
    v_status := 'rejected';
  ELSIF v_completed_sets >= 16 AND v_split_sum < v_total_seconds * 0.35 THEN
    v_reasons := array_append(v_reasons, 'split_sum_too_low');
    IF v_status = 'valid' THEN
      v_status := 'suspicious';
    END IF;
  END IF;

  FOR v_set IN
    SELECT
      we.exercise_id,
      we.order_index,
      ws.duration_seconds,
      ws.distance_meters,
      ws.weight,
      ws.reps,
      re.target_distance_meters,
      re.target_weight,
      re.target_reps
    FROM public.workout_exercises we
    JOIN public.workout_sets ws ON ws.workout_exercise_id = we.id
    LEFT JOIN public.routine_exercises re
      ON re.routine_id = (SELECT routine_id FROM public.workouts WHERE id = p_workout_id)
     AND re.order_index = we.order_index
    WHERE we.workout_id = p_workout_id
      AND ws.completed = TRUE
  LOOP
    IF v_set.duration_seconds IS NULL OR v_set.duration_seconds <= 0 THEN
      IF v_status = 'valid' THEN
        v_reasons := array_append(v_reasons, 'missing_station_time');
        v_status := 'suspicious';
      END IF;
      CONTINUE;
    END IF;

    v_min_station := public.hyrox_min_station_seconds(
      v_set.exercise_id,
      v_set.distance_meters,
      v_set.reps
    );

    IF v_set.duration_seconds < v_min_station THEN
      v_reasons := array_append(v_reasons, 'station_time_too_fast:' || v_set.exercise_id);
      v_status := 'rejected';
    END IF;

    IF v_set.target_distance_meters IS NOT NULL
       AND v_set.distance_meters IS NOT NULL
       AND ABS(v_set.distance_meters - v_set.target_distance_meters) > 1.0 THEN
      v_reasons := array_append(v_reasons, 'target_distance_mismatch:' || v_set.exercise_id);
      v_status := 'rejected';
    END IF;

    IF v_set.target_weight IS NOT NULL
       AND v_set.weight IS NOT NULL
       AND ABS(v_set.weight - v_set.target_weight) > 0.75 THEN
      v_reasons := array_append(v_reasons, 'target_weight_mismatch:' || v_set.exercise_id);
      v_status := 'rejected';
    END IF;

    IF v_set.target_reps IS NOT NULL
       AND v_set.target_reps > 0
       AND v_set.reps IS DISTINCT FROM v_set.target_reps THEN
      v_reasons := array_append(v_reasons, 'target_reps_mismatch:' || v_set.exercise_id);
      v_status := 'rejected';
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'status', v_status,
    'reasons', to_jsonb(v_reasons)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_validate_hyrox_workout_before_complete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  IF NEW.completed_at IS NOT NULL
     AND (OLD.completed_at IS NULL OR OLD.completed_at IS DISTINCT FROM NEW.completed_at) THEN
    v_result := public.validate_hyrox_workout(NEW.id);
    IF v_result->>'status' IS NOT NULL THEN
      NEW.hyrox_validation_status := v_result->>'status';
      NEW.hyrox_validation_reasons := COALESCE(v_result->'reasons', '[]'::jsonb);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS validate_hyrox_workout_before_complete ON public.workouts;
CREATE TRIGGER validate_hyrox_workout_before_complete
  BEFORE UPDATE ON public.workouts
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_validate_hyrox_workout_before_complete();

-- Leaderboard Hyrox: solo tiempos validados.
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
      AND COALESCE(w.hyrox_validation_status, 'valid') = 'valid'
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

REVOKE ALL ON FUNCTION public.validate_hyrox_workout(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.validate_hyrox_workout(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.get_leaderboard(TEXT, TEXT, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_leaderboard(TEXT, TEXT, TEXT, INT) TO authenticated;
