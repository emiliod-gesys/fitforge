-- Browse extended catalog without a text query (paginated).

CREATE OR REPLACE FUNCTION public.browse_catalog_exercises(
  p_limit INT DEFAULT 40,
  p_offset INT DEFAULT 0
)
RETURNS SETOF public.catalog_exercises
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT *
  FROM public.catalog_exercises
  ORDER BY name_en
  LIMIT greatest(1, least(p_limit, 80))
  OFFSET greatest(0, p_offset);
$$;

GRANT EXECUTE ON FUNCTION public.browse_catalog_exercises(INT, INT) TO anon, authenticated;
