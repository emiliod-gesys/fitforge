-- Token search for catalog exercises: match every word, any order, ES/EN synonyms.
-- Ignore instruction text so generic words do not crowd out name matches.

CREATE OR REPLACE FUNCTION public.normalize_exercise_search(p_text TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT trim(regexp_replace(
    translate(lower(coalesce(p_text, '')), 'áéíóúüñàèìòù', 'aeiouunaeiou'),
    '[^a-z0-9]+', ' ', 'g'
  ));
$$;

CREATE OR REPLACE FUNCTION public.exercise_search_token_variants(p_token TEXT)
RETURNS TEXT[]
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_token
    WHEN 'banca' THEN ARRAY['banca', 'banco', 'bench']
    WHEN 'banco' THEN ARRAY['banco', 'banca', 'bench']
    WHEN 'bench' THEN ARRAY['bench', 'banca', 'banco']
    WHEN 'mancuerna' THEN ARRAY['mancuerna', 'dumbbell']
    WHEN 'mancuernas' THEN ARRAY['mancuernas', 'dumbbell', 'dumbbells']
    WHEN 'dumbbell' THEN ARRAY['dumbbell', 'mancuerna', 'mancuernas']
    WHEN 'dumbbells' THEN ARRAY['dumbbells', 'mancuernas', 'mancuerna']
    WHEN 'barra' THEN ARRAY['barra', 'barbell']
    WHEN 'barbell' THEN ARRAY['barbell', 'barra']
    WHEN 'polea' THEN ARRAY['polea', 'cable']
    WHEN 'cable' THEN ARRAY['cable', 'polea']
    WHEN 'sentadilla' THEN ARRAY['sentadilla', 'squat']
    WHEN 'squat' THEN ARRAY['squat', 'sentadilla']
    WHEN 'zancada' THEN ARRAY['zancada', 'lunge']
    WHEN 'lunge' THEN ARRAY['lunge', 'zancada']
    WHEN 'dominada' THEN ARRAY['dominada', 'pullup', 'pull']
    WHEN 'dominadas' THEN ARRAY['dominadas', 'pullup', 'pull']
    WHEN 'flexion' THEN ARRAY['flexion', 'pushup', 'push']
    WHEN 'flexiones' THEN ARRAY['flexiones', 'pushup', 'push']
    WHEN 'remo' THEN ARRAY['remo', 'row']
    WHEN 'row' THEN ARRAY['row', 'remo']
    WHEN 'apertura' THEN ARRAY['apertura', 'fly']
    WHEN 'aperturas' THEN ARRAY['aperturas', 'fly']
    WHEN 'fly' THEN ARRAY['fly', 'apertura', 'aperturas']
    WHEN 'jalon' THEN ARRAY['jalon', 'pulldown']
    WHEN 'pulldown' THEN ARRAY['pulldown', 'jalon']
    WHEN 'inclinado' THEN ARRAY['inclinado', 'incline']
    WHEN 'incline' THEN ARRAY['incline', 'inclinado']
    WHEN 'declinado' THEN ARRAY['declinado', 'decline']
    WHEN 'decline' THEN ARRAY['decline', 'declinado']
    WHEN 'rumano' THEN ARRAY['rumano', 'romanian']
    WHEN 'romanian' THEN ARRAY['romanian', 'rumano']
    WHEN 'martillo' THEN ARRAY['martillo', 'hammer']
    WHEN 'hammer' THEN ARRAY['hammer', 'martillo']
    WHEN 'muerto' THEN ARRAY['muerto', 'deadlift']
    WHEN 'deadlift' THEN ARRAY['deadlift', 'muerto']
    WHEN 'pecho' THEN ARRAY['pecho', 'chest']
    WHEN 'chest' THEN ARRAY['chest', 'pecho']
    WHEN 'hombro' THEN ARRAY['hombro', 'shoulder']
    WHEN 'hombros' THEN ARRAY['hombros', 'shoulders']
    WHEN 'shoulder' THEN ARRAY['shoulder', 'hombro']
    WHEN 'shoulders' THEN ARRAY['shoulders', 'hombros']
    WHEN 'espalda' THEN ARRAY['espalda', 'back']
    WHEN 'back' THEN ARRAY['back', 'espalda']
    ELSE ARRAY[p_token]
  END;
$$;

CREATE OR REPLACE FUNCTION public.rewrite_exercise_search_query(p_text TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT replace(replace(replace(replace(replace(replace(replace(replace(
    public.normalize_exercise_search(p_text),
    'peso muerto rumano', 'romanian deadlift'),
    'press de banca', 'bench press'),
    'press banca', 'bench press'),
    'peso muerto', 'deadlift'),
    'curl martillo', 'hammer curl'),
    'curl femoral', 'leg curl'),
    'press militar', 'overhead press'),
    'jalon al pecho', 'lat pulldown');
$$;

CREATE OR REPLACE FUNCTION public.catalog_exercise_search_haystack(ce public.catalog_exercises)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT public.normalize_exercise_search(concat_ws(' ',
    ce.name_en,
    ce.name_es,
    ce.category,
    ce.body_part,
    ce.equipment,
    ce.target_muscle,
    ce.muscle_group,
    ce.muscles::text,
    ce.secondary_muscles::text
  ));
$$;

CREATE OR REPLACE FUNCTION public.search_catalog_exercises(
  p_query TEXT,
  p_limit INT DEFAULT 40,
  p_offset INT DEFAULT 0
)
RETURNS SETOF public.catalog_exercises
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  rewritten TEXT;
  tokens TEXT[];
BEGIN
  IF char_length(trim(coalesce(p_query, ''))) < 2 THEN
    RETURN;
  END IF;

  rewritten := public.rewrite_exercise_search_query(p_query);
  tokens := ARRAY(
    SELECT t
    FROM unnest(regexp_split_to_array(rewritten, '\s+')) AS t
    WHERE char_length(t) >= 2
      AND t NOT IN (
        'de', 'del', 'la', 'el', 'los', 'las', 'en', 'con', 'por', 'para',
        'un', 'una', 'the', 'of', 'and', 'to', 'on', 'with', 'al'
      )
  );

  IF coalesce(array_length(tokens, 1), 0) = 0 THEN
    tokens := ARRAY[public.normalize_exercise_search(p_query)];
  END IF;

  RETURN QUERY
  SELECT ce.*
  FROM public.catalog_exercises ce
  WHERE (
    SELECT bool_and(
      EXISTS (
        SELECT 1
        FROM unnest(public.exercise_search_token_variants(t.token)) AS v(variant)
        WHERE public.catalog_exercise_search_haystack(ce)
          LIKE '%' || v.variant || '%'
      )
    )
    FROM unnest(tokens) AS t(token)
  )
  ORDER BY
    (public.normalize_exercise_search(ce.name_en)
      LIKE public.normalize_exercise_search(p_query) || '%') DESC,
    (public.catalog_exercise_search_haystack(ce)
      LIKE '%' || rewritten || '%') DESC,
    ce.name_en
  LIMIT greatest(1, least(p_limit, 80))
  OFFSET greatest(0, p_offset);
END;
$$;

GRANT EXECUTE ON FUNCTION public.normalize_exercise_search(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.exercise_search_token_variants(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rewrite_exercise_search_query(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.catalog_exercise_search_haystack(public.catalog_exercises) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.search_catalog_exercises(TEXT, INT, INT) TO anon, authenticated;
