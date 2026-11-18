-- Neon Cloud v6.5.7 — Join Kelas + class attendance analytics
-- Run once in Supabase SQL Editor, then deploy the updated index.html to gpealgo.app.

-- 1) Google Meet link on board posts
alter table public.app_events
  add column if not exists meet_url text;

comment on column public.app_events.meet_url is 'Google Meet URL for class/webinar posts';

-- 2) Attendance table (event_id type mirrors app_events.id)
do $$
declare
  id_type text;
begin
  select format_type(a.atttypid, a.atttypmod)
    into id_type
  from pg_attribute a
  join pg_class c on c.oid = a.attrelid
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'app_events'
    and a.attname = 'id'
    and a.attnum > 0
    and not a.attisdropped;

  if id_type is null then
    raise exception 'public.app_events.id not found — run product SQL first';
  end if;

  if to_regclass('public.class_joins') is null then
    execute format($sql$
      create table public.class_joins (
        id bigserial primary key,
        event_id %s not null references public.app_events(id) on delete cascade,
        user_id uuid,
        email text not null,
        display_name text,
        mt5_account bigint,
        joined_at timestamptz not null default now(),
        unique (event_id, email)
      )
    $sql$, id_type);
  end if;
end $$;

create index if not exists class_joins_event_id_idx on public.class_joins (event_id);
create index if not exists class_joins_joined_at_idx on public.class_joins (joined_at desc);

alter table public.class_joins enable row level security;

drop policy if exists class_joins_insert_own on public.class_joins;
create policy class_joins_insert_own on public.class_joins
  for insert to authenticated
  with check (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

drop policy if exists class_joins_select_own on public.class_joins;
create policy class_joins_select_own on public.class_joins
  for select to authenticated
  using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

drop policy if exists class_joins_select_admin on public.class_joins;
create policy class_joins_select_admin on public.class_joins
  for select to authenticated
  using (
    exists (
      select 1 from public.admin_users a
      where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
  );

drop policy if exists class_joins_update_own on public.class_joins;
create policy class_joins_update_own on public.class_joins
  for update to authenticated
  using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')))
  with check (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

-- 3) Join RPC — records attendance and returns Meet URL
create or replace function public.join_class_event(p_event_id text)
returns table (meet_url text, already_joined boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(coalesce(auth.jwt() ->> 'email', ''));
  v_uid uuid := auth.uid();
  v_meet text;
  v_kind text;
  v_exists boolean := false;
begin
  if v_email = '' then
    raise exception 'Not logged in';
  end if;

  execute $q$
    select e.meet_url, e.kind
    from public.app_events e
    where e.id::text = $1
  $q$ into v_meet, v_kind using p_event_id;

  if v_kind is null then
    raise exception 'Class not found';
  end if;

  if lower(coalesce(v_kind, '')) not in ('class', 'webinar') then
    raise exception 'Not a class or webinar post';
  end if;

  select exists(
    select 1 from public.class_joins j
    where j.event_id::text = p_event_id and lower(j.email) = v_email
  ) into v_exists;

  insert into public.class_joins (event_id, user_id, email, display_name, mt5_account, joined_at)
  select e.id, v_uid, v_email, split_part(v_email, '@', 1), null, now()
  from public.app_events e
  where e.id::text = p_event_id
  on conflict (event_id, email) do update
    set joined_at = excluded.joined_at,
        user_id = coalesce(public.class_joins.user_id, excluded.user_id);

  return query select v_meet, v_exists;
end;
$$;

grant execute on function public.join_class_event(text) to authenticated;

-- 4) Admin live attendance list
create or replace function public.list_class_joins(p_event_id text)
returns table (
  email text,
  display_name text,
  mt5_account bigint,
  joined_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(coalesce(auth.jwt() ->> 'email', ''));
begin
  if not exists (
    select 1 from public.admin_users a where lower(a.email) = v_email
  ) then
    raise exception 'Admin only';
  end if;

  return query
  select j.email, j.display_name, j.mt5_account, j.joined_at
  from public.class_joins j
  where j.event_id::text = p_event_id
  order by j.joined_at asc;
end;
$$;

grant execute on function public.list_class_joins(text) to authenticated;

-- Note: keep existing post_board_event() as-is (notifications).
-- The web app writes meet_url with an UPDATE right after a successful board post.
