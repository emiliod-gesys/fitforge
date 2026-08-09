-- Amplía las opciones de personalización del color de acento.
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_accent_color_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_accent_color_check
  CHECK (
    accent_color IN (
      'gold',
      'orange',
      'cobalt',
      'violet',
      'emerald',
      'rose',
      'crimson',
      'cyan',
      'teal',
      'indigo',
      'amber',
      'lime'
    )
  );
