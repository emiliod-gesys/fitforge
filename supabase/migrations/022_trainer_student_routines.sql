-- Entrenador: ver, crear, editar y eliminar rutinas de sus alumnos

DROP POLICY IF EXISTS "Trainers manage student routines" ON public.routines;
CREATE POLICY "Trainers manage student routines"
  ON public.routines FOR ALL
  USING (public.is_trainer_of(user_id))
  WITH CHECK (public.is_trainer_of(user_id));

DROP POLICY IF EXISTS "Trainers manage student routine exercises" ON public.routine_exercises;
CREATE POLICY "Trainers manage student routine exercises"
  ON public.routine_exercises FOR ALL
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
