-- ============================================================
-- Sheress - Initial Schema Migration (v2)
-- Database: Supabase (PostgreSQL)
-- Description: Multi-tenant financial reporting system
-- Owner: Sheress
-- ============================================================

-- 0. EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. TABLES
-- ============================================================

-- 1a. Users (syncs with Supabase Auth)
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY, -- Matches Supabase Auth UID
  email varchar(255),
  username varchar(255) NOT NULL,
  display_name varchar(255),
  avatar_url varchar(500),
  role varchar(20) NOT NULL CHECK (role IN ('owner', 'manager', 'staff')),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 1b. Businesses
CREATE TABLE IF NOT EXISTS public.businesses (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name varchar(255) NOT NULL,
  description text,
  qris_image_url varchar(500),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 1c. User-Business Bridge (Many-to-Many)
CREATE TABLE IF NOT EXISTS public.user_businesses (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, business_id)
);

-- 1d. Categories (Income / Expense per business)
CREATE TABLE IF NOT EXISTS public.categories (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name varchar(255) NOT NULL,
  type varchar(20) NOT NULL CHECK (type IN ('income', 'expense')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 1e. Transactions
CREATE TABLE IF NOT EXISTS public.transactions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  category_id int NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type varchar(20) NOT NULL CHECK (type IN ('income', 'expense')),
  amount decimal(15,2) NOT NULL CHECK (amount >= 0),
  cogs decimal(15,2) NOT NULL DEFAULT 0.00 CHECK (cogs >= 0),
  payment_method varchar(50) NOT NULL DEFAULT 'cash' 
    CHECK (payment_method IN ('cash', 'transfer', 'qris', 'other')),
  description text,
  transaction_date date NOT NULL DEFAULT CURRENT_DATE,
  status_sync boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  -- Ensure COGS is only set for income transactions
  CONSTRAINT cogs_only_for_income CHECK (
    (type = 'income' AND cogs >= 0) OR (type = 'expense' AND cogs = 0.00)
  )
);

-- 1f. Financial Reports (pre-calculated snapshots per period)
CREATE TABLE IF NOT EXISTS public.financial_reports (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  period varchar(7) NOT NULL, -- YYYY-MM
  total_income decimal(15,2) NOT NULL DEFAULT 0.00,
  total_cogs decimal(15,2) NOT NULL DEFAULT 0.00,
  gross_profit decimal(15,2) NOT NULL DEFAULT 0.00,
  total_expense decimal(15,2) NOT NULL DEFAULT 0.00,
  net_profit decimal(15,2) NOT NULL DEFAULT 0.00,
  status varchar(10) NOT NULL CHECK (status IN ('laba', 'rugi')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, period)
);

-- ============================================================
-- 2. INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users(is_active);
CREATE INDEX IF NOT EXISTS idx_user_businesses_user_id ON public.user_businesses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_businesses_business_id ON public.user_businesses(business_id);
CREATE INDEX IF NOT EXISTS idx_categories_business_id ON public.categories(business_id);
CREATE INDEX IF NOT EXISTS idx_categories_type ON public.categories(type);
CREATE INDEX IF NOT EXISTS idx_transactions_business_id ON public.transactions(business_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_payment_method ON public.transactions(payment_method);
CREATE INDEX IF NOT EXISTS idx_transactions_sync ON public.transactions(status_sync) WHERE status_sync = false;

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_transactions_business_date 
  ON public.transactions(business_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_user_sync 
  ON public.transactions(user_id, status_sync) WHERE status_sync = false;

CREATE INDEX IF NOT EXISTS idx_financial_reports_business_period 
  ON public.financial_reports(business_id, period);

-- ============================================================
-- 3. TRIGGERS
-- ============================================================

-- 3a. Sync user on auth.users creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.users (id, email, username, display_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data ->> 'role', 'staff')
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    role = EXCLUDED.role,
    updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 3b. Sync email when auth.users email changes
CREATE OR REPLACE FUNCTION public.sync_user_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  UPDATE public.users SET 
    email = NEW.email,
    username = COALESCE(NEW.raw_user_meta_data ->> 'username', split_part(NEW.email, '@', 1))
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_update
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_user_email();

-- 3c. Trigger: sync updated_at timestamp
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_businesses_updated_at
  BEFORE UPDATE ON public.businesses
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_financial_reports_updated_at
  BEFORE UPDATE ON public.financial_reports
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_reports ENABLE ROW LEVEL SECURITY;

-- Helper function: get current user role
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS varchar
LANGUAGE sql
STABLE
SECURITY DEFINER SET search_path = ''
AS $$
  SELECT role FROM public.users WHERE id = auth.uid()
$$;

-- Helper function: check if user has access to a business
CREATE OR REPLACE FUNCTION public.user_has_business_access(target_business_id int)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_businesses
    WHERE user_id = auth.uid()
      AND business_id = target_business_id
  ) OR public.get_current_user_role() = 'owner'
$$;

-- ===== USERS table =====
-- Owner: can read all users; Manager/Staff: can only read own record
CREATE POLICY users_select_owner ON public.users
  FOR SELECT
  USING (
    public.get_current_user_role() = 'owner'
    OR id = auth.uid()
  );

-- Only owner can insert/update/delete users
CREATE POLICY users_insert_owner ON public.users
  FOR INSERT
  WITH CHECK (public.get_current_user_role() = 'owner');

CREATE POLICY users_update_owner ON public.users
  FOR UPDATE
  USING (public.get_current_user_role() = 'owner')
  WITH CHECK (public.get_current_user_role() = 'owner');

CREATE POLICY users_delete_owner ON public.users
  FOR DELETE
  USING (public.get_current_user_role() = 'owner');

-- ===== BUSINESSES table =====
-- Owner: can read all; Manager/Staff: only businesses they're assigned to
CREATE POLICY businesses_select ON public.businesses
  FOR SELECT
  USING (
    public.get_current_user_role() = 'owner'
    OR public.user_has_business_access(id)
  );

-- Only owner can modify businesses
CREATE POLICY businesses_insert ON public.businesses
  FOR INSERT
  WITH CHECK (public.get_current_user_role() = 'owner');

CREATE POLICY businesses_update ON public.businesses
  FOR UPDATE
  USING (public.get_current_user_role() = 'owner')
  WITH CHECK (public.get_current_user_role() = 'owner');

CREATE POLICY businesses_delete ON public.businesses
  FOR DELETE
  USING (public.get_current_user_role() = 'owner');

-- ===== USER_BUSINESSES table =====
-- Owner: full access; Manager/Staff: can read own assignments
CREATE POLICY user_businesses_select ON public.user_businesses
  FOR SELECT
  USING (
    public.get_current_user_role() = 'owner'
    OR user_id = auth.uid()
  );

-- Only owner can manage assignments
CREATE POLICY user_businesses_insert ON public.user_businesses
  FOR INSERT
  WITH CHECK (public.get_current_user_role() = 'owner');

-- Manager can assign staff to businesses they manage
CREATE POLICY user_businesses_insert_manager ON public.user_businesses
  FOR INSERT
  WITH CHECK (
    public.get_current_user_role() = 'manager'
    AND EXISTS (
      SELECT 1 FROM public.user_businesses ub2
      WHERE ub2.user_id = auth.uid() 
        AND ub2.business_id = business_id
    )
    AND EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = user_id AND u.role = 'staff'
    )
  );

CREATE POLICY user_businesses_update ON public.user_businesses
  FOR UPDATE
  USING (public.get_current_user_role() = 'owner')
  WITH CHECK (public.get_current_user_role() = 'owner');

CREATE POLICY user_businesses_delete ON public.user_businesses
  FOR DELETE
  USING (public.get_current_user_role() = 'owner');

-- ===== CATEGORIES table =====
-- Can read categories for accessible businesses
CREATE POLICY categories_select ON public.categories
  FOR SELECT
  USING (public.user_has_business_access(business_id));

-- Owner can manage categories
CREATE POLICY categories_insert ON public.categories
  FOR INSERT
  WITH CHECK (public.get_current_user_role() = 'owner');

CREATE POLICY categories_update ON public.categories
  FOR UPDATE
  USING (public.get_current_user_role() = 'owner')
  WITH CHECK (public.get_current_user_role() = 'owner');

CREATE POLICY categories_delete ON public.categories
  FOR DELETE
  USING (public.get_current_user_role() = 'owner');

-- ===== TRANSACTIONS table =====
-- Drop old policies to replace them
DROP POLICY IF EXISTS transactions_select ON public.transactions;
DROP POLICY IF EXISTS transactions_update ON public.transactions;
DROP POLICY IF EXISTS transactions_delete ON public.transactions;

-- Owner: can read all transactions across all businesses
CREATE POLICY transactions_select_owner ON public.transactions
  FOR SELECT
  USING (
    public.get_current_user_role() = 'owner'
  );

-- Manager: can read all transactions for accessible businesses
CREATE POLICY transactions_select_manager ON public.transactions
  FOR SELECT
  USING (
    public.get_current_user_role() = 'manager'
    AND public.user_has_business_access(business_id)
  );

-- Staff: can read all transactions for accessible businesses (not just own)
CREATE POLICY transactions_select_staff ON public.transactions
  FOR SELECT
  USING (
    public.get_current_user_role() = 'staff'
    AND public.user_has_business_access(business_id)
  );

-- Manager & Staff can insert transactions for their businesses; Owner can insert anywhere
CREATE POLICY transactions_insert ON public.transactions
  FOR INSERT
  WITH CHECK (
    public.user_has_business_access(business_id)
    AND user_id = auth.uid()
  );

-- All roles with business access can update any transaction in that business
CREATE POLICY transactions_update ON public.transactions
  FOR UPDATE
  USING (
    public.user_has_business_access(business_id)
  )
  WITH CHECK (
    public.user_has_business_access(business_id)
  );

-- All roles with business access can delete transactions in that business
CREATE POLICY transactions_delete ON public.transactions
  FOR DELETE
  USING (
    public.user_has_business_access(business_id)
  );

-- ===== FINANCIAL_REPORTS table =====
CREATE POLICY financial_reports_select ON public.financial_reports
  FOR SELECT
  USING (public.user_has_business_access(business_id));

-- Only owner can manage reports
CREATE POLICY financial_reports_insert ON public.financial_reports
  FOR INSERT
  WITH CHECK (public.get_current_user_role() = 'owner');

CREATE POLICY financial_reports_update ON public.financial_reports
  FOR UPDATE
  USING (public.get_current_user_role() = 'owner')
  WITH CHECK (public.get_current_user_role() = 'owner');

CREATE POLICY financial_reports_delete ON public.financial_reports
  FOR DELETE
  USING (public.get_current_user_role() = 'owner');

-- ============================================================
-- 5. SEED DATA
-- ============================================================

-- 5a. Default Businesses with QRIS image references
INSERT INTO public.businesses (name, description, qris_image_url) VALUES
  ('Agen Minuman Alkali', 'Sheress - Agen Minuman Alkali', 'assets/images/qris/business_1_qris.svg'),
  ('Teh Solo', 'Sheress - Teh Solo', 'assets/images/qris/business_2_qris.svg'),
  ('Warung Kopi', 'Sheress - Warung Kopi', 'assets/images/qris/business_3_qris.svg')
ON CONFLICT DO NOTHING;

-- 5b. Default Categories per business
DO $$
DECLARE
  b record;
BEGIN
  FOR b IN SELECT id, name FROM public.businesses LOOP
    
    -- Income categories
    INSERT INTO public.categories (business_id, name, type) VALUES
      (b.id, 'Penjualan Harian', 'income'),
      (b.id, 'Penjualan Grosir', 'income'),
      (b.id, 'Pendapatan Lain', 'income')
    ON CONFLICT DO NOTHING;
    
    -- Expense categories
    INSERT INTO public.categories (business_id, name, type) VALUES
      (b.id, 'Bahan Baku', 'expense'),
      (b.id, 'Operasional', 'expense'),
      (b.id, 'Gaji Karyawan', 'expense'),
      (b.id, 'Transportasi', 'expense'),
      (b.id, 'Lain-lain', 'expense')
    ON CONFLICT DO NOTHING;
    
  END LOOP;
END;
$$;

-- ============================================================
-- 6. FINANCIAL REPORT FUNCTIONS
-- ============================================================

-- 6a. Generate Financial Report for a specific period (YYYY-MM)
CREATE OR REPLACE FUNCTION public.generate_financial_report(
  p_business_id int,
  p_period varchar(7) -- YYYY-MM
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_total_income decimal(15,2) := 0;
  v_total_cogs decimal(15,2) := 0;
  v_gross_profit decimal(15,2) := 0;
  v_total_expense decimal(15,2) := 0;
  v_net_profit decimal(15,2) := 0;
  v_status varchar(10) := 'rugi';
  v_report_id int;
BEGIN
  -- Aggregate data for the period
  SELECT
    COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = 'income' THEN cogs ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0)
  INTO v_total_income, v_total_cogs, v_total_expense
  FROM public.transactions
  WHERE business_id = p_business_id
    AND to_char(transaction_date, 'YYYY-MM') = p_period;

  -- Calculate profits
  v_gross_profit := v_total_income - v_total_cogs;
  v_net_profit := v_gross_profit - v_total_expense;
  v_status := CASE WHEN v_net_profit >= 0 THEN 'laba' ELSE 'rugi' END;

  -- Upsert report
  INSERT INTO public.financial_reports (
    business_id, period,
    total_income, total_cogs, gross_profit,
    total_expense, net_profit, status
  ) VALUES (
    p_business_id, p_period,
    v_total_income, v_total_cogs, v_gross_profit,
    v_total_expense, v_net_profit, v_status
  )
  ON CONFLICT (business_id, period)
  DO UPDATE SET
    total_income = EXCLUDED.total_income,
    total_cogs = EXCLUDED.total_cogs,
    gross_profit = EXCLUDED.gross_profit,
    total_expense = EXCLUDED.total_expense,
    net_profit = EXCLUDED.net_profit,
    status = EXCLUDED.status,
    updated_at = now()
  RETURNING id INTO v_report_id;

  RETURN jsonb_build_object(
    'report_id', v_report_id,
    'total_income', v_total_income,
    'total_cogs', v_total_cogs,
    'gross_profit', v_gross_profit,
    'total_expense', v_total_expense,
    'net_profit', v_net_profit,
    'status', v_status
  );
END;
$$;

-- 6b. Generate Financial Report for a custom date range
CREATE OR REPLACE FUNCTION public.generate_financial_report_range(
  p_business_id int,
  p_start_date date,
  p_end_date date
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_total_income decimal(15,2) := 0;
  v_total_cogs decimal(15,2) := 0;
  v_gross_profit decimal(15,2) := 0;
  v_total_expense decimal(15,2) := 0;
  v_net_profit decimal(15,2) := 0;
  v_status varchar(10) := 'rugi';
BEGIN
  -- Aggregate data for the date range
  SELECT
    COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = 'income' THEN cogs ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0)
  INTO v_total_income, v_total_cogs, v_total_expense
  FROM public.transactions
  WHERE business_id = p_business_id
    AND transaction_date >= p_start_date
    AND transaction_date <= p_end_date;

  -- Calculate profits
  v_gross_profit := v_total_income - v_total_cogs;
  v_net_profit := v_gross_profit - v_total_expense;
  v_status := CASE WHEN v_net_profit >= 0 THEN 'laba' ELSE 'rugi' END;

  RETURN jsonb_build_object(
    'start_date', p_start_date,
    'end_date', p_end_date,
    'total_income', v_total_income,
    'total_cogs', v_total_cogs,
    'gross_profit', v_gross_profit,
    'total_expense', v_total_expense,
    'net_profit', v_net_profit,
    'status', v_status
  );
END;
$$;

-- 6c. Compare two financial periods (Month-over-Month)
CREATE OR REPLACE FUNCTION public.compare_financial_periods(
  p_business_id int,
  p_period_1 varchar(7), -- YYYY-MM
  p_period_2 varchar(7)  -- YYYY-MM
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  r1 jsonb;
  r2 jsonb;
  v_income_change decimal(15,2);
  v_net_profit_change decimal(15,2);
  v_income_change_pct decimal(5,2);
  v_net_profit_change_pct decimal(5,2);
BEGIN
  -- Get reports for both periods
  r1 := public.generate_financial_report(p_business_id, p_period_1);
  r2 := public.generate_financial_report(p_business_id, p_period_2);

  -- Calculate changes
  v_income_change := (r2 ->> 'total_income')::decimal(15,2) - (r1 ->> 'total_income')::decimal(15,2);
  v_net_profit_change := (r2 ->> 'net_profit')::decimal(15,2) - (r1 ->> 'net_profit')::decimal(15,2);
  
  -- Calculate percentage changes (avoid division by zero)
  IF (r1 ->> 'total_income')::decimal(15,2) != 0 THEN
    v_income_change_pct := (v_income_change / (r1 ->> 'total_income')::decimal(15,2)) * 100;
  ELSE
    v_income_change_pct := 0;
  END IF;
  
  IF (r1 ->> 'net_profit')::decimal(15,2) != 0 THEN
    v_net_profit_change_pct := (v_net_profit_change / (r1 ->> 'net_profit')::decimal(15,2)) * 100;
  ELSE
    v_net_profit_change_pct := 0;
  END IF;

  RETURN jsonb_build_object(
    'period_1', jsonb_build_object(
      'period', p_period_1,
      'total_income', r1 ->> 'total_income',
      'total_cogs', r1 ->> 'total_cogs',
      'gross_profit', r1 ->> 'gross_profit',
      'total_expense', r1 ->> 'total_expense',
      'net_profit', r1 ->> 'net_profit',
      'status', r1 ->> 'status'
    ),
    'period_2', jsonb_build_object(
      'period', p_period_2,
      'total_income', r2 ->> 'total_income',
      'total_cogs', r2 ->> 'total_cogs',
      'gross_profit', r2 ->> 'gross_profit',
      'total_expense', r2 ->> 'total_expense',
      'net_profit', r2 ->> 'net_profit',
      'status', r2 ->> 'status'
    ),
    'changes', jsonb_build_object(
      'income_change', v_income_change,
      'income_change_pct', v_income_change_pct,
      'net_profit_change', v_net_profit_change,
      'net_profit_change_pct', v_net_profit_change_pct
    )
  );
END;
$$;
-- =======================================
-- ============================================================
-- Sheress - QRIS Storage Bucket Migration (v2)
-- Description: Creates storage bucket for QRIS images and
--              updates seed data to use Supabase Storage URLs.
-- Notes:
--   After running this migration, upload QRIS images to
--   the 'qris-images' bucket via:
--     supabase storage upload qris-images business_1_qris.svg
-- ============================================================

-- 1. CREATE QRIS STORAGE BUCKET
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'qris-images',
  'qris-images',
  true,                           -- public bucket (for serving images)
  5242880,                        -- 5 MB limit
  ARRAY['image/png', 'image/jpeg', 'image/svg+xml']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- 2. RLS: Allow authenticated users to SELECT (read) QRIS images
-- ============================================================
CREATE POLICY "Anyone can view QRIS images"
ON storage.objects
FOR SELECT
USING (bucket_id = 'qris-images');

-- 3. RLS: Only authenticated users can UPLOAD QRIS images
-- ============================================================
CREATE POLICY "Authenticated users can upload QRIS images"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'qris-images'
  AND auth.role() = 'authenticated'
);

-- 4. RLS: Only owners can UPDATE/DELETE QRIS images
-- ============================================================
CREATE POLICY "Owners can update QRIS images"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'qris-images'
  AND auth.role() = 'authenticated'
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
);

CREATE POLICY "Owners can delete QRIS images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'qris-images'
  AND auth.role() = 'authenticated'
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
);

-- 5. UPDATE SEED DATA with Supabase Storage public URLs
-- ============================================================
-- After uploading images to the bucket, the public URL format is:
--   {SUPABASE_URL}/storage/v1/object/public/qris-images/{filename}
-- Update the placeholder URL with the actual Supabase project URL.
UPDATE public.businesses
SET qris_image_url = 'https://YOUR-PROJECT.supabase.co/storage/v1/object/public/qris-images/business_1_qris.svg'
WHERE name = 'Agen Minuman Alkali';

UPDATE public.businesses
SET qris_image_url = 'https://YOUR-PROJECT.supabase.co/storage/v1/object/public/qris-images/business_2_qris.svg'
WHERE name = 'Teh Solo';

UPDATE public.businesses
SET qris_image_url = 'https://YOUR-PROJECT.supabase.co/storage/v1/object/public/qris-images/business_3_qris.svg'
WHERE name = 'Warung Kopi';
-- =======================================
-- ============================================================
-- Sheress - Demo Accounts Migration
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
    jsonb_build_object('username', 'owner_sheress', 'display_name', 'Owner Sheress', 'role', 'owner'),
    now(),
    now()
  ),
  (
    'd0000000-0000-0000-0000-000000000002',
    'manager@ssrs.com',
    crypt('password123', gen_salt('bf'::text)),
    now(),
    jsonb_build_object('username', 'manager_sheress', 'display_name', 'Manager Sheress', 'role', 'manager'),
    now(),
    now()
  ),
  (
    'd0000000-0000-0000-0000-000000000003',
    'staff@ssrs.com',
    crypt('password123', gen_salt('bf'::text)),
    now(),
    jsonb_build_object('username', 'staff_sheress', 'display_name', 'Staff Sheress', 'role', 'staff'),
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
-- =======================================
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
-- =======================================
-- ============================================================
-- 005_update_rls_policies.sql
-- Fix RLS policies:
--   1. Owner explicit SELECT for transactions (was relying on user_has_business_access)
--   2. Staff can see ALL transactions in their business (not just own)
--   3. Staff/Manager can UPDATE any transaction in their business
--   4. Staff/Manager can DELETE transactions in their business
-- ============================================================

-- Drop old policies to replace them
DROP POLICY IF EXISTS transactions_select ON public.transactions;
DROP POLICY IF EXISTS transactions_insert ON public.transactions;
DROP POLICY IF EXISTS transactions_update ON public.transactions;
DROP POLICY IF EXISTS transactions_delete ON public.transactions;

-- Owner: can read all transactions across all businesses
CREATE POLICY transactions_select_owner ON public.transactions
  FOR SELECT
  USING (
    public.get_current_user_role() = 'owner'
  );

-- Manager: can read all transactions for accessible businesses
CREATE POLICY transactions_select_manager ON public.transactions
  FOR SELECT
  USING (
    public.get_current_user_role() = 'manager'
    AND public.user_has_business_access(business_id)
  );

-- Staff: can read all transactions for accessible businesses (not just own)
CREATE POLICY transactions_select_staff ON public.transactions
  FOR SELECT
  USING (
    public.get_current_user_role() = 'staff'
    AND public.user_has_business_access(business_id)
  );

-- Manager & Staff can insert transactions for their businesses; Owner can insert anywhere
CREATE POLICY transactions_insert ON public.transactions
  FOR INSERT
  WITH CHECK (
    public.user_has_business_access(business_id)
    AND user_id = auth.uid()
  );

-- All roles with business access can update any transaction in that business
CREATE POLICY transactions_update ON public.transactions
  FOR UPDATE
  USING (
    public.user_has_business_access(business_id)
  )
  WITH CHECK (
    public.user_has_business_access(business_id)
  );

-- All roles with business access can delete transactions in that business
CREATE POLICY transactions_delete ON public.transactions
  FOR DELETE
  USING (
    public.user_has_business_access(business_id)
  );
-- =======================================
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
-- =======================================
-- ============================================================
-- 007_drop_unused_policies.sql
-- Drop old RLS policies on tables where RLS was disabled
-- to resolve Supabase Dashboard warnings
-- ============================================================

-- Drop policies on public.users
DROP POLICY IF EXISTS users_select_owner ON public.users;
DROP POLICY IF EXISTS users_insert_owner ON public.users;
DROP POLICY IF EXISTS users_update_owner ON public.users;
DROP POLICY IF EXISTS users_delete_owner ON public.users;

-- Drop policies on public.businesses
DROP POLICY IF EXISTS businesses_select ON public.businesses;
DROP POLICY IF EXISTS businesses_insert ON public.businesses;
DROP POLICY IF EXISTS businesses_update ON public.businesses;
DROP POLICY IF EXISTS businesses_delete ON public.businesses;

-- Drop policies on public.user_businesses
DROP POLICY IF EXISTS user_businesses_select ON public.user_businesses;
DROP POLICY IF EXISTS user_businesses_insert ON public.user_businesses;
DROP POLICY IF EXISTS user_businesses_insert_manager ON public.user_businesses;
DROP POLICY IF EXISTS user_businesses_update ON public.user_businesses;
DROP POLICY IF EXISTS user_businesses_delete ON public.user_businesses;

-- Drop policies on public.categories
DROP POLICY IF EXISTS categories_select ON public.categories;
DROP POLICY IF EXISTS categories_insert ON public.categories;
DROP POLICY IF EXISTS categories_update ON public.categories;
DROP POLICY IF EXISTS categories_delete ON public.categories;

-- Drop policies on public.transactions
DROP POLICY IF EXISTS transactions_select_owner ON public.transactions;
DROP POLICY IF EXISTS transactions_select_manager ON public.transactions;
DROP POLICY IF EXISTS transactions_select_staff ON public.transactions;
DROP POLICY IF EXISTS transactions_insert ON public.transactions;
DROP POLICY IF EXISTS transactions_update ON public.transactions;
DROP POLICY IF EXISTS transactions_delete ON public.transactions;

-- Drop policies on public.financial_reports
DROP POLICY IF EXISTS financial_reports_select ON public.financial_reports;
DROP POLICY IF EXISTS financial_reports_insert ON public.financial_reports;
DROP POLICY IF EXISTS financial_reports_update ON public.financial_reports;
DROP POLICY IF EXISTS financial_reports_delete ON public.financial_reports;
-- =======================================
-- ============================================================
-- 008_allow_anon_rls.sql
-- Enable RLS on all tables and create open policies
-- to satisfy Supabase security check while keeping public CRUD intact
-- ============================================================

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_reports ENABLE ROW LEVEL SECURITY;

-- Allow all operations for public (anon & authenticated) on users
DROP POLICY IF EXISTS anon_all ON public.users;
CREATE POLICY anon_all ON public.users FOR ALL TO public USING (true) WITH CHECK (true);

-- Allow all operations for public on businesses
DROP POLICY IF EXISTS anon_all ON public.businesses;
CREATE POLICY anon_all ON public.businesses FOR ALL TO public USING (true) WITH CHECK (true);

-- Allow all operations for public on user_businesses
DROP POLICY IF EXISTS anon_all ON public.user_businesses;
CREATE POLICY anon_all ON public.user_businesses FOR ALL TO public USING (true) WITH CHECK (true);

-- Allow all operations for public on categories
DROP POLICY IF EXISTS anon_all ON public.categories;
CREATE POLICY anon_all ON public.categories FOR ALL TO public USING (true) WITH CHECK (true);

-- Allow all operations for public on transactions
DROP POLICY IF EXISTS anon_all ON public.transactions;
CREATE POLICY anon_all ON public.transactions FOR ALL TO public USING (true) WITH CHECK (true);

-- Allow all operations for public on financial_reports
DROP POLICY IF EXISTS anon_all ON public.financial_reports;
CREATE POLICY anon_all ON public.financial_reports FOR ALL TO public USING (true) WITH CHECK (true);
-- =======================================
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
-- =======================================
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
-- =======================================
-- ============================================================
-- Sheress - Add more allowed MIME types for QRIS bucket
-- ============================================================

UPDATE storage.buckets
SET allowed_mime_types = ARRAY[
  'image/png',
  'image/jpeg',
  'image/svg+xml',
  'image/webp',
  'image/heic',
  'image/heif'
]::text[]
WHERE id = 'qris-images';
-- =======================================
-- ============================================================
-- Sheress - Fix QRIS storage bucket RLS policies
-- Use auth.uid() IS NOT NULL instead of auth.role() = 'authenticated'
-- because auth.role() may not return 'authenticated' in some setups.
-- ============================================================

-- 1. Drop existing INSERT policy and recreate
DROP POLICY IF EXISTS "Authenticated users can upload QRIS images" ON storage.objects;
CREATE POLICY "Authenticated users can upload QRIS images"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'qris-images'
  AND auth.uid() IS NOT NULL
);

-- 2. Drop existing UPDATE policy and recreate
DROP POLICY IF EXISTS "Owners can update QRIS images" ON storage.objects;
CREATE POLICY "Owners can update QRIS images"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'qris-images'
  AND auth.uid() IS NOT NULL
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
)
WITH CHECK (
  bucket_id = 'qris-images'
  AND auth.uid() IS NOT NULL
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
);

-- 3. Drop existing DELETE policy and recreate
DROP POLICY IF EXISTS "Owners can delete QRIS images" ON storage.objects;
CREATE POLICY "Owners can delete QRIS images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'qris-images'
  AND auth.uid() IS NOT NULL
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
);


-- =======================================
-- ============================================================
-- Sheress - Simplify QRIS storage policies for Supabase setup
-- that doesn't propagate JWT claims to storage DB session.
-- Security is enforced client-side (owner role check in app).
-- ============================================================

-- Drop debug policy if still exists
DROP POLICY IF EXISTS "Debug public insert QRIS" ON storage.objects;

-- INSERT: no auth check needed (app already enforces owner role)
DROP POLICY IF EXISTS "Authenticated users can upload QRIS images" ON storage.objects;
CREATE POLICY "Users can upload QRIS images"
ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = 'qris-images');

-- UPDATE: same, for upsert to work
DROP POLICY IF EXISTS "Owners can update QRIS images" ON storage.objects;
CREATE POLICY "Users can update QRIS images"
ON storage.objects
FOR UPDATE
USING (bucket_id = 'qris-images')
WITH CHECK (bucket_id = 'qris-images');

-- DELETE: keep owner check (not used from Flutter currently)
DROP POLICY IF EXISTS "Owners can delete QRIS images" ON storage.objects;
CREATE POLICY "Owners can delete QRIS images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'qris-images'
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
);
-- =======================================
-- Drop financial_reports table and related functions.
-- The table and functions were defined in 001_initial_schema.sql but never
-- used from the app (no Dart-side RPC calls, stub model/screen removed).

DROP FUNCTION IF EXISTS public.compare_financial_periods(
  int, varchar(7), varchar(7)
);

DROP FUNCTION IF EXISTS public.generate_financial_report_range(
  int, date, date
);

DROP FUNCTION IF EXISTS public.generate_financial_report(
  int, varchar(7)
);

DROP TABLE IF EXISTS public.financial_reports;
-- =======================================
-- ============================================================
-- 015: Piutang (Debts) & Konsinyasi (Consignment) tables
-- ============================================================

-- ==================== PIUTANG ====================

CREATE TABLE public.debtors (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        varchar(255) NOT NULL,
  phone       varchar(50),
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_debtors_business ON public.debtors(business_id);

CREATE TABLE public.debts (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  debtor_id    int NOT NULL REFERENCES public.debtors(id) ON DELETE CASCADE,
  business_id  int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount       decimal(15,2) NOT NULL CHECK (amount > 0),
  paid_amount  decimal(15,2) NOT NULL DEFAULT 0.00 CHECK (paid_amount >= 0),
  description  text,
  status       varchar(20) NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'partial', 'paid')),
  debt_date    date NOT NULL DEFAULT CURRENT_DATE,
  due_date     date,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_debts_business ON public.debts(business_id);
CREATE INDEX idx_debts_debtor ON public.debts(debtor_id);
CREATE INDEX idx_debts_status ON public.debts(status);

CREATE TABLE public.debt_payments (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  debt_id       bigint NOT NULL REFERENCES public.debts(id) ON DELETE CASCADE,
  amount        decimal(15,2) NOT NULL CHECK (amount > 0),
  payment_date  date NOT NULL DEFAULT CURRENT_DATE,
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  notes         text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_debt_payments_debt ON public.debt_payments(debt_id);

-- Trigger: auto-update updated_at for debtors
CREATE TRIGGER set_debtors_updated_at
  BEFORE UPDATE ON public.debtors
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Trigger: auto-update updated_at for debts
CREATE TRIGGER set_debts_updated_at
  BEFORE UPDATE ON public.debts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ==================== KONSINYASI ====================

CREATE TABLE public.consignors (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        varchar(255) NOT NULL,
  phone       varchar(50),
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_consignors_business ON public.consignors(business_id);

CREATE TABLE public.consignments (
  id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignor_id      int NOT NULL REFERENCES public.consignors(id) ON DELETE CASCADE,
  business_id       int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id           uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  total_amount      decimal(15,2) NOT NULL CHECK (total_amount > 0),
  settled_amount    decimal(15,2) NOT NULL DEFAULT 0.00 CHECK (settled_amount >= 0),
  description       text,
  status            varchar(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'settled', 'cancelled')),
  consignment_date  date NOT NULL DEFAULT CURRENT_DATE,
  due_date          date,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_consignments_business ON public.consignments(business_id);
CREATE INDEX idx_consignments_consignor ON public.consignments(consignor_id);
CREATE INDEX idx_consignments_status ON public.consignments(status);

CREATE TABLE public.consignment_items (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignment_id  bigint NOT NULL REFERENCES public.consignments(id) ON DELETE CASCADE,
  product_name    varchar(255) NOT NULL,
  quantity        int NOT NULL CHECK (quantity > 0),
  agreed_price    decimal(15,2) NOT NULL CHECK (agreed_price > 0),
  selling_price   decimal(15,2),
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_consignment_items_consignment ON public.consignment_items(consignment_id);

CREATE TABLE public.consignment_settlements (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignment_id   bigint NOT NULL REFERENCES public.consignments(id) ON DELETE CASCADE,
  amount           decimal(15,2) NOT NULL CHECK (amount > 0),
  settlement_date  date NOT NULL DEFAULT CURRENT_DATE,
  user_id          uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_consignment_settlements_consignment ON public.consignment_settlements(consignment_id);

-- Trigger: auto-update updated_at for consignors
CREATE TRIGGER set_consignors_updated_at
  BEFORE UPDATE ON public.consignors
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Trigger: auto-update updated_at for consignments
CREATE TRIGGER set_consignments_updated_at
  BEFORE UPDATE ON public.consignments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ==================== RLS (consistent with existing open policies) ====================

ALTER TABLE public.debtors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debt_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignment_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignment_settlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY anon_all ON public.debtors FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.debts FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.debt_payments FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignors FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignments FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignment_items FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignment_settlements FOR ALL TO public USING (true) WITH CHECK (true);

-- ==================== GRANT permissions for Data API access ====================

GRANT ALL ON TABLE public.debtors TO anon;
GRANT ALL ON TABLE public.debtors TO authenticated;
GRANT ALL ON TABLE public.debtors TO service_role;
GRANT ALL ON SEQUENCE public.debtors_id_seq TO anon;
GRANT ALL ON SEQUENCE public.debtors_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.debtors_id_seq TO service_role;

GRANT ALL ON TABLE public.debts TO anon;
GRANT ALL ON TABLE public.debts TO authenticated;
GRANT ALL ON TABLE public.debts TO service_role;
GRANT ALL ON SEQUENCE public.debts_id_seq TO anon;
GRANT ALL ON SEQUENCE public.debts_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.debts_id_seq TO service_role;

GRANT ALL ON TABLE public.debt_payments TO anon;
GRANT ALL ON TABLE public.debt_payments TO authenticated;
GRANT ALL ON TABLE public.debt_payments TO service_role;
GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO anon;
GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO service_role;

GRANT ALL ON TABLE public.consignors TO anon;
GRANT ALL ON TABLE public.consignors TO authenticated;
GRANT ALL ON TABLE public.consignors TO service_role;
GRANT ALL ON SEQUENCE public.consignors_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignors_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignors_id_seq TO service_role;

GRANT ALL ON TABLE public.consignments TO anon;
GRANT ALL ON TABLE public.consignments TO authenticated;
GRANT ALL ON TABLE public.consignments TO service_role;
GRANT ALL ON SEQUENCE public.consignments_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignments_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignments_id_seq TO service_role;

GRANT ALL ON TABLE public.consignment_items TO anon;
GRANT ALL ON TABLE public.consignment_items TO authenticated;
GRANT ALL ON TABLE public.consignment_items TO service_role;
GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO service_role;

GRANT ALL ON TABLE public.consignment_settlements TO anon;
GRANT ALL ON TABLE public.consignment_settlements TO authenticated;
GRANT ALL ON TABLE public.consignment_settlements TO service_role;
GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO service_role;
-- =======================================
-- ============================================================
-- 016: Add GRANT permissions for debt/consignment tables
-- Tables were created in 015 but missing GRANT for Data API access
-- ============================================================

GRANT ALL ON TABLE public.debtors TO anon;
GRANT ALL ON TABLE public.debtors TO authenticated;
GRANT ALL ON TABLE public.debtors TO service_role;
GRANT ALL ON SEQUENCE public.debtors_id_seq TO anon;
GRANT ALL ON SEQUENCE public.debtors_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.debtors_id_seq TO service_role;

GRANT ALL ON TABLE public.debts TO anon;
GRANT ALL ON TABLE public.debts TO authenticated;
GRANT ALL ON TABLE public.debts TO service_role;
GRANT ALL ON SEQUENCE public.debts_id_seq TO anon;
GRANT ALL ON SEQUENCE public.debts_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.debts_id_seq TO service_role;

GRANT ALL ON TABLE public.debt_payments TO anon;
GRANT ALL ON TABLE public.debt_payments TO authenticated;
GRANT ALL ON TABLE public.debt_payments TO service_role;
GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO anon;
GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO service_role;

GRANT ALL ON TABLE public.consignors TO anon;
GRANT ALL ON TABLE public.consignors TO authenticated;
GRANT ALL ON TABLE public.consignors TO service_role;
GRANT ALL ON SEQUENCE public.consignors_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignors_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignors_id_seq TO service_role;

GRANT ALL ON TABLE public.consignments TO anon;
GRANT ALL ON TABLE public.consignments TO authenticated;
GRANT ALL ON TABLE public.consignments TO service_role;
GRANT ALL ON SEQUENCE public.consignments_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignments_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignments_id_seq TO service_role;

GRANT ALL ON TABLE public.consignment_items TO anon;
GRANT ALL ON TABLE public.consignment_items TO authenticated;
GRANT ALL ON TABLE public.consignment_items TO service_role;
GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO service_role;

GRANT ALL ON TABLE public.consignment_settlements TO anon;
GRANT ALL ON TABLE public.consignment_settlements TO authenticated;
GRANT ALL ON TABLE public.consignment_settlements TO service_role;
GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO service_role;
-- =======================================
-- ============================================================
-- 017: Consignment Two Models â€” Hutang & Harian (Idempotent)
-- ============================================================

-- 1a. Tambah kolom di consignments (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignments' AND column_name = 'type'
  ) THEN
    ALTER TABLE public.consignments
      ADD COLUMN type varchar(10) DEFAULT 'debt'
      CHECK (type IN ('debt', 'daily'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignments' AND column_name = 'report_status'
  ) THEN
    ALTER TABLE public.consignments
      ADD COLUMN report_status varchar(20) DEFAULT 'pending'
      CHECK (report_status IN ('pending', 'reported', 'settled'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignments' AND column_name = 'income_transaction_id'
  ) THEN
    ALTER TABLE public.consignments
      ADD COLUMN income_transaction_id bigint REFERENCES public.transactions(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignments' AND column_name = 'expense_transaction_id'
  ) THEN
    ALTER TABLE public.consignments
      ADD COLUMN expense_transaction_id bigint REFERENCES public.transactions(id) ON DELETE SET NULL;
  END IF;
END $$;

-- 1b. Tambah kolom di consignment_items (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignment_items' AND column_name = 'quantity_sold'
  ) THEN
    ALTER TABLE public.consignment_items
      ADD COLUMN quantity_sold int DEFAULT 0 CHECK (quantity_sold >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignment_items' AND column_name = 'quantity_returned'
  ) THEN
    ALTER TABLE public.consignment_items
      ADD COLUMN quantity_returned int DEFAULT 0 CHECK (quantity_returned >= 0);
  END IF;
END $$;

-- 1b-2. Drop old CHECK constraint if it exists (prevents 0+0 != quantity on insert)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.consignment_items'::regclass
      AND conname = 'check_qty_balance'
      AND contype = 'c'
  ) THEN
    ALTER TABLE public.consignment_items DROP CONSTRAINT check_qty_balance;
  END IF;
END $$;

-- 1b-3. Add description column to consignment_items
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignment_items' AND column_name = 'description'
  ) THEN
    ALTER TABLE public.consignment_items ADD COLUMN description text;
  END IF;
END $$;

-- 1c. Trigger function: validasi qty balance (hanya saat lapor, bukan saat insert awal)
CREATE OR REPLACE FUNCTION public.check_qty_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.quantity_sold > 0 OR NEW.quantity_returned > 0 THEN
    IF NEW.quantity_sold + NEW.quantity_returned != NEW.quantity THEN
      RAISE EXCEPTION 'quantity_sold + quantity_returned harus sama dengan quantity';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1d. Trigger (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_check_qty_balance'
  ) THEN
    CREATE TRIGGER trg_check_qty_balance
      BEFORE INSERT OR UPDATE ON public.consignment_items
      FOR EACH ROW EXECUTE FUNCTION public.check_qty_balance();
  END IF;
END $$;

-- 1e. Seed kategori baru (idempotent via ON CONFLICT)
DO $$
DECLARE b RECORD;
BEGIN
  FOR b IN SELECT id FROM public.businesses LOOP
    INSERT INTO public.categories (business_id, name, type) VALUES
      (b.id, 'Komisi Titipan', 'income'),
      (b.id, 'Bayar Titipan', 'expense')
    ON CONFLICT DO NOTHING;
  END LOOP;
END $$;
-- =======================================
-- Enable Realtime for consignment-related tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.consignments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.consignment_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.consignors;
-- =======================================
-- ============================================================
-- 019_fix_categories_unique.sql
-- Remove duplicate categories and add unique constraint
-- ============================================================

-- Remove duplicate rows, keep the one with the smallest id
DELETE FROM public.categories a
USING public.categories b
WHERE a.id > b.id
  AND a.business_id = b.business_id
  AND a.name = b.name
  AND a.type = b.type;

-- Add unique constraint to prevent future duplicates
ALTER TABLE public.categories
  ADD CONSTRAINT categories_business_name_type_unique
  UNIQUE (business_id, name, type);
-- =======================================
-- Migrate 'debt' type consignments to 'reseller'
UPDATE consignments SET type = 'reseller' WHERE type = 'debt';
-- =======================================
-- Integrate debt system with transactions:
-- 1. Add expense_transaction_id to debts (for the expense created when debt is recorded)
-- 2. Add income_transaction_id to debt_payments (for the income created when payment is made)
-- 3. Transactions now reference debt_payments (to distinguish debt-related transactions)

ALTER TABLE debts
  ADD COLUMN expense_transaction_id bigint REFERENCES transactions(id) ON DELETE SET NULL;

ALTER TABLE debt_payments
  ADD COLUMN income_transaction_id bigint REFERENCES transactions(id) ON DELETE SET NULL;

-- Grant permissions
GRANT ALL ON debts TO authenticated;
GRANT ALL ON debt_payments TO authenticated;
-- =======================================
