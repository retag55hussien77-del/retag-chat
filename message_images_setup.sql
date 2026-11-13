-- Retag Chat: secure image attachments for private 1-to-1 messages
-- REVIEW ONLY: do not run until the current Supabase schema has been backed up/reviewed.
-- Additive migration: does not delete or rewrite existing messages or storage objects.
-- Expected existing columns: messages.id, sender_id, receiver_id, content, created_at.

begin;

alter table public.messages
  add column if not exists attachment_path text,
  add column if not exists attachment_mime_type text,
  add column if not exists attachment_size_bytes bigint;

create index if not exists messages_attachment_path_idx
  on public.messages (attachment_path)
  where attachment_path is not null;

-- Keep the bucket private. A recipient can read an object only when a message
-- explicitly references that exact object path and they are its sender/receiver.
-- The uploader's UID must be the first folder in the object path, e.g.
-- <auth.uid()>/<random-file-id>.jpg
insert into storage.buckets (id, name, public)
values ('chat-images', 'chat-images', false)
on conflict (id) do update set public = false;

drop policy if exists "Retag users read chat images in their conversations"
  on storage.objects;

create policy "Retag users read chat images in their conversations"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'chat-images'
  and exists (
    select 1
    from public.messages m
    where m.attachment_path = storage.objects.name
      and (auth.uid() = m.sender_id or auth.uid() = m.receiver_id)
  )
);

-- Uploads remain restricted to each user's own UID folder.
drop policy if exists "Retag users upload own chat images" on storage.objects;
create policy "Retag users upload own chat images"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'chat-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Only the uploader can delete their own stored image. Recipients are read-only.
drop policy if exists "Retag users delete own chat images" on storage.objects;
create policy "Retag users delete own chat images"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'chat-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

commit;

-- Application upload flow:
-- 1) Upload to chat-images/<auth.uid()>/<random-uuid>.<validated-extension>.
-- 2) Insert a messages row with sender_id=auth.uid(), receiver_id=recipient UUID,
--    content='' (or a short caption), and attachment_path equal to the object path.
-- 3) Render images with createSignedUrl() while signed in. The storage SELECT
--    policy above authorizes both participants because the message references it.
-- 4) Never make chat-images public; never put a service-role key in browser code.
-- 5) Validate MIME type and file size in the client for usability, but do not treat
--    client validation as a security boundary.
--
-- Important limitation:
-- The existing messages UPDATE policy only allows the sender to update messages.
-- Read receipts and recipient-side delivery state need a separately designed
-- policy/schema before implementing them; do not weaken the sender/receiver rules.
