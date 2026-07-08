-- Solicitud de alumno: el alumno debe aprobar antes de que el entrenador vea sus datos.
-- Añade estado pending/accepted al vínculo entrenador-alumno y un flujo de aprobación.

ALTER TABLE public.trainer_students
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'accepted'
    CHECK (status IN ('pending', 'accepted')),
  ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_trainer_students_student_pending
  ON public.trainer_students(student_id, created_at DESC)
  WHERE status = 'pending';

-- Privacidad: un entrenador solo puede ver los datos de un alumno con vínculo ACEPTADO.
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
      AND ts.status = 'accepted'
  );
$$;

-- El alumno puede aceptar (UPDATE) o rechazar / abandonar (DELETE) su propio vínculo.
DROP POLICY IF EXISTS "Students respond to trainer link" ON public.trainer_students;
CREATE POLICY "Students respond to trainer link"
  ON public.trainer_students FOR UPDATE
  USING (auth.uid() = student_id)
  WITH CHECK (auth.uid() = student_id);

DROP POLICY IF EXISTS "Students leave trainer" ON public.trainer_students;
CREATE POLICY "Students leave trainer"
  ON public.trainer_students FOR DELETE
  USING (auth.uid() = student_id);

-- Agregar alumno ahora crea una SOLICITUD pendiente + notificación al alumno.
CREATE OR REPLACE FUNCTION public.add_trainer_student(p_student_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trainer_id UUID := auth.uid();
  v_row_id UUID;
  v_status TEXT;
  v_actor_name TEXT;
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

  SELECT id, status INTO v_row_id, v_status
  FROM public.trainer_students
  WHERE trainer_id = v_trainer_id AND student_id = p_student_id;

  IF v_row_id IS NOT NULL THEN
    IF v_status = 'accepted' THEN
      RAISE EXCEPTION 'Student already added';
    END IF;
    RAISE EXCEPTION 'Request already pending';
  END IF;

  INSERT INTO public.trainer_students (trainer_id, student_id, status)
  VALUES (v_trainer_id, p_student_id, 'pending')
  RETURNING id INTO v_row_id;

  SELECT COALESCE(display_name, split_part(email, '@', 1), 'Un entrenador')
  INTO v_actor_name
  FROM public.profiles
  WHERE id = v_trainer_id;

  INSERT INTO public.social_notifications (user_id, actor_id, type, message, reference_id)
  VALUES (
    p_student_id,
    v_trainer_id,
    'trainer_request',
    v_actor_name || ' quiere agregarte como su alumno',
    v_row_id
  );

  RETURN v_row_id;
END;
$$;

-- El alumno responde a la solicitud: aceptar (activa el vínculo) o rechazar (lo elimina).
CREATE OR REPLACE FUNCTION public.respond_trainer_request(p_request_id UUID, p_accept BOOLEAN)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_request RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_request
  FROM public.trainer_students
  WHERE id = p_request_id;

  IF v_request.id IS NULL THEN
    RAISE EXCEPTION 'Request not found';
  END IF;

  IF v_request.student_id != v_user_id THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  IF v_request.status != 'pending' THEN
    RAISE EXCEPTION 'Request already resolved';
  END IF;

  IF p_accept THEN
    UPDATE public.trainer_students
    SET status = 'accepted', resolved_at = NOW()
    WHERE id = p_request_id;
  ELSE
    DELETE FROM public.trainer_students
    WHERE id = p_request_id;
  END IF;

  UPDATE public.social_notifications
  SET read_at = NOW()
  WHERE reference_id = p_request_id
    AND user_id = v_user_id
    AND read_at IS NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.respond_trainer_request(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.respond_trainer_request(UUID, BOOLEAN) TO authenticated;

NOTIFY pgrst, 'reload schema';
