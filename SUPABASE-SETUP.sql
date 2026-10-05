-- EDUVO / Supabase setup
-- شغّل الملف كله مرة واحدة داخل Supabase > SQL Editor.
-- لا تضع Service Role Key داخل الموقع.

create extension if not exists pgcrypto;

create table if not exists public.students (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  email text,
  grade text,
  provider text not null default 'phone',
  status text not null default 'active' check (status in ('active','pending','suspended','rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists students_phone_idx on public.students(phone);
create index if not exists students_created_at_idx on public.students(created_at desc);

create or replace function public.set_students_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists students_set_updated_at on public.students;
create trigger students_set_updated_at
before update on public.students
for each row execute function public.set_students_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.students (id, full_name, phone, email, grade, provider)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.phone,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'grade', ''),
    coalesce(new.app_metadata ->> 'provider', 'phone')
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    phone = excluded.phone,
    email = excluded.email,
    grade = excluded.grade,
    provider = excluded.provider;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.students enable row level security;

-- الطالب يرى ويعدل بياناته فقط.
drop policy if exists "students_select_own" on public.students;
create policy "students_select_own"
on public.students for select
to authenticated
using (auth.uid() = id or (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "students_insert_own" on public.students;
create policy "students_insert_own"
on public.students for insert
to authenticated
with check (auth.uid() = id or (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "students_update_own" on public.students;
create policy "students_update_own"
on public.students for update
to authenticated
using (auth.uid() = id or (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
with check (auth.uid() = id or (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "students_delete_admin" on public.students;
create policy "students_delete_admin"
on public.students for delete
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

grant usage on schema public to authenticated;
grant select, insert, update on public.students to authenticated;
grant delete on public.students to authenticated;

-- بعد إنشاء حساب المدير من Supabase Auth، استبدل UUID وضعه هنا:
-- update auth.users
-- set raw_app_meta_data = jsonb_set(coalesce(raw_app_meta_data, '{}'::jsonb), '{role}', '"admin"', true)
-- where id = 'PUT-ADMIN-USER-UUID-HERE';
