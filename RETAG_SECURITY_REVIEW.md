# Retag Chat — secure messaging and attachment review

## Scope and evidence
Reviewed the isolated branch `feature/account-auth-preview`, its `account_preview.html`, and repository SQL files `supabase_setup.sql` and `accounts_setup.sql`. This is a repository review only. No live Supabase dashboard/API connection is available in this run, so current deployed schema, Auth settings, Storage policies, and Realtime publication were not independently verified.

## Account preview
- Uses Supabase JS v2 with the project's URL and a publishable browser key.
- Implements email/password signup, sign-in, session restore, and sign-out.
- Does not use a service-role key.
- Does not yet create/sync a row in `public.profiles`; display_name is only Auth user metadata.
- Confirmation-email behavior depends on the project's live Auth settings.
- This page is a prototype and is not integrated into `index.html`. Do not treat it as production-ready until tested against the live project and reviewed for account/session isolation.

## Current SQL policy findings
- `profiles`: every authenticated user can select every profile (`using (true)`). This may be intentional for contact discovery, but it exposes all profile columns, including bio/contact fields if present. Prefer a limited public profile view or explicit column-safe design; do not expose private contact data by default.
- `profiles`: insert/update constrain the row id to `auth.uid()`, which is a good ownership baseline. Column-level permissions and any other existing policies still need a live audit.
- `messages`: select permits either participant, a sound baseline for one-to-one chats.
- `messages`: insert checks only `sender_id = auth.uid()`. It does not prove the receiver is a valid/allowed account, nor validate message type/content/size. Add server-side validation and check any existing policies.
- `messages`: sender update policy allows the sender to update any columns on their own message, potentially including receiver_id and created_at. Restrict editable columns or use a narrowly scoped RPC/trigger for edits.
- `messages`: sender delete policy permits deleting own rows. Confirm desired delete-for-everyone vs delete-for-me semantics before building UI.
- Storage bucket `chat-images` is configured private. Upload/delete are restricted to objects whose first path folder equals the uploader UID.
- Existing Storage SELECT policy uses the same uploader-folder check. Therefore, a recipient cannot read the sender's private image object under the current policy. Making the bucket public is not an acceptable fix.
- RLS policies are permissive by default and combine with OR. Existing older policies with different names can silently widen access. The repository script only drops its own exact policy names; live policy inventory is mandatory before any migration.

## Proposed recipient-safe image design
Draft migration: `message_attachments_setup.sql`.
- Keep `chat-images` private and keep uploads under `<sender-uid>/<random-object-id>.<extension>`.
- Store attachment metadata in `public.message_attachments`, linked to the message row.
- Attachment metadata SELECT checks that the signed-in user is the sender or receiver of the linked message.
- Storage SELECT permits the uploader's own folder and, for other users, only an object whose path is registered against a message in which they are a participant.
- Upload remains uploader-only; attachment metadata can only be inserted by the authenticated sender for their own message.
- Client downloads with the authenticated Supabase Storage SDK; do not persist public URLs.
- Draft has preflight assertions for the expected messages schema and private bucket. It is a proposal only and has not been run.

## Before any live SQL execution
1. Export/list all current policies for `public.profiles`, `public.messages`, `public.message_attachments`, and `storage.objects`; inspect duplicate/broad legacy policies.
2. Verify actual column types, foreign keys, bucket id/privacy, Auth user state, and grants.
3. Decide profile discoverability and which profile fields may be visible.
4. Decide message edit/delete semantics and constrain update permissions.
5. Test with two separate test accounts: sender can upload/read; receiver can read only after attachment is linked; unrelated third account is denied; unauthenticated access is denied; guessing another object path is denied.
6. Test oversized/unsupported files and orphan uploads. Add rate limits and server-side validation before public launch.

## Not done / needs live testing
- No Supabase SQL was executed and no dashboard settings/data were changed.
- Auth signup confirmation, login, logout, and session persistence have not been exercised against the live project.
- Realtime delivery between two users has not been tested.
- Private image download by the recipient has not been tested.
- No changes were made to `main` or `index.html`.
