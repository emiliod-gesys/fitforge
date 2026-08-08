-- Clara de huevo sin yema, normalizada por 100 g.
-- Incluye aliases de preparación para que Quick Add encuentre el alimento.
INSERT INTO public.catalog_foods (
  id,
  name_es,
  name_en,
  region,
  category,
  calories_kcal,
  protein_g,
  carbs_g,
  fat_g,
  fiber_g,
  amount_unit,
  serving_amount,
  serving_label_es,
  serving_label_en,
  search_text,
  source
)
VALUES (
  'cf_claras_huevo',
  'Claras de huevo',
  'Egg whites',
  'latam',
  'proteina',
  52,
  10.9,
  0.7,
  0.2,
  0,
  'g',
  100,
  '100 g',
  '100 g',
  public.normalize_food_search(
    'Claras de huevo egg whites clara de huevo clara cocida claras cocidas clara cruda claras crudas'
  ),
  'usda'
)
ON CONFLICT (id) DO UPDATE SET
  name_es = EXCLUDED.name_es,
  name_en = EXCLUDED.name_en,
  region = EXCLUDED.region,
  category = EXCLUDED.category,
  calories_kcal = EXCLUDED.calories_kcal,
  protein_g = EXCLUDED.protein_g,
  carbs_g = EXCLUDED.carbs_g,
  fat_g = EXCLUDED.fat_g,
  fiber_g = EXCLUDED.fiber_g,
  amount_unit = EXCLUDED.amount_unit,
  serving_amount = EXCLUDED.serving_amount,
  serving_label_es = EXCLUDED.serving_label_es,
  serving_label_en = EXCLUDED.serving_label_en,
  search_text = EXCLUDED.search_text,
  source = EXCLUDED.source;
