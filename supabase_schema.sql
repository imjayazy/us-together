-- Run AFTER your original schema. Safe to re-run.
alter table public.workouts add column if not exists muscle_group text;

create table if not exists public.goals (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 area text not null, kind text not null check (kind in ('fat','muscle')),
 target_text text, target_date date, achieved boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.body_logs (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 log_date date not null default current_date,
 weight_kg numeric, waist_cm numeric, body_fat_pct numeric,
 created_at timestamptz not null default now()
);
create table if not exists public.assigned_workouts (
 id uuid primary key default gen_random_uuid(),
 assigned_by uuid not null references auth.users(id) on delete cascade,
 assigned_to uuid not null references auth.users(id) on delete cascade,
 exercise text not null, muscle_group text,
 sets integer not null default 3, reps integer not null default 10, weight_kg numeric,
 due_date date not null default current_date,
 completed boolean not null default false, completed_at timestamptz,
 created_at timestamptz not null default now()
);
alter table public.goals enable row level security;
alter table public.body_logs enable row level security;
alter table public.assigned_workouts enable row level security;

drop policy if exists goals_select on public.goals;
create policy goals_select on public.goals for select to authenticated
using(user_id=auth.uid() or (public.current_couple_id() is not null and user_id in(select id from public.profiles where couple_id=public.current_couple_id())));
drop policy if exists goals_insert on public.goals;
create policy goals_insert on public.goals for insert to authenticated with check(user_id=auth.uid());
drop policy if exists goals_update on public.goals;
create policy goals_update on public.goals for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists goals_delete on public.goals;
create policy goals_delete on public.goals for delete to authenticated using(user_id=auth.uid());

drop policy if exists body_select on public.body_logs;
create policy body_select on public.body_logs for select to authenticated
using(user_id=auth.uid() or (public.current_couple_id() is not null and user_id in(select id from public.profiles where couple_id=public.current_couple_id())));
drop policy if exists body_insert on public.body_logs;
create policy body_insert on public.body_logs for insert to authenticated with check(user_id=auth.uid());
drop policy if exists body_delete on public.body_logs;
create policy body_delete on public.body_logs for delete to authenticated using(user_id=auth.uid());

drop policy if exists assign_select on public.assigned_workouts;
create policy assign_select on public.assigned_workouts for select to authenticated using(assigned_by=auth.uid() or assigned_to=auth.uid());
drop policy if exists assign_insert on public.assigned_workouts;
create policy assign_insert on public.assigned_workouts for insert to authenticated
with check(assigned_by=auth.uid() and assigned_to in(select id from public.profiles where couple_id=public.current_couple_id()));
drop policy if exists assign_update on public.assigned_workouts;
create policy assign_update on public.assigned_workouts for update to authenticated using(assigned_to=auth.uid() or assigned_by=auth.uid()) with check(assigned_to=auth.uid() or assigned_by=auth.uid());
drop policy if exists assign_delete on public.assigned_workouts;
create policy assign_delete on public.assigned_workouts for delete to authenticated using(assigned_by=auth.uid());

grant select,insert,update,delete on public.goals to authenticated;
grant select,insert,delete on public.body_logs to authenticated;
grant select,insert,update,delete on public.assigned_workouts to authenticated;
