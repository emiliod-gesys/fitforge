-- Índice para consultas de métricas corporales por usuario y tipo
CREATE INDEX IF NOT EXISTS idx_body_measurements_user_type_date
  ON public.body_measurements(user_id, type, measured_at DESC);
