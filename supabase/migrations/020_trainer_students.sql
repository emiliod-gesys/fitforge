-- Personal trainers: rol en perfil, relación entrenador-alumno y acceso a entrenos

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS user_type TEXT NOT NULL DEFAULT 'athlete'
  CHECK (user_type IN ('athlete', 'trainer'));

CREATE TABLE IF NOT EXISTS public.trainer_students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (trainer_id, student_id),
  CHECK (trainer_id <> student_id)
);

CREATE INDEX IF NOT EXISTS idx_trainer_students_trainer ON public.trainer_students(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_students_student ON public.trainer_students(student_id);

ALTER TABLE public.trainer_students ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trainers manage own students"
  ON public.trainer_students FOR ALL
  USING (auth.uid() = trainer_id)
  WITH CHECK (auth.uid() = trainer_id);

CREATE POLICY "Students view own trainer link"
  ON public.trainer_students FOR SELECT
  USING (auth.uid() = student_id);

CREATE OR REPLACE FUNCTION public.is_trainer()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.user_type = 'trainer'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_trainer_of(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.trainer_students ts
    WHERE ts.trainer_id = auth.uid()
      AND ts.student_id = target_user_id
  );
$$;

REVOKE ALL ON FUNCTION public.is_trainer() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_trainer() TO authenticated;
REVOKE ALL ON FUNCTION public.is_trainer_of(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_trainer_of(UUID) TO authenticated;

-- Entrenador puede leer entrenos completados de sus alumnos
DROP POLICY IF EXISTS "Trainers view student workouts" ON public.workouts;
CREATE POLICY "Trainers view student workouts"
  ON public.workouts FOR SELECT
  USING (auth.uid() = user_id OR public.is_trainer_of(user_id));

DROP POLICY IF EXISTS "Trainers view student workout exercises" ON public.workout_exercises;
CREATE POLICY "Trainers view student workout exercises"
  ON public.workout_exercises FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.workouts w
      WHERE w.id = workout_exercises.workout_id
        AND (w.user_id = auth.uid() OR public.is_trainer_of(w.user_id))
    )
  );

DROP POLICY IF EXISTS "Trainers view student workout sets" ON public.workout_sets;
CREATE POLICY "Trainers view student workout sets"
  ON public.workout_sets FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.workout_exercises we
      JOIN public.workouts w ON w.id = we.workout_id
      WHERE we.id = workout_sets.workout_exercise_id
        AND (w.user_id = auth.uid() OR public.is_trainer_of(w.user_id))
    )
  );

-- Perfiles de alumnos visibles para su entrenador
DROP POLICY IF EXISTS "Users view own or friends profiles" ON public.profiles;
CREATE POLICY "Users view own or friends profiles"
  ON public.profiles FOR SELECT
  USING (
    auth.uid() = id
    OR public.has_friendship_with(id)
    OR public.is_trainer_of(id)
  );

-- Agregar alumno: debe ser entrenador, amigo aceptado, alumno no entrenador
CREATE OR REPLACE FUNCTION public.add_trainer_student(p_student_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trainer_id UUID := auth.uid();
  v_row_id UUID;
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_trainer() THEN
    RAISE EXCEPTION 'Only personal trainers can add students';
  END IF;

  IF p_student_id = v_trainer_id THEN
    RAISE EXCEPTION 'Cannot add yourself as a student';
  END IF;

  IF NOT public.is_friend_with(p_student_id) THEN
    RAISE EXCEPTION 'Student must be an accepted friend first';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_student_id AND p.user_type = 'trainer'
  ) THEN
    RAISE EXCEPTION 'Cannot add another trainer as a student';
  END IF;

  INSERT INTO public.trainer_students (trainer_id, student_id)
  VALUES (v_trainer_id, p_student_id)
  ON CONFLICT (trainer_id, student_id) DO NOTHING
  RETURNING id INTO v_row_id;

  IF v_row_id IS NULL THEN
    SELECT ts.id INTO v_row_id
    FROM public.trainer_students ts
    WHERE ts.trainer_id = v_trainer_id AND ts.student_id = p_student_id;
  END IF;

  RETURN v_row_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_trainer_student(p_student_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM public.trainer_students
  WHERE trainer_id = auth.uid() AND student_id = p_student_id;
END;
$$;

REVOKE ALL ON FUNCTION public.add_trainer_student(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.add_trainer_student(UUID) TO authenticated;
REVOKE ALL ON FUNCTION public.remove_trainer_student(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.remove_trainer_student(UUID) TO authenticated;
