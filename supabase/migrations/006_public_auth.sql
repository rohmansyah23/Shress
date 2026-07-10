-- ============================================================
-- 006_public_auth.sql
-- Disable Row Level Security on all tables to allow public login & CRUD
-- and provide RPC functions for creating users and updating passwords
-- ============================================================

-- Disable Row Level Security on all tables
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_businesses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_reports DISABLE ROW LEVEL SECURITY;

-- RPC to create a new user directly in public.users with hashed password
CREATE OR REPLACE FUNCTION public.create_public_user(
  p_email text,
  p_username text,
  p_role text,
  p_password text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := gen_random_uuid();
  INSERT INTO public.users (id, email, username, role, password_hash)
  VALUES (
    v_user_id,
    p_email,
    p_username,
    p_role,
    extensions.crypt(p_password, extensions.gen_salt('bf'))
  );
  RETURN v_user_id;
END;
$$;

-- RPC to update user password directly in public.users
CREATE OR REPLACE FUNCTION public.update_public_user_password(
  p_user_id uuid,
  p_new_password text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.users
  SET password_hash = extensions.crypt(p_new_password, extensions.gen_salt('bf')),
      updated_at = now()
  WHERE id = p_user_id;
END;
$$;
