-- ============================================================
-- SSRS Finance - Initial Schema Migration (v2)
-- Database: Supabase (PostgreSQL)
-- Description: Multi-tenant financial reporting system
-- Owner: SSRS
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
  );
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
-- Owner/Manager: can read transactions for accessible businesses
CREATE POLICY transactions_select ON public.transactions
  FOR SELECT
  USING (
    (public.get_current_user_role() IN ('owner', 'manager') 
     AND public.user_has_business_access(business_id))
    OR
    (public.get_current_user_role() = 'staff'
     AND public.user_has_business_access(business_id)
     AND user_id = auth.uid())
  );

-- Manager & Staff can insert transactions for their businesses; Owner can insert anywhere
CREATE POLICY transactions_insert ON public.transactions
  FOR INSERT
  WITH CHECK (
    public.user_has_business_access(business_id)
    AND user_id = auth.uid()
  );

-- Can only update own transactions
CREATE POLICY transactions_update ON public.transactions
  FOR UPDATE
  USING (
    public.user_has_business_access(business_id)
    AND user_id = auth.uid()
  )
  WITH CHECK (
    public.user_has_business_access(business_id)
    AND user_id = auth.uid()
  );

-- Only owner can delete transactions
CREATE POLICY transactions_delete ON public.transactions
  FOR DELETE
  USING (
    public.get_current_user_role() = 'owner'
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
  ('Agen Minuman Alkali', 'SSRS - Agen Minuman Alkali', 'assets/images/qris/business_1_qris.svg'),
  ('Teh Solo', 'SSRS - Teh Solo', 'assets/images/qris/business_2_qris.svg'),
  ('Warung Kopi', 'SSRS - Warung Kopi', 'assets/images/qris/business_3_qris.svg')
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
