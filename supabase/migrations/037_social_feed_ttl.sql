-- Las publicaciones del feed expiran a las 24 h para no saturar.

CREATE OR REPLACE FUNCTION public.cleanup_old_social_feed_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM public.social_notifications
  WHERE type IN ('workout_completed', 'milestone_unlocked', 'level_up', 'pr_unlocked')
    AND created_at < NOW() - INTERVAL '24 hours';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_old_social_feed_notifications() FROM PUBLIC;

-- Limpieza inicial de filas antiguas.
SELECT public.cleanup_old_social_feed_notifications();

-- Purga horaria en segundo plano (requiere pg_cron en el proyecto).
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

DO $cron$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'cron') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'cleanup_old_social_feed_notifications';

    PERFORM cron.schedule(
      'cleanup_old_social_feed_notifications',
      '15 * * * *',
      $job$SELECT public.cleanup_old_social_feed_notifications();$job$
    );
  END IF;
END;
$cron$;
