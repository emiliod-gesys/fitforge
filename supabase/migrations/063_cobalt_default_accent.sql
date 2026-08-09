-- Azul cobalto como acento principal de marca.
-- Los demás colores siguen disponibles para personalización.
ALTER TABLE public.profiles
  ALTER COLUMN accent_color SET DEFAULT 'cobalt';

-- Los perfiles aún en el antiguo valor predeterminado pasan al nuevo acento.
UPDATE public.profiles
SET accent_color = 'cobalt'
WHERE accent_color = 'gold';
