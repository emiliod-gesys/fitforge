-- Corrige RLS de rutinas del entrenador: políticas explícitas por operación

DROP POLICY IF EXISTS "Trainers manage student routines" ON public.routines;
DROP POLICY IF EXISTS "Trainers select student routines" ON public.routines;
DROP POLICY IF EXISTS "Trainers insert student routines" ON public.routines;
DROP POLICY IF EXISTS "Trainers update student routines" ON public.routines;
DROP POLICY IF EXISTS "Trainers delete student routines" ON public.routines;

CREATE POLICY "Trainers select student routines"
  ON public.routines FOR SELECT
  USING (public.is_trainer_of(user_id));

CREATE POLICY "Trainers insert student routines"
  ON public.routines FOR INSERT
  WITH CHECK (public.is_trainer() AND public.is_trainer_of(user_id));

CREATE POLICY "Trainers update student routines"
  ON public.routines FOR UPDATE
  USING (public.is_trainer_of(user_id))
  WITH CHECK (public.is_trainer_of(user_id));

CREATE POLICY "Trainers delete student routines"
  ON public.routines FOR DELETE
  USING (public.is_trainer_of(user_id));

DROP POLICY IF EXISTS "Trainers manage student routine exercises" ON public.routine_exercises;
DROP POLICY IF EXISTS "Trainers select student routine exercises" ON public.routine_exercises;
DROP POLICY IF EXISTS "Trainers insert student routine exercises" ON public.routine_exercises;
DROP POLICY IF EXISTS "Trainers update student routine exercises" ON public.routine_exercises;
DROP POLICY IF EXISTS "Trainers delete student routine exercises" ON public.routine_exercises;

CREATE POLICY "Trainers select student routine exercises"
  ON public.routine_exercises FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_exercises.routine_id
        AND public.is_trainer_of(r.user_id)
    )
  );

CREATE POLICY "Trainers insert student routine exercises"
  ON public.routine_exercises FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_exercises.routine_id
        AND public.is_trainer_of(r.user_id)
    )
  );

CREATE POLICY "Trainers update student routine exercises"
  ON public.routine_exercises FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_exercises.routine_id
        AND public.is_trainer_of(r.user_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_exercises.routine_id
        AND public.is_trainer_of(r.user_id)
    )
  );

CREATE POLICY "Trainers delete student routine exercises"
  ON public.routine_exercises FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_exercises.routine_id
        AND public.is_trainer_of(r.user_id)
    )
  );
