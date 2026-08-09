-- Meta diaria de agua personalizada (ml). NULL = usar sugerencia de la app.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS water_goal_ml integer
  CHECK (water_goal_ml IS NULL OR (water_goal_ml >= 500 AND water_goal_ml <= 5000));

COMMENT ON COLUMN public.profiles.water_goal_ml IS
  'Daily water goal override in ml. NULL = use FitForge suggested goal from metrics.';
