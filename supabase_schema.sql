create extension if not exists pgcrypto;

create table if not exists public.couples (
 id uuid primary key default gen_random_uuid(),
 invite_code text unique not null,
 created_by uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default 'Partner',
 couple_id uuid references public.couples(id) on delete set null,
 created_at timestamptz not null default now()
);
create table if not exists public.tasks (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 title text not null, due_date date, category text default 'Routine',
 completed boolean not null default false, completed_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.workouts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 exercise text not null, workout_date date not null default current_date,
 workout_type text default 'Strength', sets integer not null default 0,
 reps integer not null default 0, weight_kg numeric, duration_min integer,
 notes text, created_at timestamptz not null default now()
);
create table if not exists public.habit_logs (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 habit_name text not null, log_date date not null default current_date,
 completed boolean not null default true, note text, created_at timestamptz not null default now()
);

alter table public.couples enable row level security;
alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.workouts enable row level security;
alter table public.habit_logs enable row level security;

create or replace function public.current_couple_id()
returns uuid language sql stable security definer set search_path=public
as $$ select couple_id from public.profiles where id=auth.uid() $$;

drop policy if exists profiles_select_self_or_couple on public.profiles;
create policy profiles_select_self_or_couple on public.profiles for select to authenticated
using (id=auth.uid() or (couple_id is not null and couple_id=public.current_couple_id()));
drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles for insert to authenticated with check(id=auth.uid());
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());

drop policy if exists couples_select_member_or_creator on public.couples;
create policy couples_select_member_or_creator on public.couples for select to authenticated
using(created_by=auth.uid() or id=public.current_couple_id());
drop policy if exists couples_insert_creator on public.couples;
create policy couples_insert_creator on public.couples for insert to authenticated with check(created_by=auth.uid());

create or replace function public.join_couple_by_code(invite_code_input text)
returns uuid language plpgsql security definer set search_path=public
as $$
declare target_id uuid; existing_id uuid;
begin
 if auth.uid() is null then raise exception 'You must sign in first.'; end if;
 select couple_id into existing_id from public.profiles where id=auth.uid();
 if existing_id is not null then raise exception 'This account is already connected to a couple space.'; end if;
 select id into target_id from public.couples where upper(invite_code)=upper(trim(invite_code_input)) limit 1;
 if target_id is null then raise exception 'Invite code not found.'; end if;
 update public.profiles set couple_id=target_id where id=auth.uid();
 return target_id;
end; $$;
revoke all on function public.join_couple_by_code(text) from public;
grant execute on function public.join_couple_by_code(text) to authenticated;

drop policy if exists tasks_select_self_or_partner on public.tasks;
create policy tasks_select_self_or_partner on public.tasks for select to authenticated
using(user_id=auth.uid() or (public.current_couple_id() is not null and user_id in(select id from public.profiles where couple_id=public.current_couple_id())));
drop policy if exists tasks_insert_couple on public.tasks;
create policy tasks_insert_couple on public.tasks for insert to authenticated
with check(user_id=auth.uid() or (public.current_couple_id() is not null and user_id in(select id from public.profiles where couple_id=public.current_couple_id())));
drop policy if exists tasks_update_self on public.tasks;
create policy tasks_update_self on public.tasks for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists tasks_delete_self on public.tasks;
create policy tasks_delete_self on public.tasks for delete to authenticated using(user_id=auth.uid());

drop policy if exists workouts_select_couple on public.workouts;
create policy workouts_select_couple on public.workouts for select to authenticated
using(user_id=auth.uid() or (public.current_couple_id() is not null and user_id in(select id from public.profiles where couple_id=public.current_couple_id())));
drop policy if exists workouts_insert_self on public.workouts;
create policy workouts_insert_self on public.workouts for insert to authenticated with check(user_id=auth.uid());
drop policy if exists workouts_update_self on public.workouts;
create policy workouts_update_self on public.workouts for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists workouts_delete_self on public.workouts;
create policy workouts_delete_self on public.workouts for delete to authenticated using(user_id=auth.uid());

drop policy if exists habits_select_couple on public.habit_logs;
create policy habits_select_couple on public.habit_logs for select to authenticated
using(user_id=auth.uid() or (public.current_couple_id() is not null and user_id in(select id from public.profiles where couple_id=public.current_couple_id())));
drop policy if exists habits_insert_self on public.habit_logs;
create policy habits_insert_self on public.habit_logs for insert to authenticated with check(user_id=auth.uid());
drop policy if exists habits_update_self on public.habit_logs;
create policy habits_update_self on public.habit_logs for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists habits_delete_self on public.habit_logs;
create policy habits_delete_self on public.habit_logs for delete to authenticated using(user_id=auth.uid());

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
 insert into public.profiles(id,display_name)
 values(new.id,coalesce(new.raw_user_meta_data->>'display_name',split_part(new.email,'@',1)))
 on conflict(id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

grant usage on schema public to authenticated;
grant select,insert,update on public.profiles to authenticated;
grant select,insert on public.couples to authenticated;
grant select,insert,update,delete on public.tasks to authenticated;
grant select,insert,update,delete on public.workouts to authenticated;
grant select,insert,update,delete on public.habit_logs to authenticated;
