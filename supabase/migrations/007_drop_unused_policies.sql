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
