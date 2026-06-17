-- Sistema de niveles / XP del jugador

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS total_xp BIGINT NOT NULL DEFAULT 0;

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS xp_awarded INTEGER;

COMMENT ON COLUMN public.profiles.total_xp IS 'Experiencia acumulada para el sistema de niveles';
COMMENT ON COLUMN public.workouts.xp_awarded IS 'XP otorgada al completar (idempotencia)';
