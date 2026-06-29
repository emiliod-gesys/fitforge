-- Secretos de push en Vault; la Edge Function los lee con service_role.
CREATE OR REPLACE FUNCTION public.get_push_notification_secrets()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = vault, public
AS $$
DECLARE
  firebase_sa text;
  webhook_secret text;
BEGIN
  SELECT decrypted_secret INTO firebase_sa
  FROM vault.decrypted_secrets
  WHERE name = 'firebase_service_account'
  LIMIT 1;

  SELECT decrypted_secret INTO webhook_secret
  FROM vault.decrypted_secrets
  WHERE name = 'social_push_webhook_secret'
  LIMIT 1;

  RETURN jsonb_build_object(
    'firebase_service_account', firebase_sa,
    'webhook_secret', webhook_secret
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_push_notification_secrets() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_push_notification_secrets() TO service_role;
