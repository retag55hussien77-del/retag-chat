# Retag Chat — private image attachments preview

## Added
- `attachments_preview.html` is a separate test page; it does not replace or edit `index.html`.
- Reuses the shared `retag-auth.js` Supabase Auth client.
- Allows the tester to select an image and send it with a message to another Auth UUID.
- Client-side checks allow JPEG, PNG, WEBP, GIF and reject empty files or files larger than 10 MiB.
- Uploads to the existing private `chat-images` bucket under the signed-in user's UUID folder with a random object name.
- Inserts attachment metadata into `public.message_attachments`.
- Reads attachment metadata for conversation messages, then downloads through the authenticated Storage SDK and displays a temporary browser object URL.
- Does not create public URLs or change the bucket to public.
- Includes Realtime listeners for messages and attachment metadata.
- Clears rendered messages and temporary image URLs on account change/sign-out; ignores stale asynchronous renders from a prior account.
- Attempts best-effort cleanup of the uploaded object and an image-only placeholder message if image attachment registration fails.

## Important prerequisites
- The existing `message_attachments_setup.sql` is a review draft only and has NOT been executed.
- The live private bucket, exact messages schema, and all current RLS policies must be verified before testing.
- Existing permissive policies may OR together and broaden access; audit all policies, not just the newly named ones.
- Browser file checks are usability checks, not a replacement for server-side Storage limits and database constraints.
- Cleanup after a partial send is best-effort; if Storage deletion or message deletion is denied/fails, a manual orphan cleanup may still be needed.
- This page is a technical preview, not a production-ready attachment system.

## Verification status
- Repository file and references are statically reviewed.
- No live Supabase login, database, Storage upload/download, recipient access, or Realtime test has been performed.
- No SQL was run and no Supabase setting, user, or live app file was changed.
- The main `index.html` remains untouched.
