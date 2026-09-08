begin;

create extension if not exists pgcrypto;

do $$
begin

  if not exists (
    select 1 from pg_type
    where typname = 'roleverse_story_status'
  ) then
    create type public.roleverse_story_status
      as enum ('Activa', 'Pausada', 'Finalizada');
  end if;

  if not exists (
    select 1 from pg_type
    where typname = 'roleverse_member_role'
  ) then
    create type public.roleverse_member_role
      as enum ('owner', 'member');
  end if;

  if not exists (
    select 1 from pg_type
    where typname = 'roleverse_character_type'
  ) then
    create type public.roleverse_character_type
      as enum ('character', 'narrator');
  end if;

  if not exists (
    select 1 from pg_type
    where typname = 'roleverse_message_type'
  ) then
    create type public.roleverse_message_type
      as enum ('character', 'narrator', 'dice');
  end if;

end $$;

create table if not exists public.profiles (

  id uuid primary key
    references auth.users(id)
    on delete cascade,

  display_name text not null
    default 'Usuario',

  avatar_url text,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now()
);

create table if not exists public.stories (

  id uuid primary key
    default gen_random_uuid(),

  owner_id uuid not null
    references auth.users(id)
    on delete cascade,

  name text not null
    default 'Historia sin nombre',

  genre text not null
    default 'Roleplay',

  chapter text not null
    default 'Capítulo 1 — El comienzo',

  location text not null
    default 'Sin definir',

  scenario text not null
    default 'Sin definir',

  notes text not null
    default 'Aquí podremos guardar información importante del universo.',

  status public.roleverse_story_status not null
    default 'Activa',

  cover_path text,

  cover_url text,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now()
);

create table if not exists public.story_members (

  story_id uuid not null
    references public.stories(id)
    on delete cascade,

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  role public.roleverse_member_role not null
    default 'member',

  joined_at timestamptz not null
    default now(),

  primary key (story_id, user_id)
);

create table if not exists public.characters (

  id uuid primary key
    default gen_random_uuid(),

  owner_id uuid not null
    references auth.users(id)
    on delete cascade,

  name text not null
    default 'Sin nombre',

  type public.roleverse_character_type not null
    default 'character',

  mine boolean not null
    default false,

  initial text not null
    default '✦',

  weight text not null
    default 'Sin definir',

  height text not null
    default 'Sin definir',

  gender text not null
    default 'Sin definir',

  likes text not null
    default 'Sin definir',

  sexual_likes text not null
    default 'Sin definir',

  abilities jsonb not null
    default '[]'::jsonb,

  history text not null
    default '',

  image_path text,

  image_url text,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now(),

  constraint characters_abilities_array
    check (
      jsonb_typeof(abilities) = 'array'
    )
);

create table if not exists public.character_stats (

  character_id uuid primary key
    references public.characters(id)
    on delete cascade,

  fuerza smallint not null
    default 5
    check (fuerza between 0 and 100),

  velocidad smallint not null
    default 5
    check (velocidad between 0 and 100),

  resistencia smallint not null
    default 5
    check (resistencia between 0 and 100),

  inteligencia smallint not null
    default 5
    check (inteligencia between 0 and 100),

  voluntad smallint not null
    default 5
    check (voluntad between 0 and 100),

  percepcion smallint not null
    default 5
    check (percepcion between 0 and 100),

  tecnica smallint not null
    default 5
    check (tecnica between 0 and 100),

  carisma smallint not null
    default 5
    check (carisma between 0 and 100),

  updated_at timestamptz not null
    default now()
);

create table if not exists public.story_characters (

  story_id uuid not null
    references public.stories(id)
    on delete cascade,

  character_id uuid not null
    references public.characters(id)
    on delete cascade,

  added_by uuid not null
    references auth.users(id)
    on delete cascade,

  created_at timestamptz not null
    default now(),

  primary key (story_id, character_id)
);

create table if not exists public.messages (

  id uuid primary key
    default gen_random_uuid(),

  story_id uuid not null
    references public.stories(id)
    on delete cascade,

  character_id uuid
    references public.characters(id)
    on delete set null,

  sender_id uuid
    references auth.users(id)
    on delete set null,

  speaker text not null
    default 'Narrador',

  type public.roleverse_message_type not null
    default 'character',

  text text not null
    default '',

  image_path text,

  image_url text,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now(),

  constraint message_has_content
    check (
      length(trim(text)) > 0
      or image_path is not null
      or image_url is not null
    )
);

create index if not exists idx_stories_owner
on public.stories(owner_id);

create index if not exists idx_stories_updated
on public.stories(updated_at desc);

create index if not exists idx_story_members_user
on public.story_members(user_id);

create index if not exists idx_story_members_story
on public.story_members(story_id);

create index if not exists idx_characters_owner
on public.characters(owner_id);

create index if not exists idx_story_characters_story
on public.story_characters(story_id);

create index if not exists idx_story_characters_character
on public.story_characters(character_id);

create index if not exists idx_messages_story_created
on public.messages(story_id, created_at);

create index if not exists idx_messages_character
on public.messages(character_id);

create index if not exists idx_messages_sender
on public.messages(sender_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin

  new.updated_at = now();

  return new;

end;
$$;

drop trigger if exists profiles_set_updated_at
on public.profiles;

create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists stories_set_updated_at
on public.stories;

create trigger stories_set_updated_at
before update on public.stories
for each row
execute function public.set_updated_at();

drop trigger if exists characters_set_updated_at
on public.characters;

create trigger characters_set_updated_at
before update on public.characters
for each row
execute function public.set_updated_at();

drop trigger if exists character_stats_set_updated_at
on public.character_stats;

create trigger character_stats_set_updated_at
before update on public.character_stats
for each row
execute function public.set_updated_at();

drop trigger if exists messages_set_updated_at
on public.messages;

create trigger messages_set_updated_at
before update on public.messages
for each row
execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin

  insert into public.profiles (
    id,
    display_name
  )

  values (
    new.id,

    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      new.raw_user_meta_data ->> 'name',
      'Usuario'
    )
  )

  on conflict (id)
  do nothing;

  return new;

end;
$$;

drop trigger if exists on_auth_user_created
on auth.users;

create trigger on_auth_user_created

after insert on auth.users

for each row
execute function public.handle_new_user();

create or replace function public.is_story_member(
  p_story_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$

  select exists (

    select 1

    from public.stories s

    where s.id = p_story_id

      and s.owner_id =
        (select auth.uid())

    union all

    select 1

    from public.story_members sm

    where sm.story_id = p_story_id

      and sm.user_id =
        (select auth.uid())

  );

$$;

create or replace function public.is_story_owner(
  p_story_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$

  select exists (

    select 1

    from public.stories s

    where s.id = p_story_id

      and s.owner_id =
        (select auth.uid())

  );

$$;

create or replace function public.can_use_character(
  p_character_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$

  select

    exists (

      select 1

      from public.characters c

      where c.id = p_character_id

        and c.owner_id =
          (select auth.uid())

    )

    or

    exists (

      select 1

      from public.story_characters sc

      join public.story_members sm
        on sm.story_id = sc.story_id

      where sc.character_id = p_character_id

        and sm.user_id =
          (select auth.uid())

    );

$$;

create or replace function public.can_use_character_in_story(
  p_character_id uuid,
  p_story_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$

  select exists (

    select 1

    from public.characters c

    where c.id = p_character_id

      and c.owner_id = (select auth.uid())

  )

  or exists (

    select 1

    from public.story_characters sc

    join public.story_members sm
      on sm.story_id = sc.story_id

    where sc.story_id = p_story_id

      and sc.character_id = p_character_id

      and sm.user_id = (select auth.uid())

  );

$$;

alter table public.profiles
enable row level security;

alter table public.stories
enable row level security;

alter table public.story_members
enable row level security;

alter table public.characters
enable row level security;

alter table public.character_stats
enable row level security;

alter table public.story_characters
enable row level security;

alter table public.messages
enable row level security;

revoke all
on table public.profiles
from anon;

revoke all
on table public.stories
from anon;

revoke all
on table public.story_members
from anon;

revoke all
on table public.characters
from anon;

revoke all
on table public.character_stats
from anon;

revoke all
on table public.story_characters
from anon;

revoke all
on table public.messages
from anon;

grant select, insert, update, delete
on public.profiles
to authenticated;

grant select, insert, update, delete
on public.stories
to authenticated;

grant select, insert, update, delete
on public.story_members
to authenticated;

grant select, insert, update, delete
on public.characters
to authenticated;

grant select, insert, update, delete
on public.character_stats
to authenticated;

grant select, insert, update, delete
on public.story_characters
to authenticated;

grant select, insert, update, delete
on public.messages
to authenticated;

drop policy if exists profiles_select_own
on public.profiles;

create policy profiles_select_own

on public.profiles

for select

to authenticated

using (
  (select auth.uid()) = id
);

drop policy if exists profiles_insert_own
on public.profiles;

create policy profiles_insert_own

on public.profiles

for insert

to authenticated

with check (
  (select auth.uid()) = id
);

drop policy if exists profiles_update_own
on public.profiles;

create policy profiles_update_own

on public.profiles

for update

to authenticated

using (
  (select auth.uid()) = id
)

with check (
  (select auth.uid()) = id
);

drop policy if exists profiles_delete_own
on public.profiles;

create policy profiles_delete_own

on public.profiles

for delete

to authenticated

using (
  (select auth.uid()) = id
);

drop policy if exists stories_select_members
on public.stories;

create policy stories_select_members

on public.stories

for select

to authenticated

using (

  owner_id = (select auth.uid())

  or public.is_story_member(id)

);

drop policy if exists stories_insert_owner
on public.stories;

create policy stories_insert_owner

on public.stories

for insert

to authenticated

with check (
  owner_id = (select auth.uid())
);

drop policy if exists stories_update_owner
on public.stories;

create policy stories_update_owner

on public.stories

for update

to authenticated

using (
  owner_id = (select auth.uid())
)

with check (
  owner_id = (select auth.uid())
);

drop policy if exists stories_delete_owner
on public.stories;

create policy stories_delete_owner

on public.stories

for delete

to authenticated

using (
  owner_id = (select auth.uid())
);

drop policy if exists story_members_select_members
on public.story_members;

create policy story_members_select_members

on public.story_members

for select

to authenticated

using (
  public.is_story_member(story_id)
);

drop policy if exists story_members_insert_owner
on public.story_members;

create policy story_members_insert_owner

on public.story_members

for insert

to authenticated

with check (
  public.is_story_owner(story_id)
);

drop policy if exists story_members_update_owner
on public.story_members;

create policy story_members_update_owner

on public.story_members

for update

to authenticated

using (
  public.is_story_owner(story_id)
)

with check (
  public.is_story_owner(story_id)
);

drop policy if exists story_members_delete_owner
on public.story_members;

create policy story_members_delete_owner

on public.story_members

for delete

to authenticated

using (
  public.is_story_owner(story_id)
);

drop policy if exists characters_select_allowed
on public.characters;

create policy characters_select_allowed

on public.characters

for select

to authenticated

using (
  public.can_use_character(id)
);

drop policy if exists characters_insert_own
on public.characters;

create policy characters_insert_own

on public.characters

for insert

to authenticated

with check (
  owner_id = (select auth.uid())
);

drop policy if exists characters_update_own
on public.characters;

create policy characters_update_own

on public.characters

for update

to authenticated

using (
  owner_id = (select auth.uid())
)

with check (
  owner_id = (select auth.uid())
);

drop policy if exists characters_delete_own
on public.characters;

create policy characters_delete_own

on public.characters

for delete

to authenticated

using (
  owner_id = (select auth.uid())
);

drop policy if exists character_stats_select_allowed
on public.character_stats;

create policy character_stats_select_allowed

on public.character_stats

for select

to authenticated

using (
  public.can_use_character(character_id)
);

drop policy if exists character_stats_insert_owner
on public.character_stats;

create policy character_stats_insert_owner

on public.character_stats

for insert

to authenticated

with check (

  exists (

    select 1

    from public.characters c

    where c.id = character_id

      and c.owner_id =
        (select auth.uid())

  )

);

drop policy if exists character_stats_update_owner
on public.character_stats;

create policy character_stats_update_owner

on public.character_stats

for update

to authenticated

using (

  exists (

    select 1

    from public.characters c

    where c.id = character_id

      and c.owner_id =
        (select auth.uid())

  )

)

with check (

  exists (

    select 1

    from public.characters c

    where c.id = character_id

      and c.owner_id =
        (select auth.uid())

  )

);

drop policy if exists character_stats_delete_owner
on public.character_stats;

create policy character_stats_delete_owner

on public.character_stats

for delete

to authenticated

using (

  exists (

    select 1

    from public.characters c

    where c.id = character_id

      and c.owner_id =
        (select auth.uid())

  )

);

drop policy if exists story_characters_select_members
on public.story_characters;

create policy story_characters_select_members

on public.story_characters

for select

to authenticated

using (
  public.is_story_member(story_id)
);

drop policy if exists story_characters_insert_members
on public.story_characters;

create policy story_characters_insert_members

on public.story_characters

for insert

to authenticated

with check (

  public.is_story_member(story_id)

  and public.can_use_character_in_story(character_id, story_id)

  and added_by = (select auth.uid())

);

drop policy if exists story_characters_delete_members
on public.story_characters;

create policy story_characters_delete_members

on public.story_characters

for delete

to authenticated

using (

  public.is_story_member(story_id)

  and (

    public.is_story_owner(story_id)

    or added_by = (select auth.uid())

  )

);

drop policy if exists messages_select_members
on public.messages;

drop policy if exists messages_insert_members
on public.messages;

create policy messages_select_members

on public.messages

for select

to authenticated

using (

  public.is_story_member(story_id)

);

create policy messages_insert_members

on public.messages

for insert

to authenticated

with check (

  public.is_story_member(story_id)

  and (

    sender_id = (select auth.uid())

    or sender_id is null

  )

  and (

    character_id is null

    or public.can_use_character_in_story(character_id, story_id)

  )

);


drop policy if exists messages_update_members
on public.messages;

create policy messages_update_members

on public.messages

for update

to authenticated

using (

  public.is_story_member(story_id)

  and (

    sender_id = (select auth.uid())

    or public.is_story_owner(story_id)

  )

)

with check (

  public.is_story_member(story_id)

  and (

    sender_id = (select auth.uid())

    or public.is_story_owner(story_id)

  )

);

drop policy if exists messages_delete_members
on public.messages;

create policy messages_delete_members

on public.messages

for delete

to authenticated

using (

  public.is_story_member(story_id)

  and (

    sender_id = (select auth.uid())

    or public.is_story_owner(story_id)

  )

);

insert into storage.buckets (
  id,
  name,
  public
)

values (
  'roleverse-media',
  'roleverse-media',
  false
)

on conflict (id)

do update set
  public = false;

drop policy if exists roleverse_media_select
on storage.objects;

create policy roleverse_media_select

on storage.objects

for select

to authenticated

using (

  bucket_id = 'roleverse-media'

  and split_part(name, '/', 1) = 'stories'

  and public.is_story_member(

    nullif(
      split_part(name, '/', 2),
      ''
    )::uuid

  )

);

drop policy if exists roleverse_media_insert
on storage.objects;

create policy roleverse_media_insert

on storage.objects

for insert

to authenticated

with check (

  bucket_id = 'roleverse-media'

  and split_part(name, '/', 1) = 'stories'

  and public.is_story_member(

    nullif(
      split_part(name, '/', 2),
      ''
    )::uuid

  )

);

drop policy if exists roleverse_media_update
on storage.objects;

create policy roleverse_media_update

on storage.objects

for update

to authenticated

using (

  bucket_id = 'roleverse-media'

  and split_part(name, '/', 1) = 'stories'

  and public.is_story_member(

    nullif(
      split_part(name, '/', 2),
      ''
    )::uuid

  )

)

with check (

  bucket_id = 'roleverse-media'

  and split_part(name, '/', 1) = 'stories'

  and public.is_story_member(

    nullif(
      split_part(name, '/', 2),
      ''
    )::uuid

  )

);

drop policy if exists roleverse_media_delete
on storage.objects;

create policy roleverse_media_delete

on storage.objects

for delete

to authenticated

using (

  bucket_id = 'roleverse-media'

  and split_part(name, '/', 1) = 'stories'

  and public.is_story_member(

    nullif(
      split_part(name, '/', 2),
      ''
    )::uuid

  )

);

do $$
begin

  begin
    alter publication supabase_realtime
      add table public.messages;
  exception
    when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime
      add table public.stories;
  exception
    when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime
      add table public.characters;
  exception
    when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime
      add table public.character_stats;
  exception
    when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime
      add table public.story_characters;
  exception
    when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime
      add table public.story_members;
  exception
    when duplicate_object then null;
  end;

end $$;

create or replace function public.create_roleverse_story(
  p_name text,
  p_genre text default 'Roleplay'
)

returns uuid

language plpgsql

security invoker

set search_path = public

as $$

declare

  v_story_id uuid;

begin

  if auth.uid() is null then

    raise exception
      'Debes iniciar sesión.';

  end if;

  insert into public.stories (

    owner_id,
    name,
    genre

  )

  values (

    auth.uid(),

    coalesce(
      nullif(trim(p_name), ''),
      'Historia sin nombre'
    ),

    coalesce(
      nullif(trim(p_genre), ''),
      'Roleplay'
    )

  )

  returning id
  into v_story_id;

  insert into public.story_members (

    story_id,
    user_id,
    role

  )

  values (

    v_story_id,
    auth.uid(),
    'owner'

  );

  return v_story_id;

end;

$$;

grant execute
on function public.create_roleverse_story(text, text)
to authenticated;

commit;