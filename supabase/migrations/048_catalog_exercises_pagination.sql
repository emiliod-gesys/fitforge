-- Paginated search for extended exercise catalog.

CREATE OR REPLACE FUNCTION public.search_catalog_exercises(
  p_query TEXT,
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
  WHERE char_length(trim(p_query)) >= 2
    AND search_text ILIKE '%' || lower(trim(p_query)) || '%'
  ORDER BY name_en
  LIMIT greatest(1, least(p_limit, 80))
  OFFSET greatest(0, p_offset);
$$;

GRANT EXECUTE ON FUNCTION public.search_catalog_exercises(TEXT, INT, INT) TO anon, authenticated;
