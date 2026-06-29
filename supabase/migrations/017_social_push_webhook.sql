-- Dispara push FCM al insertar notificaciones sociales (pg_net + vault).
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.notify_social_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  webhook_secret text;
  request_id bigint;
BEGIN
  SELECT decrypted_secret INTO webhook_secret
  FROM vault.decrypted_secrets
  WHERE name = 'social_push_webhook_secret'
  LIMIT 1;

  IF webhook_secret IS NULL OR length(webhook_secret) = 0 THEN
    RETURN NEW;
  END IF;

  SELECT net.http_post(
    url := 'https://cpxpqklbmiwguvuwifpd.supabase.co/functions/v1/send-social-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || webhook_secret
    ),
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'social_notifications',
      'record', jsonb_build_object(
        'user_id', NEW.user_id,
        'actor_id', NEW.actor_id,
        'message', NEW.message,
        'type', NEW.type
      )
    )
  ) INTO request_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS social_notifications_push_webhook ON public.social_notifications;
CREATE TRIGGER social_notifications_push_webhook
  AFTER INSERT ON public.social_notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_social_push();
