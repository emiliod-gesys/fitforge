-- Origen de la suscripción para no mezclar pagos de tienda con cortesías.
-- iap = Play Billing / StoreKit; courtesy = asignado a mano (comps, testers).

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS subscription_source text
    CHECK (subscription_source IS NULL OR subscription_source IN ('iap', 'courtesy')),
  ADD COLUMN IF NOT EXISTS subscription_product_id text,
  ADD COLUMN IF NOT EXISTS subscription_expires_at timestamptz;

COMMENT ON COLUMN profiles.subscription_source IS
  'iap = store purchase; courtesy = manual comp. Null on free.';
COMMENT ON COLUMN profiles.subscription_product_id IS
  'Last store product id when subscription_source = iap.';
COMMENT ON COLUMN profiles.subscription_expires_at IS
  'Store expiry when known; courtesy rows stay null.';

UPDATE profiles
SET subscription_source = 'courtesy'
WHERE subscription_tier IN ('gymrat', 'gymrat_pro')
  AND subscription_source IS NULL;
