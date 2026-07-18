-- ============================================================
-- Fix: Session version increment saat ganti password
-- + Force logout functions (admin only)
-- ============================================================

-- 1. Fix: password change harus invalidate semua sesi aktif
CREATE OR REPLACE FUNCTION public.update_public_user_password(
  p_user_id uuid, p_new_password text
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.users
  SET password_hash = extensions.crypt(p_new_password, extensions.gen_salt('bf')),
      session_version = session_version + 1,
      updated_at = now()
  WHERE id = p_user_id;
END;
$$;

-- 2. Force logout SEMUA user (untuk deploy besar / vulnerability patch)
CREATE OR REPLACE FUNCTION public.force_logout_all_users()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.users
  SET session_version = session_version + 1;
END;
$$;

-- 3. Force logout SATU user (device hilang / user dipecat)
CREATE OR REPLACE FUNCTION public.force_logout_user(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.users
  SET session_version = session_version + 1
  WHERE id = p_user_id;
END;
$$;

-- Grant ke authenticated (authorization di-layer Dart/app)
GRANT EXECUTE ON FUNCTION public.force_logout_all_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.force_logout_user(uuid) TO authenticated;
