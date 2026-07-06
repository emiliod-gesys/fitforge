-- Rutinas favoritas (máx. 5 por usuario) visibles en el perfil para amigos

ALTER TABLE public.routines
  ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS favorite_order INT;

CREATE INDEX IF NOT EXISTS idx_routines_user_favorites
  ON public.routines(user_id, favorite_order)
  WHERE is_favorite = TRUE;

DROP POLICY IF EXISTS "Friends view favorite routines" ON public.routines;
CREATE POLICY "Friends view favorite routines"
  ON public.routines FOR SELECT
  USING (
    is_favorite = TRUE
    AND public.is_friend_with(user_id)
  );

DROP POLICY IF EXISTS "Friends view favorite routine exercises" ON public.routine_exercises;
CREATE POLICY "Friends view favorite routine exercises"
  ON public.routine_exercises FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_exercises.routine_id
        AND r.is_favorite = TRUE
        AND public.is_friend_with(r.user_id)
    )
  );

CREATE OR REPLACE FUNCTION public.set_routine_favorite(p_routine_id UUID, p_favorite BOOLEAN)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_count INT;
  v_next_order INT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT user_id INTO v_user_id
  FROM public.routines
  WHERE id = p_routine_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Routine not found';
  END IF;

  IF v_user_id != auth.uid() THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  IF p_favorite THEN
    SELECT COUNT(*) INTO v_count
    FROM public.routines
    WHERE user_id = auth.uid()
      AND is_favorite = TRUE
      AND id != p_routine_id;

    IF v_count >= 5 THEN
      RAISE EXCEPTION 'Maximum of 5 favorite routines allowed';
    END IF;

    SELECT COALESCE(MAX(favorite_order), 0) + 1 INTO v_next_order
    FROM public.routines
    WHERE user_id = auth.uid() AND is_favorite = TRUE;

    UPDATE public.routines
    SET
      is_favorite = TRUE,
      favorite_order = v_next_order,
      updated_at = NOW()
    WHERE id = p_routine_id;
  ELSE
    UPDATE public.routines
    SET
      is_favorite = FALSE,
      favorite_order = NULL,
      updated_at = NOW()
    WHERE id = p_routine_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.set_routine_favorite(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_routine_favorite(UUID, BOOLEAN) TO authenticated;

NOTIFY pgrst, 'reload schema';
