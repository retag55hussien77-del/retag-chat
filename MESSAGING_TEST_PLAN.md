# Retag Chat — two-account messaging test plan

This checklist is for the isolated `messages_preview.html` page on `feature/account-auth-preview`. It is not evidence that the live Supabase project has passed these tests.

## Preconditions
- Two separate Supabase Auth accounts exist and can sign in.
- Both accounts have confirmed email if the project requires confirmation.
- The tester has each account's Auth UUID.
- The live `public.messages` table contains the expected columns: `id`, `sender_id`, `receiver_id`, `content`, `created_at`.
- Live RLS policies allow an authenticated user to select rows where they are sender or receiver and insert only rows with their own Auth UUID as sender.
- Realtime is enabled for `public.messages`.

## Required tests
1. Signed-out visitor cannot load or send a conversation.
2. Account A loads a conversation with Account B's UUID.
3. Account A sends a unique test message; it appears once in A's conversation.
4. Account B signs in and sees the same message.
5. Account B replies; Account A sees the reply without manually reloading after Realtime is confirmed.
6. A third account C cannot read A↔B messages by entering either UUID.
7. A signed-in user cannot send a message with another user's sender UUID (the preview does not expose this field; verify RLS separately).
8. Invalid UUID, same-account UUID, empty message, and over-limit message are rejected or safely handled.
9. Sign-out clears the active session and disables composing.
10. Browser refresh restores the signed-in session without duplicating Realtime subscriptions.

## Record results
For each test, record Pass / Fail / Not tested, the two account roles involved, and the exact non-secret error message. Never share passwords, access tokens, refresh tokens, or service-role credentials.

## Current status
- Code and repository wiring have been checked statically.
- No live Supabase authentication, database insert/select, Realtime delivery, or third-account isolation test has been run.
- Do not treat the preview as production-ready until all required tests pass and the complete set of live RLS policies has been audited.
