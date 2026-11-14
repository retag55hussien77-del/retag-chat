# Retag Chat — profile and settings preview progress

## Added on `feature/account-auth-preview`
- `settings_preview.html`: isolated Arabic RTL profile/settings preview using the shared `retag-auth.js` helper.
- Profile fields load from `public.profiles` for the signed-in user: `display_name`, `username`, and `bio`.
- The profile save action is explicit and only writes the signed-in user's own row after the user presses Save; it checks whether the row exists before update/insert.
- Settings sections prepared: account, privacy, chats, appearance, notifications, storage/data, and linked devices.
- Demo switches are clearly marked as preview-only and do not persist or change database policies/settings.
- Avatar upload is intentionally deferred until Storage bucket and access policies are reviewed.

## Not implemented / not verified
- No live browser test, profile save test, avatar upload, push notification, linked-device management, privacy preference persistence, backup, or device-level settings test was run.
- Profile save depends on the live `profiles` schema and the signed-in user's INSERT/UPDATE RLS policies.
- Username uniqueness is not guaranteed by this preview; a database unique constraint must be reviewed before treating handles as unique.
- Remaining settings are presentation-only placeholders until their secure data model and platform behavior are designed.

## Safety and scope
- Only this preview and its progress note were added to `feature/account-auth-preview`.
- `main/index.html` was not changed.
- No SQL, Supabase settings, Storage policies, or live user data were changed by preparing this page.
- No service-role key is used.
