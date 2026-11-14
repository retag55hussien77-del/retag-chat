# Retag Chat — Supabase policy and private-image audit

Date: 2026-11-14
Branch: `feature/account-auth-preview`
Status: static review + user-provided dashboard screenshots; NOT a live policy export.

## Evidence reviewed

1. Repository files:
   - `supabase_setup.sql`
   - `accounts_setup.sql`
   - `message_attachments_setup.sql`
   - `message_images_setup.sql`
   - `attachments_preview.html`
   - `messages_preview.html`
   - `contacts_preview.html`
2. User-provided Supabase Policies screenshots:
   - RLS is enabled on `public.profiles` and `public.messages` (the UI shows the "Disable RLS" action for both).
   - The visible policy list contains multiple policies with overlapping commands on each table.
   - The names are clipped by the mobile layout. The screenshots are not a complete export and do not reveal each policy's USING/WITH CHECK expression.

## Screenshot inventory (partial; names intentionally not guessed)

### `public.profiles`
Visible rows include:
- `Profiles are view...` — SELECT — authenticated
- `Retag profiles re...` — SELECT — authenticated
- `Retag users crea...` — INSERT — authenticated
- `Retag users upd...` — UPDATE — authenticated
- `Users can creat...` — INSERT — authenticated
- `Users can u...` — another row is partly visible; command text is not fully legible

### `public.messages`
Visible rows include:
- `Retag senders d...` — DELETE — authenticated
- `Retag senders u...` — UPDATE — authenticated
- `Retag users rea...` — SELECT — authenticated
- `Retag users sen...` — INSERT — authenticated
- `Users can se...` — INSERT — authenticated
- `Users can view t...` — SELECT — authenticated

This is enough to flag duplicate/overlapping policies, but not enough to identify exact expressions or safely delete any policy. Do not remove policies based on clipped names.

## Findings and priority

### Critical before relying on production access control
1. **Overlapping RLS policies exist.** PostgreSQL permissive policies normally combine with OR. A restrictive-looking policy does not cancel a broader older policy. Export the full policy definitions for both tables and Storage before applying changes.
2. **Profiles discovery is too broad in the repository draft.** `supabase_setup.sql` uses `USING (true)` for authenticated SELECT. The contacts preview selects `username, display_name, bio, avatar_url`; do not expose phone/contact details or other private columns in a public directory. Prefer a safe public-profile projection/view and separate private profile data.
3. **Message INSERT needs server-side receiver validation.** Current draft checks only `sender_id = auth.uid()`. It does not reject self-messaging or prove that `receiver_id` is an existing/permitted account.
4. **Message UPDATE is over-broad.** Current sender UPDATE policy can allow changing any updatable column, potentially including `receiver_id` or `created_at`. Until editing is implemented, remove/withhold update access only after reviewing the live policy set; later use a narrowly scoped RPC/trigger/column grants.
5. **Private image recipient access is not provided by the base setup.** Base Storage SELECT only allows the uploader's own UID folder. A recipient cannot read a sender's image with that policy. Do not make the bucket public.

### Attachment design comparison
- Preferred draft: `message_attachments_setup.sql` (separate attachment metadata table; recipient authorization through the linked message).
- Alternative legacy draft: `message_images_setup.sql` (stores one attachment path directly on `messages`).
- **Do not execute both designs.** Choose one only after checking actual schema, existing objects, and all Storage policies. The preferred attachment draft assumes `messages.id bigint`, sender/receiver UUIDs, and an existing private `chat-images` bucket.
- The attachment draft's metadata `byte_size` and `media_type` are supplied by the browser. They are not proof of the uploaded object's real content. Configure Storage's server-side size and MIME restrictions and test them.
- The attachment draft's Storage SELECT policy allows the uploader's own folder and allows the other participant only when the exact object path is linked to a message. This is the intended private-recipient model, but it must be tested against the complete live policy set.
- The preview uploads an image, then inserts its attachment metadata. Cleanup after a failed metadata insert is best-effort, not a transactional guarantee. Test and plan orphan cleanup.

## Safe next actions (read-only first)
1. In Supabase, open each policy row and capture its complete name, command, target role, USING, and WITH CHECK expression. Do this for `profiles` and `messages`.
2. Search Storage policies for every policy on `storage.objects`, especially bucket `chat-images`; inspect full expressions. Also check whether the bucket is private and its server-side file size/MIME restrictions.
3. Inspect table columns, types, foreign keys, grants, and existing `message_attachments` table before choosing the attachment migration.
4. Only after that inventory, prepare a single reconciled migration for approval. No automatic policy deletion based on names or screenshots.
5. Test with three separate identities: sender, recipient, and unrelated third account. Verify sender/recipient access and third-party denial for messages, attachment metadata, and object downloads. Also test signed-out access and guessed object paths.

## Not done
- No SQL was run.
- No Supabase policy, bucket, Auth setting, table, or user record was changed.
- No live policy definitions were fetched from Supabase. The screenshot inventory is partial.
- No two-account or image upload/download test was run.
- `main/index.html` remains untouched; all repository work remains on the preview branch.
