-- Catálogo regional de alimentos (México → Panamá).
-- Macros normalizados por 100 g/ml; porción cultural en serving_amount + serving_label.

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS public.catalog_foods (
  id TEXT PRIMARY KEY,
  name_es TEXT NOT NULL,
  name_en TEXT NOT NULL DEFAULT '',
  brand TEXT,
  barcode TEXT,
  region TEXT NOT NULL DEFAULT 'latam',
  category TEXT NOT NULL DEFAULT 'basico',
  calories_kcal NUMERIC NOT NULL DEFAULT 0 CHECK (calories_kcal >= 0),
  protein_g NUMERIC NOT NULL DEFAULT 0 CHECK (protein_g >= 0),
  carbs_g NUMERIC NOT NULL DEFAULT 0 CHECK (carbs_g >= 0),
  fat_g NUMERIC NOT NULL DEFAULT 0 CHECK (fat_g >= 0),
  fiber_g NUMERIC NOT NULL DEFAULT 0 CHECK (fiber_g >= 0),
  amount_unit TEXT NOT NULL DEFAULT 'g' CHECK (amount_unit IN ('g', 'ml')),
  serving_amount NUMERIC NOT NULL DEFAULT 100 CHECK (serving_amount > 0),
  serving_label_es TEXT NOT NULL DEFAULT '',
  serving_label_en TEXT NOT NULL DEFAULT '',
  search_text TEXT NOT NULL DEFAULT '',
  source TEXT NOT NULL DEFAULT 'seed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS catalog_foods_search_text_idx
  ON public.catalog_foods USING gin (search_text gin_trgm_ops);

CREATE INDEX IF NOT EXISTS catalog_foods_barcode_idx
  ON public.catalog_foods (barcode) WHERE barcode IS NOT NULL;

ALTER TABLE public.catalog_foods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read catalog foods" ON public.catalog_foods;

CREATE POLICY "Anyone can read catalog foods"
  ON public.catalog_foods
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Normaliza texto para búsqueda sin acentos.
CREATE OR REPLACE FUNCTION public.normalize_food_search(p_text TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT translate(lower(coalesce(p_text, '')), 'áéíóúüñ', 'aeiouun');
$$;

CREATE OR REPLACE FUNCTION public.search_catalog_foods(
  p_query TEXT,
  p_limit INT DEFAULT 30
)
RETURNS SETOF public.catalog_foods
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT *
  FROM public.catalog_foods
  WHERE char_length(trim(p_query)) >= 2
    AND search_text LIKE '%' || public.normalize_food_search(trim(p_query)) || '%'
  ORDER BY
    -- prioriza matches al inicio del nombre
    (search_text LIKE public.normalize_food_search(trim(p_query)) || '%') DESC,
    similarity(search_text, public.normalize_food_search(trim(p_query))) DESC,
    name_es
  LIMIT greatest(1, least(p_limit, 60));
$$;

GRANT EXECUTE ON FUNCTION public.normalize_food_search(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.search_catalog_foods(TEXT, INT) TO anon, authenticated;
