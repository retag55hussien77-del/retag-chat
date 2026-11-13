-- Retag Chat: recipient-safe private image attachments
-- REVIEW ONLY. Do not run until the live schema and all existing policies are audited.
-- Assumptions from the repository's existing setup:
--   public.messages(id bigint, sender_id uuid, receiver_id uuid, ...)
--   private Storage bucket: chat-images
-- This migration is additive. It does not create public URLs or make the bucket public.

begin;

do $$
begin
  if to_regclass('public.messages') is null then
    raise exception 'Missing public.messages; stop and inspect the live schema.';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='messages' and column_name='id'
      and data_type='bigint'
  ) then
    raise exception 'Expected public.messages.id to be bigint; inspect before proceeding.';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='messages' and column_name='sender_id'
      and udt_name='uuid'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='messages' and column_name='receiver_id'
      and udt_name='uuid'
  ) then
    raise exception 'Expected sender_id and receiver_id UUID columns; inspect before proceeding.';
  end if;
  if not exists (select 1 from storage.buckets where id='chat-images' and public=false) then
    raise exception 'Expected existing private chat-images bucket; do not create or expose it automatically.';
  end if;
end $$;

create table if not exists public.message_attachments (
  id uuid primary key default gen_random_uuid(),
  message_id bigint not null references public.messages(id) on delete cascade,
  uploader_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  media_type text not null check (media_type in ('image/jpeg','image/png','image/webp','image/gif')),
  byte_size bigint not null check (byte_size > 0 and byte_size <= 10485760),
  created_at timestamptz not null default now(),
  constraint message_attachments_path_owner check (
    split_part(storage_path, '/', 1) = uploader_id::text
  )
);

alter table public.message_attachments enable row level security;

drop policy if exists "Retag participants read message attachments" on public.message_attachments;
drop policy if exists "Retag senders attach files to own messages" on public.message_attachments;
drop policy if exists "Retag uploaders delete own attachment records" on public.message_attachments;

create policy "Retag participants read message attachments"
on public.message_attachments for select
to authenticated
using (
  exists (
    select 1
    from public.messages m
    where m.id = message_attachments.message_id
      and (auth.uid() = m.sender_id or auth.uid() = m.receiver_id)
  )
);

create policy "Retag senders attach files to own messages"
on public.message_attachments for insert
to authenticated
with check (
  uploader_id = auth.uid()
  and exists (
    select 1
    from public.messages m
    where m.id = message_attachments.message_id
      and m.sender_id = auth.uid()
  )
);

create policy "Retag uploaders delete own attachment records"
on public.message_attachments for delete
to authenticated
using (uploader_id = auth.uid());

revoke all on public.message_attachments from public, anon, authenticated;
grant select, insert, delete on public.message_attachments to authenticated;

-- Uploads remain restricted to the uploader's own UID folder.
-- Recipients may download only an object that is attached to a message addressed to them.
-- The sender can read their own upload even before the attachment row is linked.
drop policy if exists "Retag users read chat images in their conversations" on storage.objects;

create policy "Retag participants read linked chat images"
on storage.objects for select
to authenticated
using (
  bucket_id = 'chat-images'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or exists (
      select 1
      from public.message_attachments a
      join public.messages m on m.id = a.message_id
      where a.storage_path = storage.objects.name
        and (auth.uid() = m.sender_id or auth.uid() = m.receiver_id)
    )
  )
);

commit;

-- Client flow:
-- 1. Insert a message row as the authenticated sender.
-- 2. Upload image to chat-images/<auth.uid()>/<random-uuid>.<allowed-extension>.
-- 3. Insert message_attachments with message_id, uploader_id, storage_path,
--    validated media_type and byte_size.
-- 4. Recipient queries the attachment row (RLS restricts it to message participants),
--    then downloads using the private Storage SDK. Do not store a permanent public URL.
-- 5. For stricter orphan cleanup, add a scheduled server-side cleanup after testing.
--
-- Important: Supabase permissive policies are OR-combined. Audit and remove/replace
-- any older broad SELECT policy on storage.objects or message_attachments before
-- relying on this policy. Never assume dropping one named policy removes all access.
