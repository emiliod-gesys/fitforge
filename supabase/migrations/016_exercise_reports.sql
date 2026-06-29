-- Reportes de problemas en ejercicios del catálogo.
create table if not exists public.exercise_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  exercise_id text not null,
  exercise_name text not null,
  category text not null,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists exercise_reports_exercise_id_idx
  on public.exercise_reports (exercise_id);

alter table public.exercise_reports enable row level security;

create policy "Users insert own exercise reports"
  on public.exercise_reports for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users read own exercise reports"
  on public.exercise_reports for select
  to authenticated
  using (auth.uid() = user_id);
