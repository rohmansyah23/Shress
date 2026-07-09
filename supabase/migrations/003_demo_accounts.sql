-- ============================================================
-- SSRS Finance - Demo Accounts Migration
-- Description: Creates demo user accounts for testing
-- ============================================================

SET search_path TO public, extensions;

-- 1. DEMO USERS
-- ============================================================
-- Supabase Auth memproses login lewat schema auth.users.
-- Untuk akun demo, gunakan insert yang kompatibel dengan auth flow dan
-- isi metadata user untuk sinkronisasi ke public.users.

INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES
  (
    'd0000000-0000-0000-0000-000000000001',
    'owner@ssrs.com',
    crypt('password123', gen_salt('bf'::text)),
    now(),
    jsonb_build_object('username', 'owner_ssrs', 'display_name', 'Owner SSRS', 'role', 'owner'),
    now(),
    now()
  ),
  (
    'd0000000-0000-0000-0000-000000000002',
    'manager@ssrs.com',
    crypt('password123', gen_salt('bf'::text)),
    now(),
    jsonb_build_object('username', 'manager_ssrs', 'display_name', 'Manager SSRS', 'role', 'manager'),
    now(),
    now()
  ),
  (
    'd0000000-0000-0000-0000-000000000003',
    'staff@ssrs.com',
    crypt('password123', gen_salt('bf'::text)),
    now(),
    jsonb_build_object('username', 'staff_ssrs', 'display_name', 'Staff SSRS', 'role', 'staff'),
    now(),
    now()
  )
ON CONFLICT (id) DO NOTHING;

-- Pastikan profile publik juga ada untuk setiap akun demo.
INSERT INTO public.users (id, email, username, display_name, role, is_active)
SELECT
  u.id,
  u.email,
  COALESCE(u.raw_user_meta_data->>'username', split_part(u.email, '@', 1)),
  COALESCE(u.raw_user_meta_data->>'display_name', split_part(u.email, '@', 1)),
  COALESCE(u.raw_user_meta_data->>'role', 'staff'),
  true
FROM auth.users u
WHERE u.email IN ('owner@ssrs.com', 'manager@ssrs.com', 'staff@ssrs.com')
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  username = EXCLUDED.username,
  display_name = EXCLUDED.display_name,
  role = EXCLUDED.role,
  is_active = true;

-- ============================================================
-- 2. ASSIGN DEMO USERS TO BUSINESSES
-- ============================================================
-- Owner: access to all businesses
-- Manager: access to Agen Minuman Alkali & Teh Solo
-- Staff: access to Warung Kopi only

INSERT INTO public.user_businesses (user_id, business_id)
SELECT demo.user_id, b.id
FROM (VALUES
  ('d0000000-0000-0000-0000-000000000001'::uuid, 'Agen Minuman Alkali'),
  ('d0000000-0000-0000-0000-000000000001'::uuid, 'Teh Solo'),
  ('d0000000-0000-0000-0000-000000000001'::uuid, 'Warung Kopi'),
  ('d0000000-0000-0000-0000-000000000002'::uuid, 'Agen Minuman Alkali'),
  ('d0000000-0000-0000-0000-000000000002'::uuid, 'Teh Solo'),
  ('d0000000-0000-0000-0000-000000000003'::uuid, 'Warung Kopi')
) AS demo(user_id, business_name)
JOIN public.businesses b ON b.name = demo.business_name
ON CONFLICT (user_id, business_id) DO NOTHING;
