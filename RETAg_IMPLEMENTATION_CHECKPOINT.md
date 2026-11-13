# Retag Chat — implementation checkpoint

Updated: 2026-11-13

## Current repository state
- `index.html` is a browser-only prototype. Its chat/profile/theme data is stored in browser localStorage.
- The current page does not initialize the Supabase client and has no real sign-up/sign-in flow.
- The visible AI, calls, updates, communities, and several chat controls are prototype UI, not connected services.
- `supabase_setup.sql` enables RLS, creates message/profile policies, creates a private `chat-images` bucket, and adds messages to Realtime.
- `accounts_setup.sql` adds optional, non-unique `profiles.contact_phone`. Authentication identity is intended to be email + password.

## Safety issues to resolve before enabling accounts
1. The current prototype stores chat/profile data in shared localStorage keys. Simply adding login would risk showing one account's local demo data to another account on the same browser. Data must be isolated per authenticated user or migrated to Supabase first.
2. The current image Storage SELECT policy only permits the uploader's own UID folder. A recipient cannot read a private image merely because it was sent to them. A secure recipient authorization design is required before image sharing is enabled.
3. The messages table currently supports text fields, but image metadata, delivery/read states, reactions, edits, deletes, and one-time media need explicit schema and authorization design.
4. View-once media and screenshot prevention cannot be guaranteed in a browser. One-time access must be enforced server-side; native Android screenshot protections can only reduce ordinary capture, not prevent external-camera capture.

## Agreed account model
- Supabase Auth email + password.
- Optional `contact_phone` stored on the profile and deliberately non-unique, so separate accounts may list the same contact number.
- Signing into the same account on another device uses that account's email/password (plus optional MFA).
- A phone number shared as contact information is not itself a shared login credential.

## Implementation order
1. Verify Supabase project is active and confirm the actual schema/policies without exposing secret keys.
2. Add and test account registration, login, logout, session restore, profile upsert, and per-account local-data isolation.
3. Move conversations/messages to Supabase with strict sender/recipient RLS and Realtime.
4. Implement private image upload and recipient-only access; then delivery/read metadata.
5. Build Stories, Channels, Groups, Calls, Streaks, Memories, Mood, Themes, and AI as separate tested modules.
6. Run multi-account and multi-device tests before packaging Android.

## Do not do yet
- Do not replace the live `index.html` with a login gate until Supabase is active and per-account data isolation is implemented.
- Do not make the image bucket public or weaken RLS to make image display appear to work.
- Do not add a service-role key or any secret key to browser code.
