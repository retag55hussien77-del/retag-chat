-- Retag Chat account foundation
-- Safe, additive migration: does not delete users, profiles, or messages.
-- Sign-in identity will be email + password through Supabase Auth.
-- contact_phone is optional profile/contact information, NOT a login identifier.
-- It is intentionally not unique, so separate accounts may share the same contact number.

alter table public.profiles
  add column if not exists contact_phone text;

create index if not exists profiles_contact_phone_idx
  on public.profiles (contact_phone)
  where contact_phone is not null;

comment on column public.profiles.contact_phone is
  'Optional contact number. Not unique; multiple independent accounts may share it. Do not use it as an authentication credential.';
