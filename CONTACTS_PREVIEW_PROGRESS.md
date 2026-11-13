# Retag Chat — Contacts Preview Progress

## Added
- `contacts_preview.html` is a separate experimental page for creating/updating the signed-in user's profile and browsing profiles.
- Profile fields used: `id`, `username`, `display_name`, and `bio`.
- Directory search filters the retrieved profile names, usernames, and bios in the browser.
- Selecting a profile opens `messages_preview.html?to=<profile-id>`.
- `messages_preview.html` now reads a valid UUID from the `to` query parameter and pre-fills the recipient field.
- The page does not read the phone address book, phone numbers, or email addresses of other users.

## Important assumptions and limitations
- Assumes `public.profiles` exists with columns `id uuid`, `username text`, `display_name text`, `bio text`, and `avatar_url text`, as previously described for this project.
- Assumes authenticated users can SELECT profile rows and can INSERT/UPDATE only their own row under RLS.
- A user appears in the directory only after they have created a profile row. The signup helper does not automatically create one; each account must save its profile once.
- Username format is checked in the browser, but uniqueness is NOT guaranteed. Add and verify a database UNIQUE constraint before treating usernames as unique identifiers.
- The directory reads up to 200 profiles. This is a small-project preview, not a scalable paginated contacts system.
- Existing broad profile SELECT policy means all authenticated users may read the selected public profile fields. Review whether bio/avatar should be visible to every signed-in user before production.
- This is account discovery, not phone-contact matching. Phone-number discovery would require a separately designed consent/privacy model.

## Verification status
- Static source review only. No live Supabase login, profile insert/update, directory query, or conversation launch was tested.
- No SQL was executed. No Supabase settings or user data were changed.
- `main/index.html` remains untouched; all work is on `feature/account-auth-preview`.

## Manual test needed later
1. Sign in with account A and save a profile.
2. Sign in with account B and save a profile.
3. Confirm each account appears in the other's directory.
4. Select the other account and verify the conversation page opens with its recipient UUID filled in.
5. Confirm RLS blocks editing another user's profile.
