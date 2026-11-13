# Retag Chat — account integration progress

## Added on `feature/account-auth-preview`
- `retag-auth.js`: shared Supabase Auth client for sign-up, email/password sign-in, sign-out, session restore, and auth-state subscription.
- `account_preview.html`: now loads the shared client instead of creating a second client inline.

## Safety boundaries
- Uses the existing Supabase publishable key only; no service-role key is included.
- This helper performs Auth operations only. It does not read or write `profiles`, `messages`, Storage objects, or user records.
- `main/index.html` was not changed. The main app is still a local/demo interface and is not yet protected by an account login gate.
- No SQL was executed and no Supabase dashboard settings or live user data were changed.

## Checks completed
- Retrieved the new helper and updated preview from the branch after committing.
- Confirmed the Supabase JS v2 CDN script loads before `retag-auth.js`.
- Confirmed the preview uses the shared helper for sign-up, sign-in, sign-out, and session restore.
- Ran `node --check` successfully on the shared helper.

## Not yet verified
- No live sign-up/sign-in test was run against Supabase.
- Email-confirmation behavior still depends on the project's live Auth settings.
- The shared helper is not yet wired into `index.html`; that integration remains a separate protected change after review.
