-- Extended exercise catalog (exercises-dataset) — lazy-loaded from Supabase.
-- Bundled FitForge exercises (ff_*) stay in the app; cloud rows use ext_* IDs.

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS public.catalog_exercises (
  id TEXT PRIMARY KEY,
  dataset_id TEXT NOT NULL UNIQUE,
  media_id TEXT,
  name_en TEXT NOT NULL,
  name_es TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL,
  body_part TEXT NOT NULL,
  equipment TEXT NOT NULL,
  target_muscle TEXT NOT NULL,
  muscle_group TEXT,
  secondary_muscles JSONB NOT NULL DEFAULT '[]'::jsonb,
  muscles JSONB NOT NULL DEFAULT '[]'::jsonb,
  description_en TEXT NOT NULL DEFAULT '',
  description_es TEXT NOT NULL DEFAULT '',
  instruction_steps_en JSONB NOT NULL DEFAULT '[]'::jsonb,
  instruction_steps_es JSONB NOT NULL DEFAULT '[]'::jsonb,
  logging_type TEXT NOT NULL DEFAULT 'strength',
  load_mode TEXT NOT NULL DEFAULT 'single_load',
  per_arm_weight BOOLEAN NOT NULL DEFAULT false,
  unilateral BOOLEAN NOT NULL DEFAULT false,
  weight_optional BOOLEAN NOT NULL DEFAULT false,
  image_url TEXT,
  gif_url TEXT,
  attribution TEXT NOT NULL DEFAULT '© Gym visual — https://gymvisual.com/',
  search_text TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS catalog_exercises_search_text_idx
  ON public.catalog_exercises USING gin (search_text gin_trgm_ops);

CREATE INDEX IF NOT EXISTS catalog_exercises_name_en_idx
  ON public.catalog_exercises (name_en);

ALTER TABLE public.catalog_exercises ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read catalog exercises" ON public.catalog_exercises;

CREATE POLICY "Anyone can read catalog exercises"
  ON public.catalog_exercises
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE OR REPLACE FUNCTION public.search_catalog_exercises(
  p_query TEXT,
  p_limit INT DEFAULT 40
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
  LIMIT greatest(1, least(p_limit, 80));
$$;

CREATE OR REPLACE FUNCTION public.get_catalog_exercise(p_id TEXT)
RETURNS public.catalog_exercises
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT *
  FROM public.catalog_exercises
  WHERE id = p_id
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.search_catalog_exercises(TEXT, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_catalog_exercise(TEXT) TO anon, authenticated;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'exercise-media',
  'exercise-media',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Public read exercise media objects" ON storage.objects;

CREATE POLICY "Public read exercise media objects"
  ON storage.objects
  FOR SELECT
  TO anon, authenticated
  USING (bucket_id = 'exercise-media');
