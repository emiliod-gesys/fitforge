-- Fecha de nacimiento como fuente de verdad; la edad se mantiene sincronizada.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS date_of_birth DATE;

-- Usuarios existentes: estimar cumpleaños como "hoy hace N años".
UPDATE public.profiles
SET date_of_birth = (CURRENT_DATE - make_interval(years => age))::date
WHERE date_of_birth IS NULL
  AND age IS NOT NULL
  AND age BETWEEN 1 AND 119;

CREATE OR REPLACE FUNCTION public.profiles_sync_age_from_dob()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.date_of_birth IS NOT NULL THEN
    NEW.age := GREATEST(
      0,
      date_part('year', age(CURRENT_DATE, NEW.date_of_birth))::integer
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_sync_age_from_dob ON public.profiles;
CREATE TRIGGER profiles_sync_age_from_dob
  BEFORE INSERT OR UPDATE OF date_of_birth ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.profiles_sync_age_from_dob();

-- Recalcular age desde DOB por si el backfill dejó valores desfasados.
UPDATE public.profiles
SET age = date_part('year', age(CURRENT_DATE, date_of_birth))::integer
WHERE date_of_birth IS NOT NULL;
