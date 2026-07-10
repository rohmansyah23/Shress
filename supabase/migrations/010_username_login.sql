-- ============================================================
-- 010_username_login.sql
-- Allow login using email OR username
-- ============================================================

-- Index username for fast lookup
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);

-- Modify RPC to accept email or username
DROP FUNCTION IF EXISTS public.verify_public_password(text, text);

CREATE FUNCTION public.verify_public_password(
  p_identifier text,
  p_password text
)
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path TO public, extensions
AS $$
  SELECT id FROM public.users
  WHERE (email = p_identifier OR username = p_identifier)
    AND password_hash IS NOT NULL
    AND crypt(p_password, password_hash) = password_hash
  LIMIT 1;
$$;
