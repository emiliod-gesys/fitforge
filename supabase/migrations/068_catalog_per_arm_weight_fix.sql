-- Fix per_arm_weight for dual-handle / unilateral catalog exercises.
-- dual_load always means the logged weight is per side.
-- Also cover band isolation, dual-handle cable flies/raises, and weighted unilateral moves
-- that were seeded with per_arm_weight = false.

UPDATE catalog_exercises
SET per_arm_weight = true
WHERE per_arm_weight = false
  AND (
    load_mode = 'dual_load'
    OR (
      unilateral = true
      AND load_mode IN ('single_load', 'dual_load', 'machine_stack')
    )
    OR (
      (
        equipment ILIKE '%banda%'
        OR equipment ILIKE '%band%'
        OR name_en ILIKE 'band %'
      )
      AND name_en ~* '(fly|raise|shrug|press|curl|kickback|row|y-raise|wrist|extension|lateral)'
      AND name_en !~* '(pulldown|pull-up|pull through|pallof|assisted|deadlift|squat|crunch|hip|v-up|sit-up|twist)'
    )
    OR (
      (
        equipment ILIKE '%polea%'
        OR equipment ILIKE '%cable%'
        OR name_en ILIKE 'cable %'
      )
      AND name_en ~* '(fly|apertura|cross-over|crossover|lateral raise|front raise|forward raise|kickback|y-raise|reverse fly|rear lateral|two arm)'
      AND name_en !~* '(rope|face pull|pulldown|woodchop|pallof|crunch)'
    )
  );
