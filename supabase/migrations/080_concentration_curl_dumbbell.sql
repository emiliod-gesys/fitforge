-- Seated dumbbell concentration curl, logged per arm.

INSERT INTO public.catalog_exercises (
  id, dataset_id, name_en, name_es,
  category, body_part, equipment, target_muscle, muscle_group,
  secondary_muscles, muscles,
  logging_type, load_mode, per_arm_weight, unilateral, weight_optional,
  image_url, gif_url, attribution, search_text
) VALUES (
  'ext_curated_concentration_curl',
  'curated_concentration_curl',
  'Dumbbell Concentration Curl',
  'Curl de concentración con mancuerna',
  'Bíceps',
  'upper arms',
  'Mancuernas',
  'biceps',
  'biceps',
  '["forearms"]'::jsonb,
  '["Bíceps","Antebrazos"]'::jsonb,
  'strength',
  'single_load',
  true,
  true,
  false,
  'https://cpxpqklbmiwguvuwifpd.supabase.co/storage/v1/object/public/exercise-media/curated/concentration-curl.gif',
  'https://cpxpqklbmiwguvuwifpd.supabase.co/storage/v1/object/public/exercise-media/curated/concentration-curl.gif',
  'FORGEN',
  'dumbbell concentration curl curl de concentracion con mancuerna biceps mancuernas'
)
ON CONFLICT (id) DO UPDATE SET
  name_en = EXCLUDED.name_en,
  name_es = EXCLUDED.name_es,
  category = EXCLUDED.category,
  equipment = EXCLUDED.equipment,
  target_muscle = EXCLUDED.target_muscle,
  per_arm_weight = EXCLUDED.per_arm_weight,
  unilateral = EXCLUDED.unilateral,
  image_url = EXCLUDED.image_url,
  gif_url = EXCLUDED.gif_url,
  search_text = EXCLUDED.search_text;
