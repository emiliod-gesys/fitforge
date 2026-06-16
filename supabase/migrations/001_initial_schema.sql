-- FitForge initial schema
-- Run in Supabase SQL Editor or via CLI

-- Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  unit_system TEXT DEFAULT 'kg',
  body_weight DECIMAL,
  fitness_goal TEXT,
  experience_level TEXT DEFAULT 'intermedio',
  ai_provider TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Routines
CREATE TABLE IF NOT EXISTS public.routines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  target_muscles TEXT[] DEFAULT '{}',
  is_ai_generated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.routines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own routines"
  ON public.routines FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Routine exercises
CREATE TABLE IF NOT EXISTS public.routine_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_id UUID NOT NULL REFERENCES public.routines(id) ON DELETE CASCADE,
  exercise_id TEXT NOT NULL,
  exercise_name TEXT NOT NULL,
  order_index INT DEFAULT 0,
  target_sets INT DEFAULT 3,
  target_reps INT DEFAULT 10,
  target_weight DECIMAL,
  rest_seconds INT DEFAULT 90,
  image_url TEXT
);

ALTER TABLE public.routine_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own routine exercises"
  ON public.routine_exercises FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_id AND r.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_id AND r.user_id = auth.uid()
    )
  );

-- Workouts
CREATE TABLE IF NOT EXISTS public.workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  routine_id UUID REFERENCES public.routines(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  duration_minutes INT DEFAULT 0,
  total_volume DECIMAL DEFAULT 0,
  notes TEXT
);

ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own workouts"
  ON public.workouts FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Workout exercises
CREATE TABLE IF NOT EXISTS public.workout_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_id UUID NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
  exercise_id TEXT NOT NULL,
  exercise_name TEXT NOT NULL,
  image_url TEXT,
  order_index INT DEFAULT 0,
  notes TEXT
);

ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own workout exercises"
  ON public.workout_exercises FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.workouts w
      WHERE w.id = workout_id AND w.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workouts w
      WHERE w.id = workout_id AND w.user_id = auth.uid()
    )
  );

-- Workout sets
CREATE TABLE IF NOT EXISTS public.workout_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_exercise_id UUID NOT NULL REFERENCES public.workout_exercises(id) ON DELETE CASCADE,
  set_number INT NOT NULL,
  weight DECIMAL,
  reps INT DEFAULT 0,
  rir INT,
  completed BOOLEAN DEFAULT FALSE,
  rest_seconds INT
);

ALTER TABLE public.workout_sets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own workout sets"
  ON public.workout_sets FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.workout_exercises we
      JOIN public.workouts w ON w.id = we.workout_id
      WHERE we.id = workout_exercise_id AND w.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workout_exercises we
      JOIN public.workouts w ON w.id = we.workout_id
      WHERE we.id = workout_exercise_id AND w.user_id = auth.uid()
    )
  );

-- Personal records
CREATE TABLE IF NOT EXISTS public.personal_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id TEXT NOT NULL,
  exercise_name TEXT NOT NULL,
  weight DECIMAL NOT NULL,
  reps INT DEFAULT 1,
  one_rep_max DECIMAL NOT NULL,
  achieved_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, exercise_id)
);

ALTER TABLE public.personal_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own PRs"
  ON public.personal_records FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Body measurements
CREATE TABLE IF NOT EXISTS public.body_measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'weight',
  value DECIMAL NOT NULL,
  unit TEXT DEFAULT 'kg',
  measured_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.body_measurements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own measurements"
  ON public.body_measurements FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_workouts_user_started ON public.workouts(user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_routines_user ON public.routines(user_id);
CREATE INDEX IF NOT EXISTS idx_personal_records_user ON public.personal_records(user_id);
