-- Weighted stretch lunge is one leg at a time. The logged weight is per leg.

UPDATE catalog_exercises
SET per_arm_weight = true,
    unilateral = true
WHERE id = 'ext_3642'
  AND name_en = 'weighted stretch lunge'
  AND per_arm_weight = false;
