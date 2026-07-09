-- ============================================================
-- 004_public_passwords.sql
-- Add password_hash to public.users, populate demo hashes, create verifier
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS password_hash varchar(200);

-- Populate demo users with bcrypt hashes (password: password123)
-- Note: pgcrypto functions are in the 'extensions' schema on Supabase
UPDATE public.users
SET password_hash = extensions.crypt('password123', extensions.gen_salt('bf'))
WHERE email IN ('owner@ssrs.com','manager@ssrs.com','staff@ssrs.com');

-- RPC to verify password against the stored bcrypt hash in public.users
CREATE OR REPLACE FUNCTION public.verify_public_password(p_email text, p_password text)
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path TO public, extensions
AS $$
  SELECT id FROM public.users
  WHERE email = p_email
    AND password_hash IS NOT NULL
    AND crypt(p_password, password_hash) = password_hash
  LIMIT 1;
$$;
