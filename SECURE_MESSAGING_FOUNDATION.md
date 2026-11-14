# Retag Chat — secure two-account messaging foundation

## Current repository state
- Work is isolated on `feature/account-auth-preview`; the branch is 20 commits ahead of `main` and has no commits behind it at review time.
- `index.html` is byte-for-byte unchanged between `main` and this branch (same blob SHA at review time).
- `account_preview.html` uses the shared Supabase Auth helper for email/password signup, login, session restore, and sign-out. It stores the display name in Auth metadata; it does not itself create a `public.profiles` row.
- `messages_preview.html` sends text using the signed-in user's ID as `sender_id`, and scopes reads to the two participants. The recipient UUID is entered manually for testing.
- `attachments_preview.html` uploads to the private `chat-images` bucket under the uploader UID folder, registers metadata in `public.message_attachments`, then downloads through the authenticated Storage SDK. It does not create public URLs.

## RLS and Storage review

### Profiles
The repository's `supabase_setup.sql` allows every authenticated user to read every profile row (`using (true)`). That can expose every selected column, including optional contact information. Use a deliberately public profile shape and keep phone/contact fields private.

### Messages
- SELECT by sender or receiver is the correct one-to-one baseline.
- INSERT currently checks only `sender_id = auth.uid()`. It does not enforce a real receiver or reject self-messaging. Add server-side receiver validation and a database-level relationship/constraint after checking the live schema.
- UPDATE currently permits the sender to update the whole row. That can include `receiver_id` and `created_at`; remove broad update access or expose only a constrained edit operation.
- DELETE currently permits the sender to delete their row. Decide whether deletion means delete-for-everyone or delete-for-me before exposing it in the UI.

### Private image attachments
Preferred design: `message_attachments_setup.sql`.
1. Keep `chat-images` private; store objects at `<sender-auth-uid>/<random-id>.<extension>`.
2. Store metadata in `message_attachments`, including message ID, uploader ID, path, MIME label, and byte size.
3. Let only the sender create an attachment record for their own sent message.
4. Let only the sender/recipient read metadata for that message.
5. Let the uploader read their own folder; let the other participant download only an object whose exact path is linked to a message in which they participate.
6. Download with the authenticated Storage SDK; never use a public bucket or permanent public URL.

The draft's `byte_size` check is not enough by itself because the client submits that value. The live bucket must also enforce an appropriate server-side file-size limit and allowed MIME types. Confirm these settings rather than assuming they exist.

### Conflicting/legacy image draft
`message_images_setup.sql` is an older alternative that stores one `attachment_path` directly on `messages`. Do not apply it together with the normalized `message_attachments_setup.sql` design. Its Storage SELECT policy is a separate authorization path and can remain active alongside other permissive policies.

### Critical RLS rule
Supabase permissive policies combine with OR. Dropping one named policy does not remove unnamed or legacy policies. Before any migration, inventory every policy and table grant on `profiles`, `messages`, `message_attachments`, and `storage.objects`.

## Tests required before integration
1. Account A sends to B; B reads and replies; A receives via Realtime.
2. Account C cannot read A↔B messages or download their image by guessing a path.
3. A sender can upload/read their own image; B can read only after it is linked to an A↔B message.
4. Signed-out access, self-message, invalid/nonexistent receiver, unsupported MIME, and oversized upload are denied.
5. Account switching/sign-out clears old conversation text and temporary image URLs.
6. A partial image send is cleaned up; failed cleanup is recorded for manual repair.

## Verification boundary
Repository files were retrieved and reviewed. Inline JavaScript syntax checks passed for the account, messaging, attachment, and contacts previews plus the shared auth helper. Static checks also confirmed that the attachment preview uses private Storage downloads and does not call `getPublicUrl` or contain a service-role credential.

No live Supabase dashboard/API access was available for this review. Therefore the deployed schema, actual bucket privacy/limits, Auth confirmation settings, effective RLS policies/grants, Realtime publication, and two-account behavior remain unverified. No SQL was executed and no Supabase settings or user data were changed.
