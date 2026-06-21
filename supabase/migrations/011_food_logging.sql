-- Registro diario de comidas y macros

CREATE TABLE IF NOT EXISTS public.food_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  name TEXT NOT NULL,
  brand TEXT,
  calories_kcal INT NOT NULL DEFAULT 0 CHECK (calories_kcal >= 0),
  protein_g DECIMAL(8, 2) NOT NULL DEFAULT 0 CHECK (protein_g >= 0),
  carbs_g DECIMAL(8, 2) NOT NULL DEFAULT 0 CHECK (carbs_g >= 0),
  fat_g DECIMAL(8, 2) NOT NULL DEFAULT 0 CHECK (fat_g >= 0),
  fiber_g DECIMAL(8, 2) DEFAULT 0 CHECK (fiber_g >= 0),
  serving_description TEXT,
  source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'quick', 'search', 'ai_photo', 'ai_text', 'barcode')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS food_entries_user_logged_idx
  ON public.food_entries (user_id, logged_at DESC);

ALTER TABLE public.food_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own food entries"
  ON public.food_entries FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
