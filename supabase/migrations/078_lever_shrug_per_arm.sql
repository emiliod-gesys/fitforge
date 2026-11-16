-- Lever shrug machines are loaded per side. The cloud rows were seeded
-- with per_arm_weight = false, so the workout logger treated them as one stack.

UPDATE catalog_exercises
SET per_arm_weight = true
WHERE per_arm_weight = false
  AND name_en ~* '^lever (gripless )?shrug';
