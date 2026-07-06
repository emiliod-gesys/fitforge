-- Entrenador: lectura de comida, actividad manual y métricas corporales del alumno

CREATE POLICY "Trainers view student food entries"
  ON public.food_entries FOR SELECT
  USING (public.is_trainer_of(user_id));

CREATE POLICY "Trainers view student manual activities"
  ON public.manual_activity_entries FOR SELECT
  USING (public.is_trainer_of(user_id));

CREATE POLICY "Trainers view student body measurements"
  ON public.body_measurements FOR SELECT
  USING (public.is_trainer_of(user_id));
