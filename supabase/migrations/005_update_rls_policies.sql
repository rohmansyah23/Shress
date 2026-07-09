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
