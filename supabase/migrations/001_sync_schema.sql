-- Optional future cross-device sync schema.
-- The current MVP stores plans locally and does not require this migration.

create table if not exists public.reading_plans (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  default_translation text not null check (default_translation in ('kjv', 'nlt')),
  start_date date not null,
  end_date date not null,
  reading_weekdays int[] not null,
  reminder_time time not null,
  source_references_json jsonb not null default '[]'::jsonb,
  template_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scheduled_readings (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.reading_plans(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  scheduled_date date not null,
  position int not null,
  references_json jsonb not null,
  completed boolean not null default false,
  translation_override text check (translation_override in ('kjv', 'nlt')),
  updated_at timestamptz not null default now(),
  unique(plan_id, position)
);

alter table public.reading_plans enable row level security;
alter table public.scheduled_readings enable row level security;

create policy "Users manage their own plans"
on public.reading_plans
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users manage their own scheduled readings"
on public.scheduled_readings
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
