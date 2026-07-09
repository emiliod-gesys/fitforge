-- Plan de suscripción del usuario (free | gymrat | gymrat_pro).
-- Por defecto todos los usuarios existentes quedan en free.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS subscription_tier text NOT NULL DEFAULT 'free'
  CHECK (subscription_tier IN ('free', 'gymrat', 'gymrat_pro'));

COMMENT ON COLUMN profiles.subscription_tier IS
  'Subscription plan: free, gymrat, or gymrat_pro';
