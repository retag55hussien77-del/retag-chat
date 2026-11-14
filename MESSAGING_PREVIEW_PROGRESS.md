# Retag Chat — messaging preview progress

## Added
- `messages_preview.html` on `feature/account-auth-preview`.
- It reuses `retag-auth.js` and requires an existing signed-in Supabase session.
- It lets a tester enter the other account's Auth UUID, load the two-person conversation, send text messages, and listen for Realtime changes.
- Clears the displayed conversation on account change/sign-out and ignores stale loads or Realtime callbacks from the prior session.
- Message text is rendered with `textContent`, not HTML insertion.
- Sender ID is always taken from the active authenticated session, never from a user-editable field.

## Scope and assumptions
- This is an isolated preview page; `index.html` is not changed.
- It assumes the repository's documented `public.messages` columns: `id`, `sender_id`, `receiver_id`, `content`, `created_at`.
- It assumes the messages table is enabled for Supabase Realtime and that the live project has compatible SELECT and INSERT RLS policies.
- The recipient UUID is entered manually for testing because the current repository profile policy/data do not provide a verified contact directory.
- Image attachments are intentionally not implemented in this preview.

## Security notes
- The browser sets `sender_id` from the current session. Existing server-side RLS remains the actual security boundary.
- The current repository SQL's INSERT policy checks only `sender_id = auth.uid()`; it does not verify that the receiver exists or apply any recipient restrictions. Client-side UUID validation is not a security control.
- Existing permissive RLS policies are OR-combined. Audit all live policies before relying on these previews.
- No service-role key is used.
- No SQL was executed; no Supabase settings, storage buckets, or user data were changed.

## Checks performed
- Retrieved the committed preview from the branch and checked key implementation conditions: session required, sender tied to authenticated user, recipient UUID validation, safe text rendering, stable Realtime subscription, no service-role credential.
- Realtime, authentication, and actual message delivery have NOT been tested against the live Supabase project.
- Two-account testing is still required before integration into the main app.
