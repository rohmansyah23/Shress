-- ============================================================
-- 009_insert_demo_users.sql
-- Insert demo users directly into public.users with password_hash
-- since we are bypassing auth.users schema
-- ============================================================

INSERT INTO public.users (id, email, username, display_name, role, password_hash, is_active)
VALUES
  (
    'd0000000-0000-0000-0000-000000000001',
    'owner@ssrs.com',
    'owner_sheress',
    'Owner Sheress',
    'owner',
    extensions.crypt('password123', extensions.gen_salt('bf')),
    true
  ),
  (
    'd0000000-0000-0000-0000-000000000002',
    'manager@ssrs.com',
    'manager_sheress',
    'Manager Sheress',
    'manager',
    extensions.crypt('password123', extensions.gen_salt('bf')),
    true
  ),
  (
    'd0000000-0000-0000-0000-000000000003',
    'staff@ssrs.com',
    'staff_sheress',
    'Staff Sheress',
    'staff',
    extensions.crypt('password123', extensions.gen_salt('bf')),
    true
  )
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  username = EXCLUDED.username,
  display_name = EXCLUDED.display_name,
  role = EXCLUDED.role,
  password_hash = COALESCE(EXCLUDED.password_hash, public.users.password_hash),
  is_active = true;
