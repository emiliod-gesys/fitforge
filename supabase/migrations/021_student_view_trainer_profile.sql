-- Alumno puede ver el perfil de su entrenador personal

CREATE OR REPLACE FUNCTION public.is_my_trainer(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.trainer_students ts
    WHERE ts.trainer_id = target_user_id
      AND ts.student_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.is_my_trainer(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_my_trainer(UUID) TO authenticated;

DROP POLICY IF EXISTS "Users view own or friends profiles" ON public.profiles;
CREATE POLICY "Users view own or friends profiles"
  ON public.profiles FOR SELECT
  USING (
    auth.uid() = id
    OR public.has_friendship_with(id)
    OR public.is_trainer_of(id)
    OR public.is_my_trainer(id)
  );
