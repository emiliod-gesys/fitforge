-- Daily water intake logs (250 ml glasses, etc.)

CREATE TABLE IF NOT EXISTS public.water_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  amount_ml INT NOT NULL CHECK (amount_ml >= 1 AND amount_ml <= 5000),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS water_entries_user_logged_idx
  ON public.water_entries (user_id, logged_at DESC);

ALTER TABLE public.water_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own water entries"
  ON public.water_entries FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Trainers view student water entries"
  ON public.water_entries FOR SELECT
  USING (public.is_trainer_of(user_id));
