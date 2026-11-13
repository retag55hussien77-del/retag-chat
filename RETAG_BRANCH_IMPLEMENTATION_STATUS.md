# Retag Chat — Branch Implementation Status

This document describes prepared preview work only. It is not a production-readiness approval.

## Prepared on `feature/account-auth-preview`
- Shared Supabase Auth helper: `retag-auth.js`
- Account signup/login preview: `account_preview.html`
- Two-account text messaging and Realtime preview: `messages_preview.html`
- Private image attachment preview: `attachments_preview.html`
- Contacts/profile directory preview: `contacts_preview.html`
- Review-only SQL drafts: `supabase_setup.sql`, `accounts_setup.sql`, and `message_attachments_setup.sql`
- Security and progress notes: `RETAG_SECURITY_REVIEW.md`, `ACCOUNT_AUTH_PROGRESS.md`, `MESSAGING_PREVIEW_PROGRESS.md`, `CONTACTS_PREVIEW_PROGRESS.md`

## Not completed / not verified
- No live Supabase project inspection was available in this work session.
- No SQL migration was executed.
- No live account creation, profile save, directory lookup, two-user messaging, Realtime delivery, image upload, or recipient image download was tested.
- The live Storage bucket and all effective RLS policies must be audited; permissive policies can combine and unintentionally widen access.
- Usernames need a database uniqueness constraint before being relied on as unique handles.
- Contacts currently means discovering users who have created a profile; it does not match the phone address book.
- Images require the reviewed attachment table and recipient-safe private Storage policies to be applied only after live schema/policy review.
- Voice/video calls, status updates, groups, push notifications, app packaging, and Google Play release are not implemented.

## Protected scope
- All preview additions and edits are on `feature/account-auth-preview`.
- The production `main/index.html` has not been changed.
- No Supabase settings, live database schema, or user records were changed.
- No secret/service-role key is included in the frontend.

## Next safe sequence
1. Inspect the actual Supabase schema, bucket privacy, and every effective RLS policy.
2. Reconcile and test the SQL drafts against that live inventory before any execution.
3. Test two real accounts: profile save, discovery, text send/receive, and Realtime.
4. Apply the recipient-safe image migration only after approval and then test both upload and download.
5. Add remaining features incrementally, then integrate into the main app after acceptance tests.
6. Prepare Android packaging and Google Play release only after the production app is complete and security-tested.
