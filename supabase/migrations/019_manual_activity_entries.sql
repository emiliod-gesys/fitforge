-- Actividades manuales (calorías quemadas fuera de entrenos registrados en FitForge)

CREATE TABLE IF NOT EXISTS public.manual_activity_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  name TEXT NOT NULL,
  calories_kcal INT NOT NULL CHECK (calories_kcal >= 1 AND calories_kcal <= 9999),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS manual_activity_entries_user_logged_idx
  ON public.manual_activity_entries (user_id, logged_at DESC);

ALTER TABLE public.manual_activity_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own manual activity entries"
  ON public.manual_activity_entries FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
