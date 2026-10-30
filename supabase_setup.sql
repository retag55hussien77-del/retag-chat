-- Retag Chat: Supabase security setup
-- Review before running in Supabase SQL Editor. This script does not delete existing data.

-- Ensure Row Level Security is enabled.
alter table public.profiles enable row level security;
alter table public.messages enable row level security;

-- Remove only policies with these exact names so this script can be rerun safely.
drop policy if exists "Retag profiles readable by authenticated users" on public.profiles;
drop policy if exists "Retag users create own profile" on public.profiles;
drop policy if exists "Retag users update own profile" on public.profiles;
drop policy if exists "Retag users read own messages" on public.messages;
drop policy if exists "Retag users send as themselves" on public.messages;
drop policy if exists "Retag senders update own messages" on public.messages;
drop policy if exists "Retag senders delete own messages" on public.messages;

create policy "Retag profiles readable by authenticated users"
on public.profiles for select
to authenticated
using (true);

create policy "Retag users create own profile"
on public.profiles for insert
to authenticated
with check (auth.uid() = id);

create policy "Retag users update own profile"
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Retag users read own messages"
on public.messages for select
to authenticated
using (auth.uid() = sender_id or auth.uid() = receiver_id);

create policy "Retag users send as themselves"
on public.messages for insert
to authenticated
with check (auth.uid() = sender_id);

create policy "Retag senders update own messages"
on public.messages for update
to authenticated
using (auth.uid() = sender_id)
with check (auth.uid() = sender_id);

create policy "Retag senders delete own messages"
on public.messages for delete
to authenticated
using (auth.uid() = sender_id);

-- Private bucket for chat images. Object paths must begin with the uploader's auth UID.
insert into storage.buckets (id, name, public)
values ('chat-images', 'chat-images', false)
on conflict (id) do nothing;

drop policy if exists "Retag users upload own chat images" on storage.objects;
drop policy if exists "Retag users read chat images in their conversations" on storage.objects;
drop policy if exists "Retag users delete own chat images" on storage.objects;

create policy "Retag users upload own chat images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'chat-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Retag users read chat images in their conversations"
on storage.objects for select
to authenticated
using (
  bucket_id = 'chat-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Retag users delete own chat images"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'chat-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Realtime publication: add messages only if not already present.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
exception
  when undefined_object then
    raise notice 'supabase_realtime publication was not found; enable Realtime for public.messages in the Supabase dashboard.';
end $$;
